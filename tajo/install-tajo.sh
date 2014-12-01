#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# The EMR Bootstrap for Tajo
#
# Arguments
#
# -t    The tajo binary Tarball URL.
#       ex) s3://tajo-release/tajo-0.9.0/tajo-0.9.0.tar.gz 
#       or 
#       http://apache.claz.org/tajo/tajo-0.9.0/tajo-0.9.0.tar.gz
#
# -c    The tajo conf directory URL.
#       ex) s3://tajo-emr/tajo-0.9.0/ami-3.3.0/m1.medium/conf
#
# -l    The tajo third party lib URL.
#       ex) s3://tajo-emr/tajo-0.9.0/ami-3.3.0/m1.medium/lib
#
# -h    The help
#
# -T	The Test directory path(Test mode)
#
# -H    The Test HADOOP_HOME(Test mode)
#

## setting header for xml
function start_configuration() {
   echo "<?xml version=\"1.0\"?>"
   echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>"
   echo "<configuration>"
}

## setting property for xml
function set_property() {
   echo "<property><name>$1</name><value>$2</value></property>"
}

## setting tail for xml
function end_configuration() {
   echo "</configuration>"
}

## Clean up
function cleanup() {
   echo "Info: Clean up."
   rm -rf $1
}

## Download package
# $1: srcPath
# $2: destPath
function download() {
   echo "Info: Download package."
   if [ $TEST_MODE = "true" ]
   then
      cp -r $1 $2
   else
      if [ `expr "$1" : http` -gt 0 ]
      then
         curl -o $2 $1
      else
         $HADOOP_HOME/bin/hadoop dfs -copyToLocal $1 $2
      fi
   fi
}

## Unpack
# $1: destPath
# $2: packagePath
function unpack() {
   echo "Info: Unpack."
   cd $1
   tar -xvf $2
}

