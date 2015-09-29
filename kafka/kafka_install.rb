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

@target_dir = "/home/hadoop/kafka"
@run_dir = "/home/hadoop/kafka"
@log_dir = "/home/hadoop/kafka"
@kafka_version = "0.8.2.1"
KAFKA_CONF = "#{@target_dir}/config/server.properties"

def install_kafka(target_dir, run_dir, log_dir, kafka_version)
  clusterMetaData = getClusterMetaData
  tarball = "kafka_2.9.1-#{kafka_version}.tgz"
  run "wget http://ftp.heanet.ie/mirrors/www.apache.org/dist/kafka/#{kafka_version}/#{tarball} --no-check-certificate"
  run("tar xvf #{tarball}")
  run("mv kafka_2.9.1-#{kafka_version} #{target_dir}")
  run("rm #{tarball}")

  run("sudo perl -pi -e 's/zookeeper.connect=localhost/zookeeper.connect=#{clusterMetaData['masterPrivateDnsName']}/g' #{KAFKA_CONF}")


  if clusterMetaData['isMaster'] == true then
     run("#{target_dir}/bin/zookeeper-server-start.sh #{target_dir}/config/zookeeper.properties &")
     run("#{target_dir}/bin/kafka-server-start.sh #{target_dir}/config/server.properties &")
  else
     randInt=`echo $RANDOM`
     run("sudo perl -pi -e 's/broker.id=0/broker.id=#{randInt}/g' #{KAFKA_CONF}")
     run("#{target_dir}/bin/kafka-server-start.sh #{target_dir}/config/server.properties &")
  end
end

install_kafka(@target_dir, @run_dir, @log_dir, @kafka_version)
