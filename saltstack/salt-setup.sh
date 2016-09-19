#!/bin/bash -e
# Based on https://github.com/awslabs/emr-bootstrap-actions/tree/master/saltstack
VERSION="20160904"
SELF=$(basename $0 .sh)


print_version() {
  echo $SELF version:$VERSION
}

print_usage() {
  cat << EOF

USAGE: ${0} -mode [-options] [-flags]

 MODES:
  -I (DEFAULT)              Independent mode. EMR Master node is the salt
                            master, slave nodes (task, core) are minions. If
                            no argument is used, this mode will be deployed.

  -E <master-ip>            External master mode. Register all EMR nodes as
                            minions on the external master specified

  -S <master-ip>            Syndicated mode. Like -I but also syndicates EMR
                            master node to the specified external master


 OPTIONS
  -l <loglevel>             See docs.saltstack.com for valid levels. Default:
                            info
  -f <facility>             See man syslog.h for valid facilities. Default:
                            LOG_LOCAL0

 FLAGS
  -d                         Enable debug mode
  -V                         Print version
  -h                         Print usage

EOF
}

write_grain_file() {
  grain_file=/etc/salt/grains
  instanceType=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
  instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

  instanceGroupId=$(jq -r '.instanceGroupId' $infodir/instance.json)
  jobFlowId=$(jq -r '.jobFlowId' $infodir/job-flow.json)
  version=$(grep releaseLabel $infodir/job-flow-state.txt | cut -d '"' -f 2)
  cluster_name=$(aws emr describe-cluster --cluster-id $jobFlowId --output text --query 'Cluster.Name')

  if [[ -z "$version" ]]; then
    version=$(grep amiVersion $infodir/job-flow-state.txt | cut -d '"' -f 2)
    emrType=ami
  else
    version=${version#emr-}
    emrType=bigtop
  fi

  instanceRole=$(jq -r '.instanceGroups[] | select(.instanceGroupId |
                 contains("'$instanceGroupId'")).instanceRole' $infodir/job-flow.json)
  instanceGroupName=$(jq -r '.instanceGroups[] | select(.instanceGroupId |
                      contains("'$instanceGroupId'")).instanceGroupName' $infodir/job-flow.json)
  cat <<EOF | sudo tee $grain_file 1>/dev/null
emr:
  version: $version
  type: $emrType
  job_flow_id: $jobFlowId
  cluster_name: ${cluster_name}
  instance_group_id: $instanceGroupId
  instance_group_name: $instanceGroupName
  instance_role: $instanceRole
instance_id: $instanceId
instance_type: $instanceType
EOF
}

install_configure_master() {
  sudo yum --enablerepo=epel -y install salt-master
  sudo mkdir -p -m750 /etc/salt/master.d

  if [[ -d "/mnt/var" ]]; then
    sudo mkdir -p -m750 /mnt/salt
    sudo chown root:hadoop /mnt/salt
    sudo ln -s /mnt/salt $3
  else
    sudo mkdir -p m770 $3
    sudo chown root:hadoop $3
  fi
  ## Conf file
  cat <<EOF | sudo tee /etc/salt/master.d/aws.conf 1>/dev/null
log_level: $1
log_file: file:///dev/log/$2
auto_accept : True
file_recv: True
file_roots:
  base:
    - $3

nodegroups:
  core: 'G@emr:instance_role:Core'
  master: 'G@emr:instance_role:Master'
  task: 'G@emr:instance_role:Task'
  slave: 'G@emr:instance_role:Core or G@emr:instance_role:Task'
EOF
  sudo service salt-master start
  sudo chkconfig --add salt-master
}

install_configure_syndic() {
  sudo yum --enablerepo=epel -y install salt-syndic
  cat <<EOF | sudo tee -a /etc/salt/master.d/aws.conf 1>/dev/null
syndic_master: $1
EOF
  sudo service salt-syndic start
  sudo chkconfig --add salt-syndic
}

install_configure_minion() {
  local user=$4
  sudo yum --enablerepo=epel -y install salt-minion
  sudo mkdir -p -m750 /etc/salt/minion.d
  sudo chown -R $user /etc/salt
  ## Conf file
# open_mode: True
  cat <<EOF | sudo -u $user tee /etc/salt/minion.d/aws.conf 1>/dev/null
log_level: $1
log_file: file:///dev/log/$2
master: $3
user: $user
EOF
  ## Grains with static EMR info
  write_grain_file
  sudo service salt-minion start
  sudo chkconfig --add salt-minion
}

write_salt-revoke_service() {
  cat <<"EOF" | sudo tee /etc/init.d/salt-revoke 1>/dev/null
#!/bin/bash

### BEGIN INIT INFO
# Provides: saltutil.revoke_auth
# Required-Start: salt-minion
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Revokes minion auth key on shutdown
### END INIT INFO

# Source function library
. /etc/rc.d/init.d/functions

# Default Parameters
RETVAL=0
PROG="salt-revoke"
LOCKFILE="/var/lock/subsys/$PROG"

start() {
  echo -n "Enable $PROG"
  if touch $LOCKFILE > /dev/null 2>&1; then
      success
  else
      RETVAL=1
      failure
  fi
  echo
}

stop() {
  echo -n "Revoking minion auth key"
  if salt-call saltutil.revoke_auth > /dev/null 2>&1; then
      rm -f $LOCKFILE > /dev/null 2>&1
      success
  else
      RETVAL=1
      failure
  fi
  echo
}

case "$1" in
  start)
      start
      ;;
  stop)
      stop
      ;;
  *)
      echo $"Usage: $0 {start|stop}"
      exit 2
