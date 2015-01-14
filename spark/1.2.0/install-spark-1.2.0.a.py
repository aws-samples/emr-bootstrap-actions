#!/usr/bin/python
# Small script to install Spark on Emr 3.x Ami
import os 
import subprocess
import glob
import sys
import shutil

# components versions
scala_version = "2.10.3"
spark_version = "1.2.0"
hadoop_version = "2.4.0"

# base path
s3_base = "s3://support.elasticmapreduce/spark/"

# build some variables
spark_archive = "spark-{0}.a.tgz".format(spark_version)
scala_archive = "scala-{0}.tgz".format(scala_version)
scala_url = "{0}/scala/{1}".format(s3_base,scala_archive)
spark_url = "{0}/{1}/{2}".format(s3_base,spark_version,spark_archive)

# various paths
hadoop_home = "/home/hadoop"
hadoop_apps = "/home/hadoop/.versions"
local_dir = "/mnt/spark"
tmp_dir = "/tmp"
spark_home = "/home/hadoop/spark"
spark_classpath = os.path.join(spark_home,"classpath")
spark_log_dir = "/mnt/var/log/apps"
scala_home = os.path.join(hadoop_apps,"scala-{0}".format(scala_version))
lock_file = '/tmp/spark-installed'

# Spark logs location used by Spark History server
spark_evlogs = "hdfs:///spark-logs"

def download_and_uncompress_files():
	subprocess.check_call(["/home/hadoop/bin/hdfs","dfs","-get",scala_url, tmp_dir])
	subprocess.check_call(["/home/hadoop/bin/hdfs","dfs","-get",spark_url, tmp_dir])
	subprocess.check_call(["/bin/tar", "zxvf" , os.path.join(tmp_dir,spark_archive), "-C", hadoop_apps])
	subprocess.check_call(["/bin/tar", "zxvf" , os.path.join(tmp_dir,scala_archive), "-C", hadoop_apps])
	subprocess.check_call(["/bin/ln","-s",hadoop_apps+"/spark-" + spark_version +".a", spark_home])
	# cleanup 
	os.remove(os.path.join(tmp_dir,scala_archive))
	os.remove(os.path.join(tmp_dir,spark_archive))

def prepare_classpath(userProvidedJars):
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

	cmd = "/bin/ls /home/hadoop/.versions/2.4.0/share/hadoop/common/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/2.4.0/share/hadoop/yarn/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/2.4.0/share/hadoop/hdfs/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/2.4.0/share/hadoop/mapreduce/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/hive-*/lib/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/hbase-*/*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	cmd = "/bin/ls /home/hadoop/.versions/spark-*/lib/amazon-kinesis-client-*.jar | xargs -n 1 -I %% cp %% {0}".format(emr)
	subprocess.check_call(cmd,shell=True)
	if len(userProvidedJars) > 0:
		userProvidedJarsPath = os.path.join(spark_classpath,"user-provided")
		subprocess.check_call(["/bin/mkdir","-p",userProvidedJarsPath])
		jarsTmp = os.path.join(tmp_dir,"userProvidedJars")
		subprocess.check_call(["/bin/mkdir","-p",jarsTmp])
		subprocess.check_call(["/home/hadoop/bin/hdfs","dfs","-copyToLocal",userProvidedJars, jarsTmp])
		subprocess.check_call("/bin/ls {0}/*/*.jar | xargs -n 1 -I %% cp %% {1}".format(jarsTmp,userProvidedJarsPath),shell=True)
		shutil.rmtree(jarsTmp, ignore_errors=True)

	# remove scala from classpath
	scala_jars = glob.glob(emr+"/scala*")
	scala_jars += glob.glob(emr_fs+"/scala*")
	for jar in scala_jars:
		os.remove(jar)

	#create symlink to hive-site.xml, if does not exist copy hive-default.xml to hive-site.xml before making link
	hivesitexml = "/home/hadoop/hive/conf/hive-site.xml"
	if not os.path.isfile(hivesitexml) :
		subprocess.check_call(["/bin/cp","/home/hadoop/hive/conf/hive-default.xml",hivesitexml])
	subprocess.check_call(["/bin/ln","-s",hivesitexml,"/home/hadoop/spark/conf/hive-site.xml"])


