Running Presto on EMR:
======================
Currently presto is supported on EMR through a bootstrap action. 

###Latest Version
For the latest version of Presto supported by EMR, please look in the "latest" folder of this repository. 

Bootstrap Action Arguments:
==========================

Usage: install_presto [OPTIONS]

    -s [S3_PATH_TO_PRESTO_SERVER_BIN], --s3-path-to-presto-server-bin \n
                                     Ex : s3://path/to/bin/presto-server-[version_number].tar.gz 
    -c [S3_PATH_TO_PRESTO_CLI],  --s3-path-to-presto-cli 
                                     Ex : s3://path/to/bin/presto-cli-executible-[version_number].jar 
    -m [S3_PATH_TO_MASTER_CONFIG], --s3-path-to-master-config   
                                     Ex : s3://path/to/config/dir/master.config 
    -w [S3_PATH_TO_WORKER_CONFIG],  --s3-path-to-worker-config   
                                     EX : s3://path/to/config/dir/worker.config 
    -p [HIVE_METASTORE_PORT],  --hive-metastore-port    
                                     EX: 11235 (Defaults to 9083) 
    -h, --help                       Display this message 

Note that all arguments are optional.
Default version used for now is 0.78


Sample Commands:
================

1. Default configuration:  
aws emr  create-cluster --name="PRESTO-default"  --ami-version=3.2.3 --applications Name=hive   --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb"

2. Override Master and Worker Config:  
aws emr  create-cluster --name="PRESTO-master-slave"  --ami-version=3.2.3   --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb",Args=["-m","s3://path/to/master/config","-w","s3://path/to/worker/config"]

3. Change the hive metastore port:  
aws emr  create-cluster --name="PRESTO-default"  --ami-version=3.2.3 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge  InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge  --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb",Args=["-m","s3://path/to/master/config","-w","s3://path/to/worker/config","-p","11235"]

4. Provide your own presto server tarball path:  
aws emr  create-cluster --name="PRESTO-default"  --ami-version=3.2.3 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge  --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb",Args=["-m","s3://path/to/master/config","-w","s3://path/to/worker/config","-p","11235","-s","s3://path/to/presto/server/tarball"]

5. Provide both server tarball and cli jar path:  
aws emr  create-cluster --name="PRESTO-default"  --ami-version=3.2.3   --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge  --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb",Args=["-m","s3://path/to/master/config","-w","s3://path/to/worker/config","-p","11235","-s","s3://path/to/presto/server/tarball","-c","s3://path/to/presto/cli/jar"]


Running with AWS RDS
====================
Presto can also use rds, but you will need to make sure you have an rds instance running. 

Steps are given below: 

1. Create rds instance.  
Example : aws rds create-db-instance --db-instance-identifier "presto-rds-test" --db-name "prestodb" --allocated-storage 5 --db-instance-class db.m1.xlarge 
--engine MySQL --master-username "root" --master-user-password "your_password"

2. Get the address for rds instance by "describe-db-instances".  
Example: aws rds describe-db-instances  --db-instance-identifier "presto-rds-test" 
Which would give you a json output, look for something similar to this : 
"Endpoint": {
                "Port": 3306, 
                "Address": "presto-rds-test.cng7u3y2mvki.us-east-1.rds.amazonaws.com"
            }

3. Use the above address in hive-site.xml  
Sample hive-site.xml is provided in the repository itself under presto/samples/hive-site.xml.sample

4. For running with rds, you will need to update hive-site.xml with the bootstrap action so that hive knows the metastore uri. 

Sample command to launch presto cluster with rds :

aws emr  create-cluster --name="PRESTO-test"  --ami-version=3.2.3   --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge  --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb",Args=["-m","s3://path/to/master/config","-w","s3://path/to/worker/config","-p","11235"] Name="install hive-site",Path="s3://us-east-1.elasticmapreduce/libs/hive/hive-script",Args=["--base-path","s3://us-east-1.elasticmapreduce/libs/hive","--install-hive-site","--hive-site=s3://path/to/hivesite","--hive-versions","latest"]


Presto Configuration:  
=====================
The bootstrap action configures by reading properties from an s3 hosted json file. 
EMR has its own default configurations which are still in experimentation stage, 
but the users are free to override the default configuration with their config json file hosted on s3.

Points to note about configs:    

1. User just needs to override the properties that he/she may wish to change compared to default configuration. 
2. If a user does not want to change anything in a particular config file, then that file will be configured from the 
   default configuration file. 
3. Any extra property mentioned by user apart from the ones mentioned in default configuration will be copied as 
   it is to the respective presto configuration file on the cluster.  
 
Default configuration json file is provided in the repository itself under presto/samples/default_presto_config.json

NOTES: 
=====
1. Please note that BA does not start metastore, user has to run "hive set up" step to use presto since BA only 
changes the hive-init script to run metastore as a remote service. Thus only when user runs hive set up, 
metastore will be started. 

2. The following properties will be ignored in the user config :  
   * "node.id" in etc/node.properties (value configured while BA is run)
   * "coordinator" in etc/config.properties (true for master , false for slave)
   * "http-server.http.port" in etc/config.properties (8080)
   * "discovery.uri" in etc/config.properties(http://[MASTER_DNS]:8080)
   * User cannot configure the "hive.metastore.uri" in etc/catalog/hive.properties since currently, 
   it is configured to run on the master but user can specify the port on which to run the hive metastore 
   by using -p option with the boot strap action.
3. It is mandatory to run install hive step to use Presto since the BA changes the install hive script to 
   start the metastore service as well. The metastore would be started on the port given with -p option or default port, 
   i.e. 9083 
   

Add-ons with the  bootstrap action:
===================================
1. The bootstrap action would configure service-nanny to monitor presto-server process.
2. It would also configure the instance controller to upload the logs to node/$instance-id/apps/presto/
3. Presto cli is installed only on the master. 


Sample Usage
============

* Launch a cluster with presto BA and run hive set up step.

Example: aws emr  create-cluster --name="PRESTO-default"  --ami-version=3.2.3 --applications Name=hive   --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/install-presto.rb" 

* ssh into master node.

Example: aws emr ssh --cluster-id [JOBFLOW_ID] --key-pair [PATH/TO/KEYPAIR/FILE]

* Launch hive cli. 

Example:  [hadoop@ip-10-169-128-182 ~]$ hive
hive> 

* Create a table on hive 

Example: 
DROP TABLE IF EXISTS apachelog;
CREATE EXTERNAL TABLE apachelog (
host STRING,
 IDENTITY STRING,
 USER STRING,
 TIME STRING,
request STRING,
 STATUS STRING,
 SIZE STRING,
 referrer STRING,
 agent STRING
)
PARTITIONED BY(iteration_no int)
LOCATION 's3://publicprestodemodata/apachelogsample/hive';

* Recover Partitions by running repair table command.

Example: 
hive> msck repair table apachelog;

* Launch presto cli (on the master)

Example: ./presto --server localhost:8080 --catalog hive --schema default

* Run Queries on presto.

Example:  select * from apachelog where iteration_no=101 limit 10;



