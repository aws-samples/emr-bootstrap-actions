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
# AWS EMR booptstrap script
# for install Apache Hama on EMR
#
# Arguments
# -h, --help
#       Show help page.
#
# -u, --url (Optional)
#       Hama release download URL. Only tarball file is possible.
#       ex)
#         -u http://apache.mirror.cdnetworks.com/hama/hama-{version}/hama-{version}.tar.gz
#         --url s3://[your_bucket]/[path_to]/hama-{version}.tar.gz
# 
# -c, --conf (Optional)
#       Addtional properties for Hama configuration.(Space-separated delimiter)
#       ex)
#         -c "bsp.master.address=host1.mydomain.com:40000 hama.zookeeper.quorum=host1.mydomain.com,host2.mydomain.com"
#
# -e, --env (Optional)
#       Set environment variables in hama-env.sh.(Space-separated delimiter)
#       ex)
#         -e "HAMA_LOG_DIR=[path_to_log_dir] HAMA_MANAGE_ZK=true"
#
#

# Setting up header part for hama configuration.
function start_configuration() {
   echo "<?xml version=\"1.0\"?>"
   echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>"
   echo "<configuration>"
}

# Setting up bottom part for hama configuration.
function end_configuration() {
   echo "</configuration>" 
}

# Setting up property for hama configuration.
# $1 : Configuration name
# $2 : Configuration value
function set_property() {
    echo "<property><name>$1</name><value>$2</value></property>"
}

# Calcurate the number of tasks, depending on Amazon EC2 instance type.
# $1: Memory size of java child task
function cal_num_task() {
    instance_group=$(cat /mnt/var/lib/info/job-flow.json | jp 'instanceGroups[0].instanceGroupName' | awk -F "\"" '{print $2}')
    instance_type=
    if [ "${instance_group}" = "CORE" ]
    then
        instance_type=$(cat /mnt/var/lib/info/job-flow.json | jp 'instanceGroups[0].instanceType' | awk -F "\"" '{print $2}')
    else
        instance_type=$(cat /mnt/var/lib/info/job-flow.json | jp 'instanceGroups[1].instanceType' | awk -F "\"" '{print $2}')
    fi

    if [ -n $instance_type ]
    then
        hadoop fs -copyToLocal s3://hamacluster/instance_info /home/hadoop
        mem_info=$(cat /home/hadoop/instance_info | awk '/'$instance_type'/ {print $2}')
        mem_size=$(echo "$mem_info" | awk -F "." '{print $1}')
        HAMA_TASK_NUM=$(echo "($mem_size-2)/$1" | bc)
    fi
}

