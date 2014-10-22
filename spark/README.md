Spark on EMR
=====================

These scripts are an example of installing Spark on EMR and configuring.   Please see https://spark.apache.org/ for details regarding the Spark project.


## How to Install/Configure

### 1) Utilize a bootstrap action to install the software

#### Script:   
`s3://support.elasticmapreduce/spark/install-spark`


#### Arguments (optional):   
-v \<version\>

   **If no version is given, it will install the latest version available for the EMR Hadoop version.**

-g   
   Installs Ganglia metrics configuration for Spark


#### Current versions available:
* Hadoop 1.0.3 (AMI 2.x)
 * Spark 0.8.1 
 
* Hadoop 2.2.0 (AMI 3.0.x)
 * Spark 1.0.0 
 
* Hadoop 2.4.0 (AMI 3.1.x and 3.2.x)
 * Spark 1.0.2
 * Spark 1.1.0
 * Spark 1.1.0.b (built with httpclient 4.2.5 to fix version conflict with AWS SDK)
 * Spark 1.1.0.c (spark-submit deploy mode default changed to cluster, kinesis examples included, ganglia metrics plugin included, sql hive dependencies fixed) 


#### Example:
```
Using AWS CLI:
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 --ec2-attributes KeyName=MYKEY --applications Name=Hive --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark
```


### 2) Utilize an EMR Step to start the Spark history server (optional)

#### Script:
`s3://support.elasticmapreduce/spark/start-history-server (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
None


_Currently works for Spark 1.x._  The history server will be reachable on the master node IP using port 18080

#### Example:
```
Using AWS CLI:
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 --ec2-attributes KeyName=MYKEY --applications Name=Hive --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server 
```


### 3) Utilize an EMR Step to configure the Spark default configuration (optional)

#### Script:
`s3://support.elasticmapreduce/spark/configure-spark.bash (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
A key=value pair of configuration items to add or replace in spark-defaults.conf file


#### Example:
```
Using AWS CLI:
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 --ec2-attributes KeyName=MYKEY --applications Name=Hive --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server Name=SparkConfigure,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=[s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=100,spark.locality.wait.rack=0]
```

