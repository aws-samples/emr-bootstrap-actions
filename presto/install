#!/usr/bin/ruby

#--- Begin Usage-- #
# users would call this to run a bootstrap action on EMR
# these commands are samples.

#---
# elastic-mapreduce --create \
# --name "Presto" \
#--alive \
#--hive-interactive \
#--ami-version 3.1.0 \
#--num-instances 4 \
#--master-instance-type i2.2xlarge \
#--slave-instance-type i2.2xlarge \
#--bootstrap-action s3://presto-bucket/install_presto_0.71.rb \
#--args "-t","1GB","-l","DEBUG","-j","-server \
#-Xmx1G -XX:+UseConcMarkSweepGC \
#-XX:+ExplicitGCInvokesConcurrent \
#-XX:+AggressiveOpts \
#-XX:+HeapDumpOnOutOfMemoryError \
#-XX:OnOutOfMemoryError=kill \
#-9 %p \
#-Dhive.config.resources=/home/hadoop/conf/core-site.xml,/home/hadoop/conf/hdfs-site.xml","-v","0.72","-s","1GB","-a","1h","-p","http://central.maven.org/maven2/com/facebook/presto/" \
# --bootstrap-name "Install Presto"

# then ssh to the master node of the cluster and run the following commands to try out Presto

#Create and set up a test table in hive

# $ hive

## Create Hive table
#DROP TABLE IF EXISTS apachelog;
#CREATE EXTERNAL TABLE apachelog (
#  host STRING,
#  IDENTITY STRING,
#  USER STRING,
#  TIME STRING,
#  request STRING,
#  STATUS STRING,
#  SIZE STRING,
#  referrer STRING,
#  agent STRING 
#)
#PARTITIONED BY(iteration_no int)
#LOCATION 's3://publicprestodemodata/apachelogsample/hive';
 
#ALTER TABLE apachelog RECOVER PARTITIONS;
 
## Test Hive
#select * from apachelog where iteration_no=101 limit 10;
 
## Exit Hive
#exit

##Start Presto and run a test query:

## Set Presto Pager to null for clean display
#export PRESTO_PAGER=
 
# Launch Presto
#./presto --catalog hive
 
## Show tables to prove that Presto is seeing Hive's tables
#show tables;
 
## Run test query in Presto
#select * from apachelog where iteration_no=101 limit 10;
#--- END Usage-- #


require 'json'                                                                                                                                                                                                                       
require 'emr/common'
require 'digest'
require 'optparse'

def println(*args)
  print *args
  puts
end

def run(cmd)
  if ! system(cmd) then
    raise "Command failed: #{cmd}"
  end
end

def sudo(cmd)
  run("sudo #{cmd}")
end

#writeGemRc
def writeGemRc
  println "Writting .gemrc..."
  File.open('/tmp/gemrc','w') do |file_w|
    file_w.write(":ssl_verify_mode: 0")
  end
  sudo "mv /tmp/gemrc /etc/gemrc"
end

#remove .gemrc
def cleanGemRc
  println "cleaning .gemrc"
  sudo "rm -rf /etc/gemrc"
end

writeGemRc
#sudo "gem env"
#run "gem env"
#get the install command to use
def checkInstallCmd
  system("which apt-get")
  check_output = `echo $?`
  if(check_output == 0)
    return "apt-get -y install"
  else
    return "yum -y install"
  end
end

$install_cmd = checkInstallCmd

#install rubygems if it is not already available 
begin
  require "rubygems"
rescue LoadError
  sudo "#{$install_cmd} rubygems"
  Gem.clear_paths
  require "rubygems"
end

#install uuidtools if it is not already available
begin
  require "uuidtools"
rescue LoadError
  sudo "gem install uuidtools"
  Gem.clear_paths
  require "uuidtools"
end
#global variables
job_flow = Emr::JsonInfoFile.new('job-flow')
instance_info = Emr::JsonInfoFile.new('instance')
$is_master = instance_info['isMaster'].to_s == 'true'
$master_private_dns = job_flow['masterPrivateDnsName'].to_s

# bucketName is a token that will be replaced by the s3 artifact deployer by the actual bucket name where this file is uploaded
$bucket_name = "{{bucketName}}"

$presto_s3repo_url="https://s3-us-west-2.amazonaws.com/presto-bucket/"
$presto_run_dir="/mnt/var/run/presto"
$presto_log_dir="/mnt/var/log/presto"
$presto_install_dir="/home/hadoop/.versions"

