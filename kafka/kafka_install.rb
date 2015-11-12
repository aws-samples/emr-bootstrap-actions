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
def s3LogJsonUpdate(kafka_log_dir)
  println "kafka log dir : #{kafka_log_dir}"
  logs_json_path = "/etc/instance-controller/logs.json"
  println "Updating #{logs_json_path}"
  json_obj=JSON.parse(File.read("#{logs_json_path}"));
  sections = json_obj["logFileTypes"]
  sections.each { |section|
    if section['typeName'] == 'SYSTEM_LOG' then
      user_log = section['logFilePatterns']
      user_log << {
          "fileGlob" => "#{kafka_log_dir}/var/log/(.*)",
          "s3Path" => "node/$instance-id/apps/kafka/$0",
          "delayPush" => "true"
      }
      break
    end
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
@kafka_version = "0.8.2.1"
KAFKA_CONF = "#{@target_dir}/config/server.properties"

def install_kafka(target_dir, run_dir, log_dir, kafka_version)
  clusterMetaData = getClusterMetaData
  tarball = "kafka_2.9.1-#{kafka_version}.tgz"
  run "wget http://ftp.heanet.ie/mirrors/www.apache.org/dist/kafka/#{kafka_version}/#{tarball}"
  run("tar xvf #{tarball}")
  run("mv kafka_2.9.1-#{kafka_version} #{target_dir}")
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

  if clusterMetaData['isMaster'] == true then
     run("#{target_dir}/bin/zookeeper-server-start.sh #{target_dir}/config/zookeeper.properties &")
     run("#{target_dir}/bin/kafka-server-start.sh #{target_dir}/config/server.properties &")
  else
     randInt=`echo $RANDOM`
     run("sudo perl -pi -e 's/broker.id=0/broker.id=#{randInt}/g' #{KAFKA_CONF}")
     run("#{target_dir}/bin/kafka-server-start.sh #{target_dir}/config/server.properties &")
  end
  
  s3LogJsonUpdate(log_dir)
end

install_kafka(@target_dir, @run_dir, @log_dir, @kafka_version)
