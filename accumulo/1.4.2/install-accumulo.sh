#!/bin/bash

cd /home/hadoop

cat > /home/hadoop/accumulo.sh << 'EOF2'
if ps ax | grep -v grep | egrep "datanode|namenode"> /dev/null
then
if [ ! -d "/home/hadoop/accumulo-1.4.2" ]; then
cd /home/hadoop/

#Download the required packages and Accumulo tar ball
sudo apt-get -y install zookeeper expect
wget https://elasticmapreduce.s3.amazonaws.com/samples/accumulo/1.4.2/accumulo-1.4.2-dist.tar.gz
tar -xvzf accumulo-1.4.2-dist.tar.gz

#Copy configuration
cp accumulo-1.4.2/conf/examples/1GB/standalone/* accumulo-1.4.2/conf/

#Substitute Zookeeper values in configuration
sed -i "s/<value>localhost:2181<\/value>/<value>$1:2181<\/value>/" accumulo-1.4.2/conf/accumulo-site.xml

#Setting up env variables
cat >> accumulo-1.4.2/conf/accumulo-env.sh  << EOF
export ACCUMULO_HOME=/home/hadoop/accumulo-1.4.2
export HADOOP_HOME=/home/hadoop
export ACCUMULO_LOG_DIR=/mnt/var/log/hadoop
export ZOOKEEPER_HOME=/usr/share/java
export JAVA_HOME=/usr/lib/jvm/java-7-oracle
EOF

#Run on master /slave based on configuration
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
expect -c "
spawn  accumulo-1.4.2/bin/accumulo init
expect -nocase \"Instance name\" {send \"$2\r\"}
expect -nocase \"Enter initial password for*\" {send \"$3\r\"}
expect -nocase \"*password*\" {send \"$3\r\r\";expect eof}"
GET http://169.254.169.254/latest/meta-data/local-ipv4 > accumulo-1.4.2/conf/masters
echo 'x' > accumulo-1.4.2/conf/slaves
accumulo-1.4.2/bin/start-all.sh  > accumulo-1.4.2/logs/start-all.log

else
GET http://169.254.169.254/latest/meta-data/local-ipv4 > accumulo-1.4.2/conf/slaves
MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo $MASTER > accumulo-1.4.2/conf/masters
accumulo-1.4.2/bin/tup.sh
fi

#Add the node to cluster
accumulo-1.4.2/bin/start-here.sh
sudo sed -i 's/.*accumulo.*//' /etc/crontab
fi
fi
EOF2

sudo sh -c "echo '*/1     * * * *   hadoop     bash /home/hadoop/accumulo.sh $1 $2 $3 > /home/hadoop/cron.log 2>&1 ' >> /etc/crontab"
