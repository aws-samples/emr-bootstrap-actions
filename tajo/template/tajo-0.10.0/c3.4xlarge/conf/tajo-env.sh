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

# Set Tajo-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# Extra Java CLASSPATH elements.  Optional.
# export TAJO_CLASSPATH=/xxx/extlib/*:/xxx/xxx.jar

# The maximum amount of heap to use, in MB. Default is 1000.
# export TAJO_MASTER_HEAPSIZE=1000

# The maximum amount of heap to use, in MB. Default is 1000.
export TAJO_WORKER_HEAPSIZE=20000

# The maximum amount of heap to use, in MB. Default is 1000.
# export TAJO_PULLSERVER_HEAPSIZE=1000

# The maximum amount of heap to use, in MB. Default is 1000.
# export TAJO_QUERYMASTER_HEAPSIZE=1000

# Extra Java runtime options.  Empty by default.
# export TAJO_OPTS=-server

# Extra TajoMaster's java runtime options for TajoMaster. Empty by default
# export TAJO_MASTER_OPTS=

# Extra TajoWorker's java runtime options. Empty by default
export TAJO_WORKER_OPTS="-XX:+UseParallelGC -XX:+UseParallelOldGC -XX:-UseGCOverheadLimit"

# Extra TajoPullServer's java runtime options. Empty by default
# export TAJO_PULLSERVER_OPTS=

# Extra  QueryMaster mode TajoWorker's java runtime options for TajoMaster. Empty by default
# export TAJO_QUERYMASTER_OPTS=

# Where log files are stored.  $TAJO_HOME/logs by default.
# export TAJO_LOG_DIR=${TAJO_HOME}/logs

# The directory where pid files are stored. /tmp by default.
# export TAJO_PID_DIR=/var/tajo/pids

# A string representing this instance of tajo. $USER by default.
# export TAJO_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.
# export TAJO_NICENESS=10

# Tajo cluster mode. the default mode is standby mode.
export TAJO_WORKER_STANDBY_MODE=true

# It must be required to use HCatalogStore
# export HIVE_HOME=
# export HIVE_JDBC_DRIVER_DIR=

# Tajo PullServer mode. the default mode is standalone mode
# export TAJO_PULLSERVER_STANDALONE=false