## Setting tajo conf
function set_tajo_conf() {
   echo "Info: Setting tajo conf."
   if [ ! -z $TAJO_CONF_URI ]
   then
      mkdir $TAJO_HOME/conf/temp
      # Test mode
      if [ $TEST_MODE = "true" ]
      then
         cp -r ${TAJO_CONF_URI}/* $TAJO_HOME/conf/temp
      else
         $HADOOP_HOME/bin/hadoop dfs -copyToLocal ${TAJO_CONF_URI}/* $TAJO_HOME/conf/temp 
      fi
      mv $TAJO_HOME/conf/temp/* $TAJO_HOME/conf
      chmod 755 $TAJO_HOME/conf/tajo-env.sh
      rm -rf $TAJO_HOME/conf/temp
   fi
   echo "" >> $TAJO_HOME/conf/tajo-env.sh
   echo 'export TAJO_CLASSPATH="$TAJO_CLASSPATH:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/lib/*"' >> $TAJO_HOME/conf/tajo-env.sh
   echo "export JAVA_HOME=$JAVA_HOME" >> $TAJO_HOME/conf/tajo-env.sh
   echo "export HADOOP_HOME=$HADOOP_HOME" >> $TAJO_HOME/conf/tajo-env.sh
   if [ -f "${TAJO_HOME}/conf/tajo-site.xml" ] 
   then
      sed -e 's:</configuration>::g' $TAJO_HOME/conf/tajo-site.xml > $TAJO_HOME/conf/tajo-site.xml.tmp
      mv $TAJO_HOME/conf/tajo-site.xml.tmp $TAJO_HOME/conf/tajo-site.xml
   else
      echo $(start_configuration) >> ${TAJO_HOME}/conf/tajo-site.xml
   fi
   echo $(set_property "tajo.master.umbilical-rpc.address" "${TAJO_MASTER}:26001") >> ${TAJO_HOME}/conf/tajo-site.xml
   echo $(set_property "tajo.master.client-rpc.address" "${TAJO_MASTER}:26002") >> ${TAJO_HOME}/conf/tajo-site.xml
   echo $(set_property "tajo.resource-tracker.rpc.address" "${TAJO_MASTER}:26003") >> ${TAJO_HOME}/conf/tajo-site.xml
   echo $(set_property "tajo.catalog.client-rpc.address" "${TAJO_MASTER}:26005") >> ${TAJO_HOME}/conf/tajo-site.xml
   
   # Default rootdir is EMR hdfs
   if [ -z `grep tajo.rootdir ${TAJO_HOME}/conf/tajo-site.xml` ]
   then
      STORAGE=local
      echo $(set_property "tajo.rootdir" "hdfs://${NAME_NODE}:9000/tajo") >> ${TAJO_HOME}/conf/tajo-site.xml
   fi
   echo $(end_configuration) >> ${TAJO_HOME}/conf/tajo-site.xml
}

## Download Third party Library
function third_party_lib() {
   echo "Info: Download Third party Library..."
   if [ ! -z $LIBRARY_URI ]
   then
      # Test mode
      if [ $TEST_MODE = "true" ]
      then
         cp -r ${LIBRARY_URI}/* ${TAJO_HOME}/lib
      else
         if [ `expr "$LIBRARY_URI" : http` -gt 0 ]
         then
            wget -P ${TAJO_HOME}/lib $LIBRARY_URI
         else
            $HADOOP_HOME/bin/hadoop dfs -copyToLocal ${LIBRARY_URI}/* ${TAJO_HOME}/lib
         fi
      fi
   fi
}

## Create start invoke file
function create_start_invoke_file() {
   echo '#!/bin/bash' >> ${TAJO_HOME}/$1
   echo 'grep -Fq "\"isMaster\": true" /mnt/var/lib/info/instance.json' >> ${TAJO_HOME}/$1
   echo 'if [ $? -eq 0 ]; then' >> ${TAJO_HOME}/$1
   if [ $STORAGE = "local" ]; then
   echo "   nc -z $NAME_NODE 9000" >> ${TAJO_HOME}/$1
   echo '   while [ $? -eq 1 ]; do' >> ${TAJO_HOME}/$1
   echo "      sleep 5" >> ${TAJO_HOME}/$1
   echo "      nc -z $NAME_NODE 9000" >> ${TAJO_HOME}/$1
   echo "   done" >> ${TAJO_HOME}/$1
   fi
   echo "   ${TAJO_HOME}/bin/tajo-daemon.sh start master" >> ${TAJO_HOME}/$1
   echo "else" >> ${TAJO_HOME}/$1
   echo "   nc -z $TAJO_MASTER 26001" >> ${TAJO_HOME}/$1
   echo '   while [ $? -eq 1 ]; do' >> ${TAJO_HOME}/$1
   echo "      sleep 5" >> ${TAJO_HOME}/$1
   echo "      nc -z $TAJO_MASTER 26001" >> ${TAJO_HOME}/$1
   echo "   done" >> ${TAJO_HOME}/$1
   echo "   ${TAJO_HOME}/bin/tajo-daemon.sh start worker" >> ${TAJO_HOME}/$1
   echo "fi" >> ${TAJO_HOME}/$1
   chmod 755 ${TAJO_HOME}/$1
}

## Initialize global variable
function init() {
   echo "Info: Initializing."
   if [ $TEST_MODE = "true" ]
   then
      if [ -z $JAVA_HOME ]
      then
         echo "Error: JAVA_HOME is not set."
         exit 1
      fi
      if [ -z $TEST_DIR ]
      then
         echo "Error: -T is not set."
         help
         exit 1
      fi
      if [ -z $TEST_HADOOP_HOME ]
      then
         echo "Error: -H is not set."
         help
         exit 1
      fi
      mkdir -p $TEST_DIR
      cp -r $TEST_HADOOP_HOME $TEST_DIR/hadoop
      export HADOOP_HOME=$TEST_DIR/hadoop
      TAJO_MASTER="localhost"
   else
      TAJO_MASTER=$(grep -i "yarn.resourcemanager.address<" ${HADOOP_HOME}/etc/hadoop/yarn-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
      TEST_MODE="false"
   fi
   STORAGE=S3
   NAME_NODE=$TAJO_MASTER
   if [ -z $TAJO_PACKAGE_URI ]
   then
      TAJO_PACKAGE_URI='http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.9.0/tajo-0.9.0.tar.gz'
   fi
}

## Print Help
function help() {
   echo 'usage : install-tajo.sh [-t] [-c] [-l] [-h] [-T] [-H]'
   echo '-t : The tajo binary Tarball URL.'
   echo '-c : The tajo conf directory URL.'
   echo '-l : The tajo third party lib URL.'
   echo '-h : The help.'
   echo '-T : The Test directory path(Test mode)'
   echo '-H : The Test HADOOP_HOME(Test mode)'
}

## Global variable
TAJO_PACKAGE_URI=
TAJO_CONF_URI=
TAJO_HOME=
LIBRARY_URI=
STORAGE=
NAME_NODE=
START_INVOKE_FILE="start-emr-tajo.sh"
TEST_MODE="false"
TEST_DIR=
TEST_HADOOP_HOME=
TAJO_MASTER=

## Main
# Get Arguments
while getopts ":t::c::l::T::H:h" opt;
do
   case $opt in
   t) TAJO_PACKAGE_URI=$OPTARG;;
   c) TAJO_CONF_URI=$OPTARG;;
   l) LIBRARY_URI=$OPTARG;;
   h) help; exit 0 ;;
   T) TEST_MODE=true; TEST_DIR=$OPTARG;;
   H) TEST_HADOOP_HOME=$OPTARG;;
   esac
done

if [ $TEST_MODE = "true" ]
then
   cleanup $TEST_DIR
else
   cleanup $HADOOP_HOME/tajo*
fi

init

download $TAJO_PACKAGE_URI $HADOOP_HOME

package_file_name=`basename $TAJO_PACKAGE_URI`
unpack $HADOOP_HOME $HADOOP_HOME/$package_file_name
 
ln -s $HADOOP_HOME/${package_file_name%.tar*} $HADOOP_HOME/tajo
TAJO_HOME=$HADOOP_HOME/tajo

set_tajo_conf

third_party_lib

echo "Info: Start Tajo..."
if [ $TEST_MODE = "true" ]
then
   ${TAJO_HOME}/bin/tajo-daemon.sh start master
   ${TAJO_HOME}/bin/tajo-daemon.sh start worker
else
   create_start_invoke_file $START_INVOKE_FILE
   ${TAJO_HOME}/$START_INVOKE_FILE &
fi