# Make hama configuration run on Amazon EMR
# for hadoop version 1.0.3
function make_hama_conf() {
    echo "Info: Make hama configuration..."

    # Add hama environment variables.
    echo "" >> $HAMA_HOME/conf/hama-env.sh
    echo "export JAVA_HOME=$JAVA_HOME" >> $HAMA_HOME/conf/hama-env.sh
    if [ -n "$HAMA_ENV" ]
    then
        for var in $(echo "$HAMA_ENV" | awk -F " " '{print}')
        do
            echo "export $var" >> $HAMA_HOME/conf/hama-env.sh
        done
    fi

    echo $(start_configuration) > ${HAMA_HOME}/conf/hama-site.xml

    echo $(set_property "bsp.master.address" "${HAMA_MASTER}:${HAMA_MASTER_PORT}") >> ${HAMA_HOME}/conf/hama-site.xml
    echo $(set_property "fs.default.name" "$(grep -i "fs.default.name<" $HADOOP_HOME/conf/core-site.xml | grep -oP '(?<=value>)[^<]+')") >> ${HAMA_HOME}/conf/hama-site.xml
    echo $(set_property "hama.zookeeper.quorum" "${HAMA_MASTER}") >> ${HAMA_HOME}/conf/hama-site.xml
    echo $(set_property "dfs.block.size" "134217728") >> ${HAMA_HOME}/conf/hama-site.xml
#    echo $(set_property "hama.graph.thread.pool.size" "256") >> ${HAMA_HOME}/conf/hama-site.xml

    if [ -n "$HAMA_SITE_PROPERTIES" ]
    then
        for property in $(echo "$HAMA_SITE_PROPERTIES" | awk -F " " '{print}')
        do
            name=$(echo "$property" | awk -F "\"*=\"*" '{print $1}')
            value=$(echo "$property" | awk -F "\"*=\"*" '{print $2}')
            echo $(set_property "$name" "$value") >> ${HAMA_HOME}/conf/hama-site.xml
        done
    fi

    # Calculate the number of tasks for Hama configuration properly.
    # This script assumes that java heap size per Hama task is 3072m as default value.
    bsp_child_java_opt=$(cat ${HAMA_HOME}/conf/hama-site.xml | grep -i 'bsp.child.java.opts' | grep -oP '(?<=value>)[^<]+' | grep -oP '[0-9]+')
    echo "bsp_child_java_opt ${bsp_child_java_opt}m"
    if [ $bsp_child_java_opt ]
    then
        echo "bsp child is not null"
        heap_size=$(echo "scale=1; $bsp_child_java_opt/1000" | bc)
        cal_num_task $heap_size
    else
        echo "HAMA_MAX_HEAP_SIZE: $HAMA_MAX_HEAP_SIZE"
        echo $(set_property "bsp.child.java.opts" "-Xmx3072m") >> ${HAMA_HOME}/conf/hama-site.xml
        heap_size=$(echo "scale=1; $HAMA_MAX_HEAP_SIZE/1000" | bc)
        cal_num_task $heap_size
    fi

    if [ -n $HAMA_TASK_NUM ]
    then
        max_task_num=$(cat ${HAMA_HOME}/conf/hama-site.xml | grep -i 'bsp.tasks.maximum')
        if [ -z $max_task_num ]; then
            echo $(set_property "bsp.tasks.maximum" "$HAMA_TASK_NUM") >> ${HAMA_HOME}/conf/hama-site.xml
        fi
    fi

    echo $(end_configuration) >> ${HAMA_HOME}/conf/hama-site.xml
}

# Create starting Hama file
function create_hama_start_file() {
    echo "Info: Creating hama start file..."
    echo '#!/bin/bash' >> ${HAMA_HOME}/$1
    echo 'grep -Fq "\"isMaster\": true" /mnt/var/lib/info/instance.json' >> ${HAMA_HOME}/$1
    echo 'if [ $? -eq 0 ]; then' >> ${HAMA_HOME}/$1
    echo "  ${HAMA_HOME}/bin/hama-daemon.sh --config ${HAMA_HOME}/conf start zookeeper" >> ${HAMA_HOME}/$1
    echo "  ${HAMA_HOME}/bin/hama-daemon.sh --config ${HAMA_HOME}/conf start bspmaster" >> ${HAMA_HOME}/$1
    echo "else" >> ${HAMA_HOME}/$1
    echo "  nc -z $HAMA_MASTER $HAMA_MASTER_PORT" >> ${HAMA_HOME}/$1
    echo '  while [ $? -eq 1 ]; do' >> ${HAMA_HOME}/$1
    echo "      sleep 5" >> ${HAMA_HOME}/$1
    echo "      nc -z $HAMA_MASTER $HAMA_MASTER_PORT" >> ${HAMA_HOME}/$1
    echo "  done" >> ${HAMA_HOME}/$1
    echo "  ${HAMA_HOME}/bin/hama-daemon.sh --config ${HAMA_HOME}/conf start groom" >> ${HAMA_HOME}/$1
    echo "fi" >> ${HAMA_HOME}/$1
    chmod +x ${HAMA_HOME}/$1
}