#parses the configurable options given with the bootstrap action. All are optional
def parseOptions
  configurable_options = {
    :memory => "1GB",
    :log_level => "DEBUG",
    :jvm_conf => "-server -Xmx1G -XX:+UseConcMarkSweepGC -XX:+ExplicitGCInvokesConcurrent -XX:+AggressiveOpts -XX:+HeapDumpOnOutOfMemoryError -XX:OnOutOfMemoryError=kill -9 %p -Dhive.config.resources=/home/hadoop/conf/core-site.xml,/home/hadoop/conf/hdfs-site.xml",
    :sink_max_buffer_memory => "1GB"
  }

  opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage: parse.rb [OPTIONS]"
    opt.on("-t",'--task_memory MEMORY',"Required task memory. Ex : 1GB ") do |memory|
      configurable_options[:memory] = memory
    end

    opt.on("-l",'--log-level LOG_LEVEL',"The log level to use { DEBUG, INFO, WARN, ERROR }") do |log_level|
      configurable_options[:log_level] = log_level
    end

    opt.on("-j",'--jvm-config JVM_CONFIG',"JVM Config") do |jvm_conf|
      configurable_options[:jvm_conf] = jvm_conf
    end

    opt.on("-v",'--version VERSION',"Presto version (Required)") do |version|
      configurable_options[:version] = version
    end

    opt.on("-s",'--sink-buffer-size SINK_BUFFER_SIZE',"Sink Maximum Buffer Size") do |sink_max_buffer_memory|
      configurable_options[:sink_max_buffer_memory] = sink_max_buffer_memory
    end

    opt.on("-a",'--query-max-age QUERY_MAX_AGE',"Query Maximum Age") do |query_max_age|
      configurable_options[:query_max_age] = query_max_age
    end

    opt.on("-m",'--query-max-history QUERY_MAX_HISTORY',"Query Maximum History") do |query_max_hist|
      configurable_options[:query_max_hist] = query_max_hist
    end

    opt.on("-p",'--presto-repo-url PRESTO_REPO_URL',"Presto repo URL (maven repo Ex: http://central.maven.org/maven2/com/facebook/presto/)") do |presto_repo_url|
      configurable_options[:presto_repo_url] = presto_repo_url
    end

    opt.on('-h', '--help', 'Display this message') do
      puts opt
      exit
    end
  end

  opt_parser.parse!
  if configurable_options[:version].nil? then
    println "Presto version is a required argument. Ex : -v [PRESTO_VERSION]"
    exit
  end
  return configurable_options;
end

#write [presto_home]/etc/node.properties
def writeNodeProperties(presto_root)
  println "Writting node properties to  #{$presto_install_dir}/#{presto_root}/etc/node.properties..."
  uuid_str = UUIDTools::UUID.timestamp_create.to_s
  File.open('/tmp/temp_node.properties','w') do |file_w|
    file_w.write("node.environment=production\n")
    file_w.write("node.id=#{uuid_str}\n")
    file_w.write("node.data-dir=#{$presto_log_dir}\n")
  end
  sudo "mv /tmp/temp_node.properties #{$presto_install_dir}/#{presto_root}/etc/node.properties"
end

#write [presto_home]/etc/jvm.config
def writePrestoJVMConfig(jvm_config, presto_root)
  println "Writting jvm config for presto to   #{$presto_install_dir}/#{presto_root}/etc/jvm.config..."
  arr=jvm_config.split(/(\ -[a-zA-Z])/).collect {|x| x.lstrip}

  File.open('/tmp/temp_jvm.config','w') do |file_w|
    file_w.write("#{arr.shift}\n")
    arr_pairs=arr.each_slice(2).to_a
    arr_pairs.each { |x| file_w.write("#{x.join()}\n") }
  end
  sudo "mv /tmp/temp_jvm.config #{$presto_install_dir}/#{presto_root}/etc/jvm.config"
end

