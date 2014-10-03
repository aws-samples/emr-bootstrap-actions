#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'emr/common'
require 'rexml/document'

def run(cmd)
  raise "Command failed: #{cmd}" unless system(cmd)
end

def sudo(cmd)
  run("sudo #{cmd}")
end

@is_master = Emr::JsonInfoFile.new('instance')['isMaster'].to_s == 'true'
@cluster_name = Emr::JsonInfoFile.new('job-flow')['jobFlowId'].to_s
sudo("cp /mnt/var/lib/instance-controller/extraInstanceData.json" +
     " /mnt/var/lib/info/extraInstanceData.json")
@region = Emr::JsonInfoFile.new('extraInstanceData')['region'].to_s
@target_dir = "/home/hadoop/elasticsearch/"
@run_dir = "/home/hadoop/elasticsearch/"
# this is where additional logs are sent in case terminal output needs to be caught
@log_dir = "/home/hadoop/elasticsearch/"
@elasticsearch_version = "1.3.1"
@elasticsearch_port_num = 9030

def load_aws_keys
  core_sites = REXML::Document.new(File.new("/home/hadoop/conf/core-site.xml"))
  root = core_sites.root
  access_key = secret_key = ""
  root.each_recursive do |node|
    if node.get_text == "fs.s3n.awsSecretAccessKey"
      secret_key = node.next_sibling_node().get_text
    end
    if node.get_text == "fs.s3n.awsAccessKeyId"
      access_key = node.next_sibling_node().get_text
    end
  end
  if access_key == "" && secret_key == ""
    raise "Valid AWS access credentials not found in configuration file."
  end
  return access_key, secret_key
end

def install_elasticsearch(target_dir, run_dir, log_dir, elasticsearch_version)
  access_key, secret_key = load_aws_keys()
  tarball = "elasticsearch-#{elasticsearch_version}.tar.gz"
  run "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/#{tarball} --no-check-certificate"
  # extract to the target directory
  run("mkdir " + target_dir)
  run("tar xvf " + tarball + " -C " + target_dir)
  File.open("elasticsearch.yml", "w") do |config|
    config.puts("http.port: #{@elasticsearch_port_num}")
    config.puts("node.master: #{@is_master}")
    config.puts("node.data: true")
    config.puts("cluster.name: #{@cluster_name}")
    config.puts("discovery.type: ec2")
    config.puts("cloud.aws.access_key: #{access_key}")
    config.puts("cloud.aws.secret_key: #{secret_key}")
    config.puts("cloud.aws.region: #{@region}")
  end

  install_dir = "#{target_dir}elasticsearch-#{elasticsearch_version}/"
  # installing elasticsearch aws plugin
  run("#{install_dir}bin/plugin -install elasticsearch/elasticsearch-cloud-aws/2.2.0")
  # replace yaml with new config file
  run("mv elasticsearch.yml #{install_dir}config/elasticsearch.yml")
  puts("Starting elasticsearch in the background. Logs found in \'#{log_dir}elasticsearch.log\'")
  sudo("#{install_dir}bin/elasticsearch &> #{log_dir}/elasticsearch.log &")
end

def install_hadoop_plugin(target_dir, run_dir)
  run("wget https://download.elasticsearch.org/hadoop/elasticsearch-hadoop-2.0.1.zip --no-check-certificate")
  run("mv elasticsearch-hadoop-2.0.1.zip #{target_dir}")
  run("unzip #{target_dir}elasticsearch-hadoop-2.0.1.zip -d #{target_dir}")
  run("echo export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:#{@target_dir}elasticsearch-hadoop-2.0.1/dist/* >> ~/.bashrc")
end

def clean_up
  run "rm -Rf #{@target_dir}elasticsearch-hadoop-2.0.0.zip"
  run "rm elasticsearch-#{@elasticsearch_version}.tar.gz"
end

install_elasticsearch(@target_dir, @run_dir, @log_dir, @elasticsearch_version)
install_hadoop_plugin(@target_dir, @run_dir)
clean_up
