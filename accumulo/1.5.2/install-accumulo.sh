#!/bin/bash
set -x -e

cat > /home/hadoop/accumulo.sh << 'EOF2'
if ps ax | grep -v grep | egrep "datanode|namenode"> /dev/null
then
if [ ! -d "/home/hadoop/accumulo" ]; then

HOMEDIR=/home/hadoop
ACCUMULOV=1.5.2
ZOOKEEPRERV=3.4.6
ACCUMULO_TSERVER_OPTS=1GB

cd $HOMEDIR/.versions
wget http://download.nextag.com/apache/accumulo/${ACCUMULOV}/accumulo-${ACCUMULOV}-bin.tar.gz

echo "Downloading Zookeeper"
wget http://apache.mirrors.tds.net/zookeeper/stable/zookeeper-3.4.6.tar.gz
tar xzf zookeeper*tar.gz
ln -sf $HOMEDIR/.versions/zookeeper-${ZOOKEEPRERV}  $HOMEDIR/zookeeper

tar -xvzf accumulo-${ACCUMULOV}-bin.tar.gz
ln -sf $HOMEDIR/.versions/accumulo-$ACCUMULOV $HOMEDIR/accumulo

sudo yum install -y expect

cd ${HOMEDIR}

cp accumulo/conf/examples/${ACCUMULO_TSERVER_OPTS}/standalone/* accumulo/conf/



sed -i "s/<value>localhost:2181<\/value>/<value>$1:2181<\/value>/" accumulo/conf/accumulo-site.xml

cat >> accumulo/conf/accumulo-env.sh  << EOF
export ACCUMULO_HOME=/home/hadoop/accumulo
export HADOOP_HOME=/home/hadoop
export ACCUMULO_LOG_DIR=/mnt/var/log/hadoop
export ZOOKEEPER_HOME=/home/hadoop/zookeeper
export JAVA_HOME=/usr/lib/jvm/java
export HADOOP_PREFIX=/home/hadoop
export HADOOP_CONF_DIR=/home/hadoop/conf
EOF



#Run on master /slave based on configuration
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
expect -c "
spawn  accumulo/bin/accumulo init
expect -nocase \"Instance name\" {send \"$2\r\"}
expect -nocase \"Enter initial password for*\" {send \"$3\r\"}
expect -nocase \"*password*\" {send \"$3\r\r\";expect eof}"
curl http://169.254.169.254/latest/meta-data/local-ipv4 > accumulo/conf/masters
echo 'x' > accumulo/conf/slaves
accumulo/bin/start-all.sh  > accumulo/logs/start-all.log

else
curl http://169.254.169.254/latest/meta-data/local-ipv4 > accumulo/conf/slaves
MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
echo $MASTER > accumulo/conf/masters
accumulo/bin/tup.sh
fi

accumulo/bin/start-here.sh
sudo sed -i 's/.*accumulo.*//' /etc/crontab
fi
fi
EOF2

sudo sh -c "echo '*/1     * * * *   hadoop     bash /home/hadoop/accumulo.sh $1 $2 $3 > /home/hadoop/cron.log 2>&1 ' >> /etc/crontab"
echo "Done"