#write [presto_home]/etc/config.properties
def writePrestoConfigProperties(configurable_options, presto_root)
  println "Writting config properties for presto to   #{$presto_install_dir}/#{presto_root}/etc/config.properties..."
  File.open('/tmp/temp_config.properties','w') do |file_w|
    if $is_master
      file_w.write("coordinator=true\n")
      file_w.write("datasources=jmx\n")
      file_w.write("discovery-server.enabled=true\n")
    else
      file_w.write("coordinator=false\n")
      file_w.write("datasources=jmx,hive\n")
    end
    file_w.write("task.max-memory=#{configurable_options[:memory]}\n")
    file_w.write("discovery.uri=http://#{$master_private_dns}:8080\n")
    file_w.write("http-server.http.port=8080\n")
    file_w.write("sink.max-buffer-size=#{configurable_options[:sink_max_buffer_memory]}\n")
    unless configurable_options[:query_max_age].nil?
      file_w.write("query.max-age=#{configurable_options[:query_max_age]}\n")
    end
    unless configurable_options[:query_max_hist].nil?
      file_w.write("query.max-history=#{configurable_options[:query_max_hist]}\n")
    end
  end
  sudo "mv /tmp/temp_config.properties #{$presto_install_dir}/#{presto_root}/etc/config.properties"
end

#write [presto_home]/etc/log.properties
def writePrestoLogProperties(log_level, presto_root)
  println "Writting log properties for presto to   #{$presto_install_dir}/#{presto_root}/etc/log.properties..."
  File.open('/tmp/temp_log.properties','w') do |file_w|
    file_w.write("com.facebook.presto=#{log_level}")
  end
  sudo "mv /tmp/temp_log.properties #{$presto_install_dir}/#{presto_root}/etc/log.properties"
end

#write [presto_home]/etc/catalog/jmx.properties
def writeJMXProperties(presto_root)
  println "Writting jmx properties for presto to   #{$presto_install_dir}/#{presto_root}/etc/catalog/jmx.properties..."
  File.open('/tmp/temp_jmx.properties','w') do |file_w|
    file_w.write("connector.name=jmx")
  end
  sudo "mv /tmp/temp_jmx.properties #{$presto_install_dir}/#{presto_root}/etc/catalog/jmx.properties"
end

#write [presto_home]/etc/catalog/hive.properties
def writeHiveProperties(presto_root)
  println "Writting hive properties for presto to   #{$presto_install_dir}/#{presto_root}/etc/catalog/hive.properties..."
  File.open('/tmp/temp_hive.properties','w') do |file_w|
    file_w.write("connector.name=hive-hadoop2\n")
    file_w.write("hive.metastore.uri=thrift://#{$master_private_dns}:10004\n")
  end
  sudo "mv /tmp/temp_hive.properties #{$presto_install_dir}/#{presto_root}/etc/catalog/hive.properties"
end

#make symlinks for hadoop-lzo and presto-server home
def makeSymlinks(presto_version)
  println "Making Symlinks..."
  lzo_file = Dir.glob("/home/hadoop/share/hadoop/common/lib/*hadoop-lzo.jar")[0]
  hives = (`ls /home/hadoop/.versions/presto-server-#{presto_version}/plugin`).split(/\r?\n/).select{|i| i.start_with?("hive")}
  hives.each { |x| sudo "ln -s #{lzo_file} /home/hadoop/.versions/presto-server-#{presto_version}/plugin/#{x}/hadoop-lzo.jar" }
  sudo "ln -s /home/hadoop/.versions/presto-server-#{presto_version}/ /home/hadoop/presto-server"
end

#installs presto-cli
def installPrestoCli(presto_repo_url, presto_version)
  presto_cli_jar="presto-cli-#{presto_version}-executable.jar"
  println "Downloading presto-cli-#{presto_version}-executable.jar from #{presto_repo_url}"
  sudo "curl -L --silent --show-error --fail --connect-timeout 60 --max-time 720 --retry 5 -O  #{presto_repo_url+"presto-cli/"+"#{presto_version}/"+presto_cli_jar}"
  sudo "mv presto-cli-#{presto_version}-executable.jar /home/hadoop/presto"
  sudo "chmod +x  /home/hadoop/presto"
end