esac

exit $RETVAL
EOF
}

# Defaults:
infodir="/mnt/var/lib/info"
facility="LOG_LOCAL0"
loglevel="warn"
basedir=/srv/salt
minion_on_master=1
minionuser="root"
syndic=0
external=0

while getopts ":f:l:E:S:dVIh" optname; do
  case $optname in
    d)  set -x ;;
    f)  facility="$OPTARG" ;;
    l)  loglevel="$OPTARG" ;;
    [eE])  saltmaster="$OPTARG"; external=1 ;;
    [sS])  saltmaster="$OPTARG"; syndic=1 ;;
    [iI])  : ;;
    # Removed for the moment due to
    # https://github.com/saltstack/salt/issues/22055
    # u)  minionuser="$OPTARG" ;;
    h)  print_usage
        exit 0 ;;
    V)  print_version
        exit 0 ;;
    ?)  if [[ "$optname" == ":" ]]; then
          echo "Option ${OPTARG} requires a parameter" 1>&2
        else
          echo "Option ${OPTARG} unkown" 1>&2
        fi
        exit 1;;
  esac
done

if grep -q '"isMaster": true' $infodir/instance.json && (( ! external )); then
  install_configure_master $loglevel $facility $basedir

  if (( syndic )); then
    install_configure_syndic $saltmaster

    ## Deregister on terminate
    write_salt-revoke_service

    sudo chmod +x /etc/init.d/salt-revoke
    sudo chkconfig --add salt-revoke
    sudo service salt-revoke start
  fi
  if (( minion_on_master )); then
    install_configure_minion $loglevel $facility 127.0.0.1 $minionuser
  fi

else
  if (( ! external )); then
    ## Get master hostname
    saltmaster=$(grep masterPrivateDnsName $infodir/job-flow.json | cut -d '"' -f 4)
  fi
  ## Grains with static EMR info
  install_configure_minion $loglevel $facility $saltmaster $minionuser

  ## Deregister on terminate
  write_salt-revoke_service

  sudo chmod +x /etc/init.d/salt-revoke
  sudo chkconfig --add salt-revoke
  sudo service salt-revoke start
fi
