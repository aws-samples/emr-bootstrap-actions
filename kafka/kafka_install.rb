#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'rexml/document'
require 'net/http'
require 'open-uri'

def run(cmd)
  raise "Command failed: #{cmd}" unless system(cmd)
end

def sudo(cmd)
  run("sudo #{cmd}")
end

def println(*args)
  print *args
  puts
end

def getClusterMetaData
  metaData = {}
  jobFlow = JSON.parse(File.read('/mnt/var/lib/info/job-flow.json'))
  userData = JSON.parse(Net::HTTP.get(URI('http://169.254.169.254/latest/user-data/')))
  #Determine if Instance Has IAM Roles
  req = Net::HTTP.get_response(URI('http://169.254.169.254/latest/meta-data/iam/security-credentials/'))
  metaData['roles'] = (req.code.to_i == 200) ? true : false
  metaData['instanceId'] = Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/instance-id/'))
  metaData['instanceType'] = Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/instance-type/'))
  metaData['ip'] = Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/local-ipv4/'))
  metaData['region'] =  Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/placement/availability-zone'))
  metaData['region'] =  metaData['region'][0...-1]
  metaData['masterPrivateDnsName'] = jobFlow['masterPrivateDnsName']
  metaData['cluster_Name'] = jobFlow['jobFlowId']
  metaData['isMaster'] = userData['isMaster']

  return metaData

end

#update /etc/instance-controller/logs.json for uploading kafka logs to s3
def s3LogJsonUpdate(target_dir, kafka_log_dir)
  println "kafka log dir : #{kafka_log_dir}"
  logs_json_path = "/etc/logpusher/kafka.config"
  println "Updating #{logs_json_path}"
  json_obj = {"#{kafka_log_dir}" => {
                "includes" =>  [ "(.*)" ],
                "s3Path" => "node/$instance-id/applications/kafka/$0",
                "retentionPeriod" => "2d",
                "logType" => [ "USER_LOG", "SYSTEM_LOG" ]
              },
              "#{target_dir}/logs" => {
                "includes" =>  [ "(.*)" ],
                "s3Path" => "node/$instance-id/applications/kafka_logs/$0",
                "retentionPeriod" => "2d",
                "logType" => [ "USER_LOG", "SYSTEM_LOG" ]
              }
             }
  new_json=JSON.pretty_generate(json_obj)
  File.open('/tmp/logs.json','w') do |file_w|
    file_w.write("#{new_json}")
  end
  sudo "mv /tmp/logs.json #{logs_json_path}"
end


@target_dir = "/home/hadoop/kafka"
@run_dir = "/mnt/var/run/kafka"
@log_dir = "/mnt/var/log/kafka"
@kafka_version = "0.10.1.0"
@scala_version = "2.11"
KAFKA_CONF = "#{@target_dir}/config/server.properties"

def create_and_link_script(kafka_script)
  tmp_script='/tmp/kafka_script.tmp'
  File.open(tmp_script,'w') do |file_w|
    file_w.write("#{kafka_script}")
  end
  sudo "mv #{tmp_script} /etc/rc.d/init.d/kafka"
  sudo "chmod u+x /etc/rc.d/init.d/kafka"
  sudo "ln -s /etc/rc.d/init.d/kafka /etc/rc.d/rc3.d/S99kafka"
end

def install_kafka(target_dir, run_dir, log_dir, kafka_version, scala_version, kafka_script)
  clusterMetaData = getClusterMetaData
  tarball = "kafka_#{scala_version}-#{kafka_version}.tgz"
  run "wget http://ftp.heanet.ie/mirrors/www.apache.org/dist/kafka/#{kafka_version}/#{tarball}"
  run("tar xvf #{tarball}")
  run("mv kafka_#{scala_version}-#{kafka_version} #{target_dir}")
  run("rm #{tarball}")
  # setting zookeeper node fqdn
  run("sudo perl -pi -e 's/zookeeper.connect=localhost/zookeeper.connect=#{clusterMetaData['masterPrivateDnsName']}/g' #{KAFKA_CONF}")
  # setting log dir
  run("sudo perl -pi -e 's/log.dirs=/#log.dirs=/g' #{KAFKA_CONF}")
  run("echo \"log.dirs=\"#{log_dir} >>  #{KAFKA_CONF}")
  # setting run properties
  sudo "rm -rf #{run_dir}"
  println "making #{run_dir}"
  sudo "mkdir -p #{run_dir}"

  if clusterMetaData['isMaster'] == false then
    randInt=`echo $RANDOM`
    run("sudo perl -pi -e 's/broker.id=0/broker.id=#{randInt}/g' #{KAFKA_CONF}")
    run("echo 'broker.id.generation.enable=false' >> #{KAFKA_CONF}")
  end

  create_and_link_script(kafka_script)
  s3LogJsonUpdate(target_dir,log_dir)
end

@kafka_script = '#!/bin/sh
#
# chkconfig: 345 99 01
# description: Kafka
#
# File : Kafka
#
# Description: Starts and stops the Kafka server
#

source /etc/rc.d/init.d/functions

KAFKA_HOME=/home/hadoop/kafka
KAFKA_USER=hadoop
export LOG_DIR=$KAFKA_HOME/logs

[ -e /etc/sysconfig/kafka ] && . /etc/sysconfig/kafka

# See how we were called.
case "$1" in

  start)
    echo -n "Starting Kafka:"
    /sbin/runuser -s /bin/sh $KAFKA_USER -c "nohup $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > $LOG_DIR/server.out 2> $LOG_DIR/server.err &"
    echo " done."
    exit 0
    ;;

  stop)
    echo -n "Stopping Kafka: "
    /sbin/runuser -s /bin/sh $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk \'{print \$2}\' | xargs kill"
    echo " done."
    exit 0
    ;;
  hardstop)
    echo -n "Stopping (hard) Kafka: "
    /sbin/runuser -s /bin/sh $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk \'{print \$2}\' | xargs kill -9"
    echo " done."
    exit 0
    ;;

  status)
    c_pid=`ps -ef | grep kafka.Kafka | grep -v grep | awk \'{print $2}\'`
    if [ "$c_pid" = "" ] ; then
      echo "Stopped"
      exit 3
    else
      echo "Running $c_pid"
      exit 0
    fi
    ;;

  restart)
    stop
    start
    ;;

  *)
    echo "Usage: kafka {start|stop|hardstop|status|restart}"
    exit 1
    ;;

esac'

install_kafka(@target_dir, @run_dir, @log_dir, @kafka_version, @scala_version, @kafka_script)
