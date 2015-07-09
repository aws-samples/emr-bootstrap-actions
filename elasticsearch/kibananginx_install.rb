#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'emr/common'

def run(cmd)
  raise "Command failed: #{cmd}" unless system(cmd)
end

def sudo(cmd)
  run("sudo #{cmd}")
end

@is_master = Emr::JsonInfoFile.new('instance')['isMaster'].to_s == 'true'
@kibana_version = "4.1.1-linux-x64"
@target_dir = "/home/hadoop/kibana/"
@nginx_dir = "/etc/nginx/"
@es_port_num = 9200

def install_pleaserun
  sudo("gem2.0 install pleaserun")
end

def install_kibana(target_dir, kibana_version)
  tarball = "kibana-#{kibana_version}.tar.gz"
  run("wget https://download.elasticsearch.org/kibana/kibana/#{tarball} --no-check-certificate")
  # extract to the target directory
  sudo("mkdir " + target_dir)
  sudo("tar xvf " + tarball + " -C " + target_dir)
  install_dir = "#{target_dir}kibana-#{kibana_version}/"

  sudo("/usr/local/bin/pleaserun --install -p sysv -v lsb-3.1 #{install_dir}/bin/kibana")

  sudo("chown hadoop.hadoop #{install_dir}")
end

def install_nginx()
  # installs the most recent version of nginx. May need to change this in the
  # future but Kibana isn't terribly demanding it seems
  # this only supports newer AMIs (3.1.0 running Amazon Linux)
  sudo('yum -y install nginx')
  File.open("nginx.conf", "w") do |config|
    config.puts("user nginx;")
    config.puts("worker_processes 1;")
    config.puts("error_log /var/log/nginx/error.log;")
    config.puts("pid /var/run/nginx.pid;")
    config.puts("events {")
    config.puts("  worker_connections 1024;")
    config.puts("}")
    config.puts("http {")
    config.puts("  include /etc/nginx/mime.types;")
    config.puts("  default_type application/octet-stream;")
    config.puts("  log_format main '$remote_addr - $remote_user [$time_local] \"$request\" '")
    config.puts("                  '$status $body_bytes_sent \"$http_referer\" '")
    config.puts("                  '\"$http_user_agent\" \"$http_x_forwarded_for\"';")
    config.puts("  access_log /var/log/nginx/access.log main;")
    config.puts("  sendfile on;")
    config.puts("  keepalive_timeout 65;")
    config.puts("  include /etc/nginx/conf.d/*.conf;")
    config.puts("  index index.html index.htm;")
    config.puts("  server {")
    config.puts("    listen 80;")
    config.puts("    server_name localhost;")
    config.puts("    location / {")
    config.puts("        proxy_pass http://localhost:5601;")
    config.puts("    }")
    config.puts("  }")
    config.puts("}")
  end
  sudo("mv nginx.conf #{@nginx_dir}nginx.conf")
end

def clean_up
  run("rm kibana-#{@kibana_version}.tar.gz")
end

if @is_master
  install_pleaserun
  install_kibana(@target_dir, @kibana_version)
  install_nginx

  sudo("service kibana start")
  sudo("service nginx start")
end
