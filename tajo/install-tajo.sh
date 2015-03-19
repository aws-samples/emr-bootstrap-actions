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
# -t, --tar    
#       The tajo binary Tarball URL.(Optional)
#
#       ex) --tar http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.10.0/tajo-0.10.0.tar.gz
#       or 
#       --tar s3://[your_bucket]/[your_path]/tajo-{version}.tar.gz
#
# -c, --conf
#       The tajo conf directory URL.(Optional)
#
#       ex) --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf
#
# -l, --lib
#       The tajo third party lib URL.(Optional)
#
#       ex) --lib s3://{your_bucket}/{your_lib_dir}
#       or
#       --lib http://{lib_url}/{lib_file_name.jar}
#
# -v, --tajo-version
#       The tajo release version.(Optional)
#       Default: Apache tajo stable version.
#
#       ex) x.x.x
#
# -h, --help
#       The help
#
# -e, --env
#       The item of tajo-env.sh(Optional, space delimiter)
#
#       ex) --tajo-env.sh "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"
#
# -s, --site
#       The item of tajo-site.xml(Optional, space delimiter)
#
#       ex) --tajo-site.xml "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore"
#
# -T, --test-home
#       The Test directory path(Only test)
#
#       ex) --test-home "/home/hadoop/bootstrap_test"
#
# -H, --test-hadoop-home
#       The Test HADOOP_HOME(Only test)
#
#       ex) --test-hadoop-home "/home/hadoop"
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
         curl -o $2/`basename $1` $1
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
      chmod +x $TAJO_HOME/conf/tajo-env.sh
      rm -rf $TAJO_HOME/conf/temp
   fi
   echo "" >> $TAJO_HOME/conf/tajo-env.sh
   echo 'export TAJO_CLASSPATH="$TAJO_CLASSPATH:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/lib/*"' >> $TAJO_HOME/conf/tajo-env.sh
   echo "export JAVA_HOME=$JAVA_HOME" >> $TAJO_HOME/conf/tajo-env.sh
   echo "export HADOOP_HOME=$HADOOP_HOME" >> $TAJO_HOME/conf/tajo-env.sh
   # using --env option
   if [ ! -z "$TAJO_ENV" ]
   then
      for property in $(echo "$TAJO_ENV" | tr " " "\n")
      do
         echo "export $property" >> $TAJO_HOME/conf/tajo-env.sh
      done
   fi
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
   # setting tmp_dir
   if [ $TEST_MODE != "true" ]
   then
      tmpdirs=($(grep -i "dfs.name.dir<" $HADOOP_HOME/etc/hadoop/hdfs-site.xml | grep -oP '(?<=value>)[^<]+'))
      for dir in $(echo "$tmpdirs" | tr "," "\n")
      do
         if [ -z $tmpdir ]; then
            tmpdir="$dir"/tajo/tmp
         else
            tmpdir="$tmpdir,$dir"/tajo/tmp
         fi
      done
      echo $(set_property "tajo.worker.tmpdir.locations" ${tmpdir}) >> ${TAJO_HOME}/conf/tajo-site.xml
   fi
   # using --site option
   if [ ! -z "$TAJO_SITE" ]
   then
      for property in $(echo "$TAJO_SITE" | tr " " "\n")
      do
         name=`echo "$property" | awk -F "\"*=\"*" '{print $1}'`
         value=`echo "$property" | awk -F "\"*=\"*" '{print $2}'`
         echo $(set_property "$name" "$value") >> ${TAJO_HOME}/conf/tajo-site.xml
      done
   fi
   # Default rootdir is EMR hdfs
   if [ -z `grep tajo.rootdir ${TAJO_HOME}/conf/tajo-site.xml` ]
   then
      STORAGE=local
      if [ $TEST_MODE = "true" ]
      then
         echo $(set_property "tajo.rootdir" "file:///${TAJO_HOME}/tajo") >> ${TAJO_HOME}/conf/tajo-site.xml
      else
         echo $(set_property "tajo.rootdir" "hdfs://${NAME_NODE}:${NAME_NODE_PORT}/tajo") >> ${TAJO_HOME}/conf/tajo-site.xml      	
      fi
   fi
   echo $(end_configuration) >> ${TAJO_HOME}/conf/tajo-site.xml
}

