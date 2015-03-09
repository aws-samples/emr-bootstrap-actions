cd /home/hadoop/

##Download Spark EMR
wget http://support.elasticmapreduce.s3.amazonaws.com/spark/0.8.1/spark-0.8.1-emr.tgz
##Download Shark
wget https://github.com/amplab/shark/releases/download/v0.8.1/shark-0.8.1-bin-hadoop1.tgz
##Download Scala
wget http://www.scala-lang.org/files/archive/scala-2.9.3.tgz
##DOwnload hive
wget https://github.com/amplab/shark/releases/download/v0.8.1/hive-0.9.0-bin.tgz

tar -xvzf scala-2.9.3.tgz
tar -xvzf spark-0.8.1-emr.tgz
tar -xvzf shark-0.8.1-bin-hadoop1.tgz
tar -xvzf hive-0.9.0-bin.tgz

ln -sf spark-0.8.1-emr spark
ln -sf /home/hadoop/shark-0.8.1-bin-hadoop1/ /home/hadoop/shark
ln -sf /home/hadoop/hive-0.9.0-bin /home/hadoop/hive
ln -sf /home/hadoop/scala-2.9.3 /home/hadoop/scala

MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
SPACE=$(mount | grep mnt | awk '{print $3"/spark/"}' | xargs | sed 's/ /,/g')
PUB_HOSTNAME=$(GET http://169.254.169.254/latest/meta-data/public-hostname)

touch /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_CLASSPATH=/home/hadoop/spark/jars/*">> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_MASTER_IP=$MASTER">> /home/hadoop/spark/conf/spark-env.sh
echo "export MASTER=spark://$MASTER:7077" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_LIBRARY_PATH=/home/hadoop/native/Linux-amd64-64" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=$SPACE\"" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_WORKER_DIR=/mnt/var/log/hadoop/userlogs/" >> /home/hadoop/spark/conf/spark-env.sh
cp /home/hadoop/spark/conf/metrics.properties.aws /home/hadoop/spark/conf/metrics.properties

cp /home/hadoop/lib/gson-* /home/hadoop/spark/jars/
##cp /home/hadoop/lib/aws-java-sdk-* /home/hadoop/spark/jars/
cp /home/hadoop/conf/core-site.xml /home/hadoop/spark/conf/
cp /home/hadoop/lib/EmrMetrics*.jar  /home/hadoop/spark/jars/
cp /home/hadoop/hive/lib/hive-builtins-0.9.0-shark-0.8.1.jar /home/hadoop/spark/jars/
cp /home/hadoop/hive/lib/hive-exec-0.9.0-shark-0.8.1.jar /home/hadoop/spark/jars/
685b35bc544f:~ bulina$ diff Downloads/sparkBuild/install-spark-shark.sh Downloads/install-spark-shark.sh
4c4
< wget http://support.elasticmapreduce.s3.amazonaws.com/spark/0.8.1/spark-0.8.1-emr.tgz
---
> wget http://bigdatademo.s3.amazonaws.com/0.8.1-dev1/spark-0.8.1-emr.tgz
685b35bc544f:~ bulina$ cat Downloads/sparkBuild/install-spark-shark.sh
cd /home/hadoop/

##Download Spark EMR
wget http://support.elasticmapreduce.s3.amazonaws.com/spark/0.8.1/spark-0.8.1-emr.tgz
##Download Shark
wget https://github.com/amplab/shark/releases/download/v0.8.1/shark-0.8.1-bin-hadoop1.tgz
##Download Scala
wget http://www.scala-lang.org/files/archive/scala-2.9.3.tgz
##DOwnload hive
wget https://github.com/amplab/shark/releases/download/v0.8.1/hive-0.9.0-bin.tgz

tar -xvzf scala-2.9.3.tgz
tar -xvzf spark-0.8.1-emr.tgz
tar -xvzf shark-0.8.1-bin-hadoop1.tgz
tar -xvzf hive-0.9.0-bin.tgz

ln -sf spark-0.8.1-emr spark
ln -sf /home/hadoop/shark-0.8.1-bin-hadoop1/ /home/hadoop/shark
ln -sf /home/hadoop/hive-0.9.0-bin /home/hadoop/hive
ln -sf /home/hadoop/scala-2.9.3 /home/hadoop/scala

MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
SPACE=$(mount | grep mnt | awk '{print $3"/spark/"}' | xargs | sed 's/ /,/g')
PUB_HOSTNAME=$(GET http://169.254.169.254/latest/meta-data/public-hostname)

touch /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_CLASSPATH=/home/hadoop/spark/jars/*">> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_MASTER_IP=$MASTER">> /home/hadoop/spark/conf/spark-env.sh
echo "export MASTER=spark://$MASTER:7077" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_LIBRARY_PATH=/home/hadoop/native/Linux-amd64-64" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=$SPACE\"" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_WORKER_DIR=/mnt/var/log/hadoop/userlogs/" >> /home/hadoop/spark/conf/spark-env.sh
cp /home/hadoop/spark/conf/metrics.properties.aws /home/hadoop/spark/conf/metrics.properties

cp /home/hadoop/lib/gson-* /home/hadoop/spark/jars/
##cp /home/hadoop/lib/aws-java-sdk-* /home/hadoop/spark/jars/
cp /home/hadoop/conf/core-site.xml /home/hadoop/spark/conf/
cp /home/hadoop/lib/EmrMetrics*.jar  /home/hadoop/spark/jars/
cp /home/hadoop/hive/lib/hive-builtins-0.9.0-shark-0.8.1.jar /home/hadoop/spark/jars/
cp /home/hadoop/hive/lib/hive-exec-0.9.0-shark-0.8.1.jar /home/hadoop/spark/jars/
cp /home/hadoop/shark/target/scala-2.9.3/shark_2.9.3-0.8.1.jar /home/hadoop/spark/jars/

touch /home/hadoop/shark/conf/shark-env.sh
cp /home/hadoop/lib/gson-* /home/hadoop/shark/lib_managed/jars/
cp /home/hadoop/lib/aws-java-sdk-* /home/hadoop/shark/lib_managed/jars/
cp /home/hadoop/lib/EmrMetrics*.jar  /home/hadoop/shark/lib_managed/jars/
cp /home/hadoop/hadoop-core.jar /home/hadoop/shark/lib_managed/jars/org.apache.hadoop/hadoop-core/hadoop-core-1.0.4.jar
cp /home/hadoop/conf/core-site.xml /home/hadoop/hive/conf/

echo "export HIVE_HOME=/home/hadoop/hive/" >> /home/hadoop/shark/conf/shark-env.sh
echo "export SPARK_HOME=/home/hadoop/spark" >>  /home/hadoop/shark/conf/shark-env.sh
echo "source /home/hadoop/spark/conf/spark-env.sh">>    /home/hadoop/shark/conf/shark-env.sh
echo "export SCALA_HOME=/home/hadoop/scala" >> /home/hadoop/shark/conf/shark-env.sh

cat > /home/hadoop/hive/conf/hive-site.xml << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property><name>mapred.job.tracker</name><value>yarn</value></property><property><name>fs.default.name</name> <value>hdfs://$MASTER:9000</value></property>
</configuration>
EOF

grep -Fq "\"isMaster\": true" /mnt/var/lib/info/instance.json
if [ $? -eq 0 ];
then
        /home/hadoop/spark/bin/start-master.sh
else
        nc -z $MASTER 7077
        while [ $? -eq 1 ];                do
                        echo "Can't connect to the master, sleeping for 20sec"
                        sleep 20
                        nc -z  $MASTER 7077
                done
        echo "Conneting to the master was successful"
        echo "export SPARK_JAVA_OPTS=\"-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Dspark.local.dir=$SPACE\"" >> /home/hadoop/spark/conf/spark-env.sh
        echo "export SPARK_PUBLIC_DNS=$PUB_HOSTNAME" >> /home/hadoop/spark/conf/spark-env.sh
        /home/hadoop/spark/bin/spark-daemon.sh start org.apache.spark.deploy.worker.Worker `hostname` spark://$MASTER:7077
fi
