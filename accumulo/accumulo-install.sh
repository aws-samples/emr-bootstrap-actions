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

cd /home/hadoop

cat > /home/hadoop/accumulo.sh << 'EOF2'
if ps ax | grep -v grep | egrep "datanode|namenode"> /dev/null
then
if [ ! -d "/home/hadoop/accumulo-1.4.2" ]; then
cd /home/hadoop/
sudo apt-get -y install zookeeper expect
wget http://mirrors.sonic.net/apache/accumulo/1.4.2/accumulo-1.4.2-dist.tar.gz
tar -xvzf accumulo-1.4.2-dist.tar.gz
##cp -a accumulo-1.4.2 /home/hadoop/
cp accumulo-1.4.2/conf/examples/1GB/standalone/* accumulo-1.4.2/conf/
sed -i "s/<value>localhost:2181<\/value>/<value>$1:2181<\/value>/" accumulo-1.4.2/conf/accumulo-site.xml

cat >> accumulo-1.4.2/conf/accumulo-env.sh  << EOF
export ACCUMULO_HOME=/home/hadoop/accumulo-1.4.2
export HADOOP_HOME=/home/hadoop
export ACCUMULO_LOG_DIR=/mnt/var/log/hadoop
export ZOOKEEPER_HOME=/usr/share/java
export JAVA_HOME=/usr/lib/jvm/java-6-sun
EOF


grep -Fq '"isMaster":true' /mnt/var/lib/info/instance.json
if [ $? -eq 0 ];
then
        expect -c "
        spawn  accumulo-1.4.2/bin/accumulo init
        expect -nocase \"Instance name\" {send \"$2\r\"}
        expect -nocase \"Enter initial password for*\" {send \"$3\r\"}
        expect -nocase \"*password*\" {send \"$3\r\r\";expect eof}"
        hostname > accumulo-1.4.2/conf/masters
        echo 'x' > accumulo-1.4.2/conf/slaves

else
        hostname > accumulo-1.4.2/conf/slaves
        MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
        echo $MASTER > accumulo-1.4.2/conf/masters
fi

accumulo-1.4.2/bin/start-here.sh
sudo sed -i 's/.*accumulo.*//' /etc/crontab
fi
fi
EOF2

sudo sh -c "echo '*/1     * * * *   hadoop     bash /home/hadoop/accumulo.sh $1 $2 $3 > /home/hadoop/cron.log 2>&1 ' >> /etc/crontab"
