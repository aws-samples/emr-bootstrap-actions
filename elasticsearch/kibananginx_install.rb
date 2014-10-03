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
@kibana_version = "3.1.0"
@target_dir = "/etc/nginx/"
@nginx_dir = "/etc/nginx/"
@es_port_num = 9030

def install_kibana(target_dir, kibana_version)
  tarball = "kibana-#{kibana_version}.tar.gz"
  run("wget https://download.elasticsearch.org/kibana/kibana/#{tarball} --no-check-certificate")
  # extract to the target directory
  sudo("mkdir " + target_dir)
  sudo("tar xvf " + tarball + " -C " + target_dir)
  install_dir = "#{target_dir}kibana-#{kibana_version}/"

  # replace config.js with new config file
  hostname = `hostname -f`
  hostname.gsub!("\n", "")
  kibana_config_js(hostname)
  sudo("mv config.js #{install_dir}config.js")
  install_nginx()
  sudo("chown hadoop.hadoop #{install_dir}")
end

# returns the kibana config file
def kibana_config_js(hostname)
  port_num = @es_port_num
  File.open("config.js", "w") do |config|
    config.puts("define([\'settings\'],")
    config.puts("function (settings) {")
    config.puts("  return new settings({")
    config.puts("    elasticsearch: \"http://#{hostname}:#{port_num}\",") 
    config.puts("    default_route: \'/dashboard/file/default.json',")
    config.puts("    kibana_index: \"kibana-int\",")
    config.puts("    panel_names: [\'histogram\', \'map\', \'goal\', \'table\', \'timepicker\'," +
                " \'text\', \'hits\', \'column\', \'trends\', \'bettermap\', \'query\', " +
                "'terms\', \'stats\', \'sparklines\']")
    config.puts("  });")
    config.puts("});")
  end
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
    config.puts("    root /etc/nginx/kibana-#{@kibana_version};")
    config.puts("    location / {")
    config.puts("    }")
    config.puts("    error_page 404 /404.html;")
    config.puts("    location = /40x.html {")
    config.puts("    }")
    config.puts("    error_page 500 502 503 504 /50x.html;")
    config.puts("    location = /50x.html {")
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
  install_kibana(@target_dir, @kibana_version)
  run("sudo service nginx start")
end