def config():
	# spark-default.conf
	spark_defaults_tmp_location = os.path.join(tmp_dir,"spark-defaults.conf")
	spark_default_final_location = os.path.join(spark_home,"conf")
	with open(spark_defaults_tmp_location,'a') as spark_defaults:
		spark_defaults.write("spark.eventLog.enabled	true\n")
		spark_defaults.write("spark.eventLog.dir			{0}\n".format(spark_evlogs))
		spark_defaults.write("spark.executor.extraJavaOptions					-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70\n")
	subprocess.check_call(["/bin/mv",spark_defaults_tmp_location,spark_default_final_location])

	# bashrc file
	with open("/home/hadoop/.bashrc","a") as bashrc:
		bashrc.write("export SCALA_HOME={0}".format(scala_home))

	# spark-env.sh
	spark_env_tmp_location = os.path.join(tmp_dir,"spark-env.sh")
	spark_env_final_location = os.path.join(spark_home,"conf")

	files= glob.glob("{0}/{1}/share/*/*/*/hadoop-*lzo.jar".format(hadoop_apps,hadoop_version))
	if len(files) < 1:
		files=glob.glob("{0}/{1}/share/*/*/*/hadoop-*lzo-*.jar".format(hadoop_apps,hadoop_version))
	if len(files) < 1:
		print "lzo not found inside {0}/{1}/share/".format(hadoop_apps,hadoop_version)
	else:
		lzo_jar=files[0]

	#subprocess.check_call(["/bin/mkdir","-p",spark_log_dir])
	subprocess.call(["/bin/mkdir","-p",spark_log_dir])

	with open(spark_env_tmp_location,'a') as spark_env:
		spark_env.write("export SPARK_DAEMON_JAVA_OPTS=\"-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70\"\n")
		spark_env.write("export SPARK_LOCAL_DIRS={0}\n".format(local_dir))
		spark_env.write("export SPARK_LOG_DIR={0}\n".format(spark_log_dir))
		spark_env.write("export SPARK_CLASSPATH=\"{0}/user-provided/*:{0}/emr/*:{1}/emrfs/*:{2}/share/hadoop/common/lib/*:{3}\"\n".format(spark_classpath,spark_classpath,spark_classpath,hadoop_home,lzo_jar))

	subprocess.check_call(["mv",spark_env_tmp_location,spark_env_final_location])

def start_history_server():
	# create hdfs folder for event logs (actually not needed, it will fail if run as BA)
	subprocess.check_call(["/home/hadoop/bin/hdfs","dfs","-mkdir","-p",spark_evlogs])
	# start spark history server
	history_server_script = os.path.join(spark_home,"sbin","start-history-server.sh")
	subprocess.check_call([history_server_script, spark_evlogs])



if __name__ == '__main__':
	args = sys.argv[1:]
	if len(args) >= 1:
		if args[0].upper() == 'BA':
			# this block is needed to avoid running the same BA multiple times in case
			# the instance-controller is restarted or the instance rebooted
			try:
				open(lock_file,'r')
				print "BA already executed"
			except Exception:
				userProvidedJars = ""
				if len(args) == 2:
					userProvidedJars = args[1]
				elif len(args) > 2:
					raise Exception("Unexpected number of arguments. Was expecting only 2 arguments at max. Arguments passed were {0}".format(args))
				download_and_uncompress_files()
				prepare_classpath(userProvidedJars)
				config()
				# create lock file
				open(lock_file,'a').close()

		if args[0].upper() == 'STEP':
			start_history_server()
	else:
		print sys.argv
		print "Available options are: BA <userProvidedJars>, STEP"			