# Only hama-trunk version
function download() {
    echo "Info: Downloading hama package..."
    cd /home/hadoop
    if [ -n "$HAMA_RELEASE_URL" ]
    then
        protocol=`echo "$HAMA_RELEASE_URL" | awk -F ":" '{print $1}'`
        if [ "$protocol" = "s3" ]
        then
            hadoop fs -copyToLocal $HAMA_RELEASE_URL /home/hadoop
        else
            wget --no-check-certificate $HAMA_RELEASE_URL
        fi
        HAMA_TARBALL=`echo "$HAMA_RELEASE_URL" | awk -F"/" '{print $NF}'`    
        tar zxvf $HAMA_TARBALL
        HAMA_HOME=${HADOOP_HOME}`echo "$HAMA_TARBALL" | awk -F".tar" '{print $1}'` 
        echo "$HAMA_TARBALL"
        echo "$HAMA_HOME"
        chmod +x $HAMA_HOME/bin/*
    else
        wget --no-check-certificate http://people.apache.org/~edwardyoon/dist/0.7.0-RC1/hama-0.7.0-SNAPSHOT-for-Hadoop2.4.0.tar.gz
        tar zxvf /home/hadoop/hama-0.7.0-SNAPSHOT-for-Hadoop2.4.0.tar.gz
        mv hama-0.7.0-SNAPSHOT hama-0.7.0
        chmod +x $HAMA_HOME/bin/*
    fi
    }

# Initialization
function init() {
    echo "Info: Initializing..."

    HAMA_MASTER=$(grep -i "fs.default.name<" $HADOOP_HOME/conf/core-site.xml | grep -oP '(?<=value>)[^<]+' | awk -F/ '{print $3}' | awk -F: '{print $1}')
    NAME_NODE=$HAMA_MASTER
}

function print_help() {
    echo 'Usage: ./install-hama.sh [OPTIONS]'
    echo ' -h, --help'
    echo '       Display help page.'
    echo ' -u, --url'
    echo '       Hama release download URL.'
    echo '       ex)'
    echo '         -u http://apache.mirror.cdnetworks.com/hama/hama-0.6.4/hama-0.6.4.tar.gz'
    echo '         --url s3://[your_bucket]/[path_to]/hama-{version}.tar.gz'
    echo ' -c, --conf'
    echo '       Addional properties for Hama configuration.(Space-separated delimiter)'
    echo '       ex) -c "bsp.master.address=host1.mydomain.com:40000 hama.zookeeper.quorum=host1.mydomain.com,host2.mydomain.com"'
    echo '         -c s3://[your_bucket]/[path_to]/hama-site.xml'
    echo ' -e, --env'
    echo '       The environment variables for hama-env.sh'
}

# Global variables
HAMA_HOME=/home/hadoop/hama-0.7.0
HADOOP_HOME=/home/hadoop/
INSTANCE_TYPE_URL=https://s3-ap-northeast-1.amazonaws.com/hamacluster/instance_info
# Hama default max heap size -Xmx3072m
HAMA_MAX_HEAP_SIZE=3072
HAMA_MASTER=
HAMA_MASTER_PORT=40000
HAMA_RELEASE_URL=
HAMA_TARBALL=
HAMA_SITE_PROPERTIES=
HAMA_ENV=
HAMA_TASK_NUM=
NAME_NODE=
START_HAMA_FILE="hama-start-emr.sh"

# Set up arguments
while [ $# -gt 0 ]
do
    case "$1" in
        -u|--url)
            HAMA_RELEASE_URL=$2
            shift;;
        -c|--conf)
            HAMA_SITE_PROPERTIES=$2
            shift;;
        -e|--env)
            HAMA_ENV=$2
            shift;;
        -h|--help)
            print_help; exit 0;;
        -*)
            echo "Unknown option: $1"; exit 0;;
        *)
            break; ;;
    esac
    shift
done

init

download

make_hama_conf

create_hama_start_file $START_HAMA_FILE
${HAMA_HOME}/$START_HAMA_FILE &
