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
@target_dir = "/home/hadoop/logstash/"
@run_dir = "/home/hadoop/logstash/"
@log_dir = "/home/hadoop/logstash/"
@logstash_version = "1.4.2"


def install_logstash(target_dir, run_dir, log_dir, logstash_version)
  tarball = "logstash-#{@logstash_version}.tar.gz"
  run "wget https://download.elasticsearch.org/logstash/logstash/#{tarball} --no-check-certificate"
  # extract to the target directory
  run("mkdir " + target_dir)
  run("tar xvf " + tarball + " -C " + target_dir)

  install_dir = "#{target_dir}logstash-#{logstash_version}/"
#  puts("Starting logstash in the background. Logs found in \'#{log_dir}logstash.log\'")
#  sudo("#{install_dir}bin/logstash &> #{log_dir}/logstash.log &")
end

def clean_up
  run "rm logstash-#{@logstash_version}.tar.gz"
end

if @is_master==true
  install_logstash(@target_dir, @run_dir, @log_dir, @elasticsearch_version)
  clean_up
end
