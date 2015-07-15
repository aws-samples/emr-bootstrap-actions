#!/usr/bin/ruby
require 'emr/common'
require 'digest'
require 'optparse'

def run(cmd)
  if ! system(cmd) then
    raise "Command failed: #{cmd}"
  end
end

def sudo(cmd)
  run("sudo #{cmd}")
end

def println(*args)
  print *args
  puts
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

begin
  require "uuidtools"
rescue LoadError
  sudo "gem install uuidtools"
  Gem.clear_paths
  require "uuidtools"
end

begin
  require "xmlsimple"
rescue LoadError
  sudo "gem install xml-simple"
  Gem.clear_paths
  require "xmlsimple"
end

job_flow = Emr::JsonInfoFile.new('job-flow')
instance_info = Emr::JsonInfoFile.new('instance')
$is_master = instance_info['isMaster'].to_s == 'true'
$master_private_dns = job_flow['masterPrivateDnsName'].to_s
$presto_install_dir="/home/hadoop/.versions"
$presto_run_dir="/mnt/var/run/presto"
$hive_version=Dir["/home/hadoop/.versions/hive*"].to_s.split('/')[-1].gsub(/[\[\]\"]/,'').split('-')[1]

class PrestoConfig
  @@s3_presto_default_config = "s3://support.elasticmapreduce/bootstrap-actions/presto/default_presto_config.json"
  @@special_properties = ["coordinator", "discovery.uri", "node.id", "http-server.http.port"]
  def initialize(is_master, master_dns, s3_path_to_config, hive_metastore_port)
    @@is_master = is_master
    @@master_dns = master_dns
    @@s3_path_to_config = s3_path_to_config
    @@hive_metastore_port = hive_metastore_port
  end

  def readConfig(jsonfilePath)
    println "reading config : #{jsonfilePath}"
    run "rm -rf /tmp/presto-config.json"
    run "hdfs dfs -copyToLocal #{jsonfilePath} /tmp/presto-config.json"
    presto_config_file = File.read("/tmp/presto-config.json")
    data_hash = JSON.parse(presto_config_file)
    return data_hash
  end

  def getOverrideObj(user_obj, default_obj)
    default_obj.each do |key, array|
      if !user_obj.has_key? "#{key}"
        user_obj["#{key}"] = array
      end
    end
  end

  def removeSpecialProperties(user_obj)
    @@special_properties.each do |val|
      if user_obj.has_key? "#{val}"
        user_obj.delete("#{val}")
      end
    end
  end

  def overrideUserConfig
    @@default_data.each do |key, array|
      if @@final_data.has_key? "#{key}"
        removeSpecialProperties(@@final_data["#{key}"])
        getOverrideObj(@@final_data["#{key}"], @@default_data["#{key}"])

      else
        #this file entry does not exist in user config
        @@final_data["#{key}"] = array
      end
    end
  end

  def updateSpecialProperties
    node_prop = @@final_data["etc/node.properties"]
    uuid_str = UUIDTools::UUID.timestamp_create.to_s
    node_prop["node.id"] = uuid_str

    config_properties = @@final_data["etc/config.properties"]
    config_properties["coordinator"] = "#{@@is_master}"
    #config_properties["discovery-server.enabled"] = "#{$is_master}"
    #config_properties["discovery-server.enabled"] = "true"

    config_properties["http-server.http.port"] = "8080"
    config_properties["discovery.uri"] = "http://#{@@master_dns}:8080"
    hive_prop = @@final_data["etc/catalog/hive.properties"]
    hive_prop["hive.metastore.uri"] = "thrift://#{@@master_dns}:#{@@hive_metastore_port}"
  end

  def dumpFiles
    run "mkdir -p /home/hadoop/presto-server/etc"
    run "mkdir -p /home/hadoop/presto-server/etc/catalog"
    #$user_data.map {|k,v| "#{k}=#{v}"}.join('\n')
    @@final_data.each do |key, val|
      if !key.include? "jvm.config"
        f = File.open("/home/hadoop/presto-server/#{key}", 'w')
        val.each do |k, v|
          f.puts "#{k}=#{v}"
        end
      end
    end

    File.open("/home/hadoop/presto-server/etc/jvm.config", 'w') do |f|
      f.puts @@final_data["etc/jvm.config"]["jvm.options"].join("\n")
    end
  end

#update /etc/instance-controller/logs.json for uploading presto logs to s3
  def s3LogJsonUpdate(presto_log_dir)
    println "presto log dir : #{presto_log_dir}"
    logs_json_path = "/etc/instance-controller/logs.json"
    println "Updating #{logs_json_path}"
    json_obj=JSON.parse(File.read("#{logs_json_path}"));
    sections = json_obj["logFileTypes"]
    sections.each { |section|
      if section['typeName'] == 'SYSTEM_LOG' then
        user_log = section['logFilePatterns']
        user_log << {
            "fileGlob" => "#{presto_log_dir}/var/log/(.*)",
            "s3Path" => "node/$instance-id/apps/presto/$0",
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

  def writeConfigs
    println "s3 presto config : #{@@s3_presto_default_config}"
    @@default_data = readConfig(@@s3_presto_default_config)
    if !@@s3_path_to_config.nil?
      @@final_data = readConfig(@@s3_path_to_config)
      overrideUserConfig
    else
      @@final_data = @@default_data
    end
    updateSpecialProperties
    if !@@final_data["etc/node.properties"]["node.data-dir"].nil?
      presto_log_dir = @@final_data["etc/node.properties"]["node.data-dir"].sub(/(\/)+$/,'')
      s3LogJsonUpdate(presto_log_dir)
    end
    return @@final_data
  end
end


#parses the configurable options given with the bootstrap action. All are optional
def parseOptions
  configurable_options = {
      :s3_path_to_presto_server_bin => "s3://support.elasticmapreduce/bootstrap-actions/presto/presto-server-0.78.tar.gz",
      :s3_path_to_presto_cli => "s3://support.elasticmapreduce/bootstrap-actions/presto/presto-cli-0.78-executable.jar",
      :hive_metastore_port => "9083"
  }

  opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage: install_presto [OPTIONS]"

    opt.on("-s",'--s3-path-to-presto-server-bin [S3_PATH_TO_PRESTO_SERVER_BIN]',
           "Ex : s3://path/to/bin/presto-server-[version_number].tar.gz") do |s3_path_to_presto_server_bin|
      configurable_options[:s3_path_to_presto_server_bin] = s3_path_to_presto_server_bin
    end

    opt.on("-c",'--s3-path-to-presto-cli [S3_PATH_TO_PRESTO_CLI]',
           "Ex : s3://path/to/bin/presto-cli-executible-[version_number].jar") do |s3_path_to_presto_cli|
      configurable_options[:s3_path_to_presto_cli] = s3_path_to_presto_cli
    end

    opt.on("-m",'--s3-path-to-master-config [S3_PATH_TO_MASTER_CONFIG]',
           "Ex : s3://path/to/config/dir/master.config )") do |s3_path_to_master_config|
      configurable_options[:s3_path_to_master_config] = s3_path_to_master_config
    end

    opt.on("-w",'--s3-path-to-worker-config [S3_PATH_TO_WORKER_CONFIG]',
           " EX : s3://path/to/config/dir/worker.config)") do |s3_path_to_worker_config|
      configurable_options[:s3_path_to_worker_config] = s3_path_to_worker_config
    end

    opt.on("-p",'--hive-metastore-port [HIVE_METASTORE_PORT]',
           " Defaults to 9083)") do |hive_metastore_port|
      configurable_options[:hive_metastore_port] = hive_metastore_port
    end

    opt.on('-h', '--help', 'Display this message') do
      puts opt
      exit
    end
  end

  opt_parser.parse!
  return configurable_options;
end

def makeSymlinks(presto_server_path)
  println "Making Symlinks..."
  lzo_file = Dir.glob("/home/hadoop/share/hadoop/common/lib/*hadoop-lzo.jar")[0]
  hives = (`ls #{presto_server_path}/plugin`).split(/\r?\n/).select{|i| i.start_with?("hive")}
  hives.each { |x| run "ln -s #{lzo_file} #{presto_server_path}/plugin/#{x}/hadoop-lzo.jar" }
  run "ln -s #{presto_server_path} /home/hadoop/presto-server"
end

def addMetaStoreToHiveInit(metastore_port)
  if $is_master
    if Gem::Version.new($hive_version) >= Gem::Version.new('0.13.0')
      cmd = "/home/hadoop/hive/bin/hive --service metastore -p #{metastore_port} >> /mnt/var/log/apps/hive-metastore.log &"

    elsif Gem::Version.new($hive_version) >= Gem::Version.new('0.11.0')
      cmd = "sh \"/home/hadoop/hive/bin/hive --service metastore -p #{metastore_port} >> /mnt/var/log/apps/hive-metastore.log &\""
    end
    if File.exist? "/home/hadoop/hive/bin/hive-init"
      File.open('/home/hadoop/hive/bin/hive-init', 'a') { |f|
        f.write("\n#{cmd}\n")
      }
    end
  end
end

def prepareHiveForRemoteMetatore(metastore_port)
  default_data = XmlSimple.xml_in(File.open("/home/hadoop/hive/conf/hive-default.xml", "rb").read)
  metastore_local = {
      "name" => ["hive.metastore.local"],
      "value" => ["false"]
  }
  metastore_uri = {
      "name" => ["hive.metastore.uris"],
      "value" => ["thrift://localhost:#{metastore_port}"]
  }
  default_data["property"].push(metastore_local,metastore_uri)
  XmlSimple.xml_out(default_data, {"outputfile" => "/home/hadoop/hive/conf/hive-default.xml", "RootName" => "configuration"})
end

def prepareHive(configurable_options)

  if $is_master
    if Gem::Version.new($hive_version) >= Gem::Version.new('0.13.0')
      if File.exist? "/home/hadoop/hive/bin/mysqld-hiveserver-setup.sh"
        println "mysqld-hiveserver-setup.sh exists therefore run hive-init"
        #correctMySqlScript
        # we dont have to run hive-init in later ami's, therefore, else would be triggerred in ami > 3.2.3 or 3.3.0
        run "sh /home/hadoop/hive/bin/hive-init"
      else
        run "sh /home/hadoop/hive/bin/hive-set-up.sh create_log_dirs"
        run "sh /home/hadoop/hive/bin/hive-set-up.sh setup_mysql"
        run "sh /home/hadoop/hive/bin/hive-set-up.sh setup_hive_server"
        run "sh /home/hadoop/hive/bin/init-hive-dfs.sh &"
      end
    end
    println "metastore : #{configurable_options[:hive_metastore_port]}"
    if  configurable_options[:hive_metastore_port].nil?
      run "/home/hadoop/hive/bin/hive --service metastore  >> /mnt/var/log/apps/hive-metastore.log &"
    else
      println "metastore port used #{configurable_options[:hive_metastore_port]}"
      run "/home/hadoop/hive/bin/hive --service metastore -p #{configurable_options[:hive_metastore_port]} >> /mnt/var/log/apps/hive-metastore.log &"
    end
  end
end

#starts presto installation
def installPresto
  println "cleaning previous presto installation if any"
  sudo "rm -rf #{$presto_install_dir}/presto-server*"
  configurable_options=parseOptions

  #remove trailing '/'
  s3_path_to_presto_server_bin="#{configurable_options[:s3_path_to_presto_server_bin]}".sub(/(\/)+$/,'')
  println "copyToLocal from #{s3_path_to_presto_server_bin}"
  run "hdfs dfs -copyToLocal #{s3_path_to_presto_server_bin} /tmp/presto-server.tar.gz"
  run "tar zxf /tmp/presto-server.tar.gz -C #{$presto_install_dir}/"
  presto_server_path=Dir.glob('/home/hadoop/.versions/presto-server*')[0]
  makeSymlinks(presto_server_path)
  sudo "rm -rf #{$presto_run_dir}"
  println "making #{$presto_run_dir}"
  sudo "mkdir -p #{$presto_run_dir}"

  #install Presto Cli
  if $is_master==true
    s3_path_to_presto_cli="#{configurable_options[:s3_path_to_presto_cli]}".sub(/(\/)+$/,'')
    println "install cli, copyToLocal from #{s3_path_to_presto_cli}"
    run "hdfs dfs -copyToLocal #{s3_path_to_presto_cli} /tmp/presto-cli-executible.jar"
    run "mv /tmp/presto-cli-executible.jar /home/hadoop/presto"
    sudo "chmod +x  /home/hadoop/presto"
  end
  writeConfigs(configurable_options)
  prepareHiveForRemoteMetatore(configurable_options[:hive_metastore_port])
  addMetaStoreToHiveInit(configurable_options[:hive_metastore_port])
  writePrestoFilesForServiceNanny
  reloadServiceNanny
end

def writeConfigs(configurable_options)
  s3_path_to_config = $is_master ? configurable_options[:s3_path_to_master_config] :
      configurable_options[:s3_path_to_worker_config]
  presto_config = PrestoConfig.new($is_master, $master_private_dns, s3_path_to_config,
                                   configurable_options[:hive_metastore_port])
  $final_config_data=presto_config.writeConfigs
  println "********Config Data**********\n : #{$final_config_data}"
  presto_config.dumpFiles
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
    "name": "run-presto-server",
    "type": "file",
    "file": "#{$presto_run_dir}/run-presto-server",
    "pattern": "1"
  },

  {
    "name": "presto-server",
    "type": "process",
    "start": "/etc/init.d/presto-launcher start",
    "stop": "/etc/init.d/presto-launcher stop",
    "pid-file": "#{$presto_run_dir}/presto-server.pid",
    "pattern": "presto-server",
    "depends": ["run-presto-server"]
  }
]
EOF
    )
  end
  sudo "mv /tmp/presto.conf /etc/service-nanny/presto.conf"
  sudo "echo '1' >/tmp/run-presto-server"
  sudo "mv /tmp/run-presto-server /mnt/var/run/presto/run-presto-server"
  sudo "chmod +x /etc/service-nanny/presto.conf"
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
