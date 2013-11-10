#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#!/bin/bash
function install_tarball_no_md5_no_overwrite {
  if [[ "$1" != "" ]]; then
    # Download a .tar.gz file and extract to target dir

    local tar_url=$1
    local tar_file=`basename $tar_url`

    local target=/home/hadoop
    mkdir -p $target

    local curl="curl -L --silent --show-error --fail --connect-timeout 10 --max-time 600 --retry 5"
    # any download should take less than 10 minutes

    for retry_count in `seq 1 3`;
    do
      $curl -O $tar_url || true

      if [ ! $retry_count -eq "3" ]; then
        sleep 10
      fi
    done

    if [ ! -e $tar_file ]; then
      echo "Failed to download $tar_file. Aborting."
      exit 1
    fi

    # Using -k so we don't overwrite any other roles' druid configs
    tar kxzf $tar_file -C $target
    rm -f $tar_file
  fi
}

function install_zookeeper {
  sudo apt-get -y install zookeeper expect
}

function install_drill {
  install_tarball_no_md5_no_overwrite http://people.apache.org/~jacques/apache-drill-1.0.0-m1.rc3/apache-drill-1.0.0-m1-binary-release.tar.gz
  mv apache-drill-1.0.0-m1 drill
  mkdir /home/hadoop/drill/drill_log
  cp -f /home/hadoop/drill/drill-override.conf /home/hadoop/drill/conf/drill-override.conf
  mkdir -p /mnt/var/run/drill
  cp start_drill.sh /mnt/var/run/drill/run_drill
}

install_zookeeper
install_drill