## Download Third party Library
function third_party_lib() {
   echo "Info: Download Third party Library."
   if [ ! -z $LIBRARY_URI ]
   then
      # Test mode
      if [ $TEST_MODE = "true" ]
      then
         cp -r ${LIBRARY_URI}/* ${TAJO_HOME}/lib
      else
         if [ `expr "$LIBRARY_URI" : http` -gt 0 ]
         then
            curl -o ${TAJO_HOME}/lib/`basename $LIBRARY_URI` $LIBRARY_URI
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
   echo "   nc -z $NAME_NODE $NAME_NODE_PORT" >> ${TAJO_HOME}/$1
   echo '   while [ $? -eq 1 ]; do' >> ${TAJO_HOME}/$1
   echo "      sleep 5" >> ${TAJO_HOME}/$1
   echo "      nc -z $NAME_NODE $NAME_NODE_PORT" >> ${TAJO_HOME}/$1
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
   chmod +x ${TAJO_HOME}/$1
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
      TAJO_MASTER=$(grep -i "yarn.resourcemanager.address<" ${HADOOP_HOME}/etc/hadoop/yarn-site.xml | grep -oP '(?<=value>)[^:<]+')
      TEST_MODE="false"
   fi
   STORAGE=S3
   NAME_NODE=$TAJO_MASTER
   if [ -z $TAJO_PACKAGE_URI ]
   then
      TAJO_PACKAGE_URI="http://d3kp3z3ppbkcio.cloudfront.net/tajo-$TAJO_VERION/tajo-$TAJO_VERION.tar.gz"
   fi
}

## Print Help
function help() {
   echo 'usage : install-tajo.sh [-t|--tar] [-c|--conf] [-l|--lib] [-h|--help] [-e|--env] [-s|--site] [-T|--test-home] [-H|--test-hadoop-home]'
   echo ' -t, --tar'    
   echo '       The tajo binary Tarball URL.(Optional)'
   echo '       ex) --tar http://apache.mirror.cdnetworks.com/tajo/tajo-0.10.0/tajo-0.10.0.tar.gz'
   echo '       or' 
   echo '       --tar s3://[your_bucket]/[your_path]/tajo-0.10.0.tar.gz'
   echo ' -c, --conf'
   echo '       The tajo conf directory URL.(Optional)'
   echo '       ex) --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf'
   echo ' -l, --lib'
   echo '       The tajo third party lib URL.(Optional)'
   echo '       ex) --lib s3://{your_bucket}/{your_lib_dir}'
   echo '       or'
   echo '       --lib http://{lib_url}/{lib_file_name.jar}'
   echo ' -v, --tajo-version'
   echo '       The tajo release version.(Optional)'
   echo '       Default: Apache tajo stable version.'
   echo '       ex) x.x.x'
   echo ' -h, --help'
   echo '       The help'
   echo ' -e, --env'
   echo '       The item of tajo-env.sh(Optional, space delimiter)'
   echo '       ex) --tajo-env.sh "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"'
   echo ' -s, --site'
   echo '       The item of tajo-site.xml(Optional, space delimiter)'
   echo '       ex) --tajo-site.xml "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore"'
   echo ' -T, --test-home'
   echo '       The Test directory path(Only test)'
   echo '       ex) --test-home "/home/hadoop/bootstrap_test"'
   echo ' -H, --test-hadoop-home'
   echo '       The Test HADOOP_HOME(Only test)'
   echo '       ex) --test-hadoop-home "/home/hadoop"'
}

## Global variable
TAJO_VERION=0.9.0
TAJO_PACKAGE_URI=
TAJO_CONF_URI=
TAJO_HOME=
LIBRARY_URI=
STORAGE=
NAME_NODE=
NAME_NODE_PORT=9000
START_INVOKE_FILE="start-emr-tajo.sh"
TEST_MODE="false"
TEST_DIR=
TEST_HADOOP_HOME=
TAJO_MASTER=
TAJO_ENV=
TAJO_SITE=

## Main
# Get Arguments
while [ $# -gt 0 ]
do
  case "$1" in
    -t)
      shift; TAJO_PACKAGE_URI=$1;;
    --tar)
      shift; TAJO_PACKAGE_URI=$1;;
    -c)
      shift; TAJO_CONF_URI=$1;;
    --conf)
      shift; TAJO_CONF_URI=$1;;
    -l)
      shift; LIBRARY_URI=$1;;
    --lib)
      shift; LIBRARY_URI=$1;;
    -v)
      shift; TAJO_VERION=$1;;
    --tajo-version)
      shift; TAJO_VERION=$1;;
    -h)
      help; exit 0;;
    --help)
      help; exit 0;;
    -e)
      shift; TAJO_ENV=$1;;    
    --env)
      shift; TAJO_ENV=$1;;
    -s)
      shift; TAJO_SITE=$1;;   
    --site)
      shift; TAJO_SITE=$1;;
    -T)
      shift; TEST_MODE=true; TEST_DIR=$1;;
    --test-home)
      shift; TEST_MODE=true; TEST_DIR=$1;;
    -H)
      shift; TEST_HADOOP_HOME=$1;;
    --test-hadoop-home)
      shift; TEST_HADOOP_HOME=$1;;
    -*)
      echo "unrecognized option: $1"; exit 0;;
    *)
      break;
      ;;
  esac
  shift
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

echo "Info: Start Tajo."
if [ $TEST_MODE = "true" ]
then
   ${TAJO_HOME}/bin/tajo-daemon.sh start master
   ${TAJO_HOME}/bin/tajo-daemon.sh start worker
else
   create_start_invoke_file $START_INVOKE_FILE
   ${TAJO_HOME}/$START_INVOKE_FILE &
fi