#starts presto installation
def installPresto
  configurable_options=parseOptions
  presto_version=configurable_options[:version]
  presto_root="presto-server-#{presto_version}"
  sudo "rm -rf #{$presto_install_dir}/presto-server*"
  sudo "rm -rf #{$presto_log_dir}"
  sudo "rm -rf #{$presto_run_dir}"
  sudo "rm -rf  /mnt/var/presto"
  sudo "mkdir -p #{$presto_run_dir}"
  presto_server_targz="presto-server-#{configurable_options[:version]}.tar.gz"
  if configurable_options[:presto_repo_url].nil? then
    presto_repo_url=$presto_s3repo_url
  else
    presto_repo_url=configurable_options[:presto_repo_url]
  end
  println "Downloading presto-server-#{presto_version}.tar.gz from #{presto_repo_url}"
  sudo "curl -L --silent --show-error --fail --connect-timeout 60 --max-time 720 --retry 5 -O  #{presto_repo_url+"presto-server/"+"#{configurable_options[:version]}/"+presto_server_targz}"
  println "Installing Presto..."
  sudo "tar xzf #{presto_server_targz} && rm -f #{presto_server_targz}"
  sudo "mv #{presto_root} #{$presto_install_dir}"
  etcDir="#{$presto_install_dir}/#{presto_root}/etc"
  println "Making #{etcDir}"
  sudo "mkdir #{etcDir}"
  println "Making #{etcDir}/catalog"
  sudo "mkdir #{etcDir}/catalog"
  sudo "mkdir /mnt/var/presto"
  println "Making metastore for Presto at /mnt/var/presto/db/metastore"
  sudo "mkdir /mnt/var/presto/db"
  sudo "touch /mnt/var/presto/db/metastore"
  println "Making node data dir for Presto at #{$presto_log_dir}"
  sudo "mkdir #{$presto_log_dir}"
  writeNodeProperties(presto_root)
  writePrestoJVMConfig(configurable_options[:jvm_conf],presto_root)
  writePrestoConfigProperties(configurable_options,presto_root)
  writePrestoLogProperties(configurable_options[:log_level],presto_root)

  writeJMXProperties(presto_root)
  writeHiveProperties(presto_root)

  installPrestoCli(presto_repo_url, presto_version)
  makeSymlinks(presto_version)
end

#write /etc/init.d/presto-launcher & /etc/service-nanny/presto.conf for service-nanny to monitor
def writePrestoFilesForServiceNanny
  println "Making /etc/init.d/presto-launcher"
  File.open('/tmp/presto-launcher', 'w') do |f|
    f.write(<<EOF
/home/hadoop/presto-server/bin/launcher $@
EOF
           )
  end
  sudo "mv /tmp/presto-launcher /etc/init.d/presto-launcher && chmod a+x /etc/init.d/presto-launcher"

  println "Making /etc/service-nanny/presto.conf"
  File.open('/tmp/presto.conf', 'w') do |f|
    f.write(<<EOF
[

{
  "name": "run-presto",
  "type": "file",
  "file": "#{$presto_run_dir}/run-presto",
  "pattern": "1"
},

{
  "name": "presto-server",
  "type": "process",
  "start": "/etc/init.d/presto-launcher start",
  "stop": "/etc/init.d/presto-launcher stop",
  "pid-file": "#{$presto_run_dir}/presto-server.pid",
  "pattern": "launcher",
  "depends": ["run-presto"]
}
]
EOF
           )
  end
  sudo "mv /tmp/presto.conf /etc/service-nanny/presto.conf"
  sudo "echo '1' >/tmp/run-presto"
  sudo "mv /tmp/run-presto /mnt/var/run/presto/run-presto"
  sudo "chmod +x /etc/service-nanny/presto.conf"
end

#update /etc/instance-controller/logs.json for uploading presto logs to s3
def s3LogJsonUpdate
  logs_json_path = "/etc/instance-controller/logs.json"
  println "Updating #{logs_json_path}"
  json_obj=JSON.parse(File.read("#{logs_json_path}"));
  sections = json_obj["logFileTypes"]
  sections.each { |section|
    if section['typeName'] == 'USER_LOG' then
      user_log = section['logFilePatterns']
      user_log << {
                        "fileGlob" => "/mnt/var/presto/log/var/log/(.*)",
                        "s3Path" => "node/$instance-id/presto-logs/$0",
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

def reloadServiceNanny
  println "restart service-nanny"
  if File.exists?('/mnt/var/run/service-nanny/service-nanny.pid')
    sudo '/etc/init.d/service-nanny restart'
  else
    sudo '/etc/init.d/service-nanny start'
  end
end

installPresto
writePrestoFilesForServiceNanny
s3LogJsonUpdate
reloadServiceNanny
cleanGemRc
