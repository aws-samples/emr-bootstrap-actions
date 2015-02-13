#!/usr/bin/python
# Script to install Spark on Emr 
# Assumes use of SparkS3InstallPath enviroment variable
# Assumes use of Ec2Region enviroment variable
import os 
import subprocess
import glob
import sys
import shutil

# Gather environment info
# expects to find SparkS3InstallPath defining path to tgz for install
# expects the basename without extension of path to match the directory name give, for example s3://support.elasticmapreduce/spark/v1.2.0/spark-1.2.0.a.tgz with basename of 
#  spark-1.2.0.a.tgz will expand into direcotry structure of spark-1.2.0.a/
SparkS3InstallPath = os.environ['SparkS3InstallPath']
ScalaS3Location = os.environ['ScalaS3Location']
Ec2Region = os.environ['Ec2Region']
SparkDriverLogLevel = os.environ['SparkDriverLogLevel']

#determine spark basename
base, ext = os.path.splitext(SparkS3InstallPath)
SparkFilename=os.path.basename(SparkS3InstallPath)
SparkBase = os.path.basename(base)

#set scala path is empty
#if ScalaS3Location == "":
#	if Ec2Region == "eu-central-1":
#		ScalaS3Location = "s3://eu-central-1.support.elasticmapreduce/spark/scala/scala-2.10.3.tgz"
#	else:
#		ScalaS3Location = "s3://support.elasticmapreduce/spark/scala/scala-2.10.3.tgz"

#determine Scala basename
base, ext = os.path.splitext(ScalaS3Location)
ScalaFilename = os.path.basename(ScalaS3Location)
ScalaBase = os.path.basename(base)


# various paths
hadoop_home = "/home/hadoop"
hadoop_apps = "/home/hadoop/.versions"
local_dir = "/mnt/spark"
tmp_dir = "/mnt/staging-spark-install-files"
spark_home = "/home/hadoop/spark"
spark_classpath = os.path.join(spark_home,"classpath")
spark_log_dir = "/mnt/var/log/apps"
scala_home = os.path.join(hadoop_apps,ScalaBase)
lock_file = '/tmp/spark-installed'

# Spark logs location used by Spark History server
spark_evlogs = "hdfs:///spark-logs"

subprocess.check_call(["/bin/mkdir","-p",tmp_dir])

def download_and_uncompress_files():
	if ScalaS3Location != "":
		subprocess.check_call(["hadoop","fs","-get",ScalaS3Location, tmp_dir])

	subprocess.check_call(["hadoop","fs","-get",SparkS3InstallPath, tmp_dir])

	subprocess.check_call(["/bin/tar", "zxvf" , os.path.join(tmp_dir,SparkFilename), "-C", hadoop_apps])

	if ScalaS3Location != "":
		subprocess.check_call(["/bin/tar", "zxvf" , os.path.join(tmp_dir,ScalaFilename), "-C", hadoop_apps])

	subprocess.check_call(["/bin/ln","-s",hadoop_apps+"/"+SparkBase, spark_home])

