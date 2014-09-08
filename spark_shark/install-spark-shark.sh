# Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

#!/bin/bash

mkdir /tmp/deb
cd /tmp/deb
# curl -O https://s3.amazonaws.com/elasticmapreduce/samples/spark/install/spark_0.5.deb
curl -O http://d3kbcqa49mib13.cloudfront.net/spark-1.0.0-bin-hadoop2.tgz
curl -O http://apache.arvixe.com/mesos/0.18.2/mesos-0.18.2.tar.gz
tar -xvf spark-1.0.0-bin-hadoop2.tgz
tar -xvf mesos-0.18.2.tar.gz
cd spark-* && 


cd mesos-*


sudo dpkg -i spark_0.5.deb
sudo dpkg -i /tmp/mesos_0.9.0-1_amd64.deb

sudo ldconfig

HADOOP_HOME=/home/hadoop
SPARK_HOME=$HADOOP_HOME/spark
SHARK_HOME=$HADOOP_HOME/shark

CPUS=`grep processor /proc/cpuinfo | wc -l`
MEM_KB=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
MEM=$[(MEM_KB - 1024 * 1024) / 1024]
MEMG=$[MEM / 1024]
RESOURCES="cpus:$CPUS;mem:$MEM"
MEM_SPARK=$[(MEM-500)]

echo "resources=$RESOURCES" >> /usr/local/var/mesos/conf/mesos.conf
echo "export SPARK_MEM=$MEM_SPARK"m"" >> $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_MEM=$MEM_SPARK"m"" >> $SHARK_HOME/conf/shark-env.sh

if [ $MEMG -le 32 ]
   then
        echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=/tmp -Dspark.kryoserializer.buffer.mb=10 -XX:+UseCompressedOops\"" >> $SPARK_HOME/conf/spark-env.sh
        echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=/tmp -Dspark.kryoserializer.buffer.mb=10 -XX:+UseCompressedOops\"" >> $SHARK_HOME/conf/shark-env.sh
   fi
if [ $MEMG -ge 32 ]
   then
        echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=/tmp -Dspark.kryoserializer.buffer.mb=10\"" >> $SPARK_HOME/conf/spark-env.sh
        echo "export SPARK_JAVA_OPTS=\"-Dspark.local.dir=/tmp -Dspark.kryoserializer.buffer.mb=10\"" >> $SHARK_HOME/conf/shark-env.sh
   fi

MASTER=$(grep -i "job.tracker<" $HADOOP_HOME/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

echo "export MASTER=master@$MASTER:5050" >> $SPARK_HOME/conf/spark-env.sh
echo "export MASTER=master@$MASTER:5050" >> $SHARK_HOME/conf/shark-env.sh

sudo sed -i "s/master=/master=master@$MASTER:5050/" /usr/local/var/mesos/conf/mesos.conf
ln -s $HADOOP_HOME/.versions/0.20.205/conf/core-site.xml $SPARK_HOME/conf/

grep -Fq '"isMaster":true' /mnt/var/lib/info/instance.json
if [ $? -eq 0 ]; 
then
	/etc/init.d/mesos-master.sh start
else
	/etc/init.d/mesos-slave.sh start
fi