def prepare_classpath():
	# This function is needed to copy the jars to a dedicated Spark folder,
	# in which all the scala related jars are removed
	emr = os.path.join(spark_classpath,"emr")
	emr_fs = os.path.join(spark_classpath,"emrfs")
	subprocess.check_call(["/bin/mkdir","-p",spark_classpath])
	emrfssharepath = "/usr/share/aws/emr/emrfs"
	if not os.path.isdir(emrfssharepath) :
		emrfssharepath = "/usr/share/aws/emr/emr-fs"
	subprocess.check_call(["/bin/cp","-R","{0}/lib/".format(emrfssharepath),emr_fs])
	subprocess.check_call(["/bin/cp","-R","/usr/share/aws/emr/lib/",emr])

	cmd = "/bin/ls /home/hadoop/share/hadoop/common/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/share/hadoop/yarn/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/share/hadoop/hdfs/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/share/hadoop/mapreduce/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/hive-*/lib/mysql*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/hive-*/lib/bonecp*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	#cmd = "/bin/ls /home/hadoop/.versions/hive-*/lib/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	#subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/hbase-*/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/spark-*/lib/amazon-kinesis-client-*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)

	if ScalaS3Location != "":
		# remove scala from classpath
		scala_jars = glob.glob(emr+"/scala*")
		scala_jars += glob.glob(emr_fs+"/scala*")
		for jar in scala_jars:
			os.remove(jar)
	else:
		#cleanup conflicting scala-reflect for yarn-client
		scala_reflect = glob.glob(emr+"/scala-reflect-2.11.0*")
		scala_reflect += glob.glob(emr_fs+"/scala-reflect-2.11.0*")
		for jar in scala_reflect:
			os.remove(jar)

	#create symlink to hive-site.xml, if does not exist copy hive-default.xml to hive-site.xml before making link
	hivesitexml = "/home/hadoop/hive/conf/hive-site.xml"
	if not os.path.isfile(hivesitexml) :
		subprocess.check_call(["/bin/cp","/home/hadoop/hive/conf/hive-default.xml",hivesitexml])
	subprocess.check_call(["/bin/ln","-s",hivesitexml,"/home/hadoop/spark/conf/hive-site.xml"])

	#create a symlink to the default log4j.properties of hadoop if not already provided
	sparklog4j = "/home/hadoop/spark/conf/log4j.properties"
	hadooplog4j = "/home/hadoop/conf/log4j.properties"
	if not os.path.isfile(sparklog4j):
		subprocess.check_call(["/bin/ln","-s",hadooplog4j,sparklog4j])


def config():
	# spark-default.conf
	spark_defaults_tmp_location = os.path.join(tmp_dir,"spark-defaults.conf")
	spark_default_final_location = os.path.join(spark_home,"conf")
	with open(spark_defaults_tmp_location,'a') as spark_defaults:
		spark_defaults.write("spark.eventLog.enabled  true\n")
		spark_defaults.write("spark.eventLog.dir      {0}\n".format(spark_evlogs))
		spark_defaults.write("spark.executor.extraJavaOptions         -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70\n")
		spark_defaults.write("spark.driver.extraJavaOptions         -Dspark.driver.log.level={0}\n".format(SparkDriverLogLevel))
	subprocess.check_call(["/bin/mv",spark_defaults_tmp_location,spark_default_final_location])

	# bashrc file
	if ScalaS3Location != "":
		with open("/home/hadoop/.bashrc","a") as bashrc:
			bashrc.write("export SCALA_HOME={0}".format(scala_home))

	# spark-env.sh
	spark_env_tmp_location = os.path.join(tmp_dir,"spark-env.sh")
	spark_env_final_location = os.path.join(spark_home,"conf")

	files= glob.glob("/home/hadoop/share/*/*/*/hadoop-*lzo.jar")
	if len(files) < 1:
		files=glob.glob("/home/hadoop/share/*/*/*/hadoop-*lzo-*.jar")
	if len(files) < 1:
		print "lzo not found inside /home/hadoop/share/"
	else:
		lzo_jar=files[0]

	#subprocess.check_call(["/bin/mkdir","-p",spark_log_dir])
	subprocess.call(["/bin/mkdir","-p",spark_log_dir])

	with open(spark_env_tmp_location,'a') as spark_env:
		spark_env.write("export SPARK_DAEMON_JAVA_OPTS=\"-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70\"\n")
		spark_env.write("export SPARK_LOCAL_DIRS={0}\n".format(local_dir))
		spark_env.write("export SPARK_LOG_DIR={0}\n".format(spark_log_dir))
		spark_env.write("export SPARK_CLASSPATH=\"{4}/conf:/home/hadoop/conf:{0}/emr/*:{1}/emrfs/*:{2}/share/hadoop/common/lib/*:{3}\"\n".format(spark_classpath,spark_classpath,hadoop_home,lzo_jar,spark_home))

	subprocess.check_call(["mv",spark_env_tmp_location,spark_env_final_location])

	# hadoop default log4j.properties
	hadooplog4j = "/home/hadoop/conf/log4j.properties"
	with open(hadooplog4j, "a") as hadooplog4jfilehandle:
		hadooplog4jfilehandle.write("log4j.logger.org.apache.spark=${spark.driver.log.level}")


if __name__ == '__main__':
	try:
		open(lock_file,'r')
		print "BA already executed"
	except Exception:
		download_and_uncompress_files()
		prepare_classpath()
		config()
		# create lock file
		open(lock_file,'a').close()
		shutil.rmtree(tmp_dir)

