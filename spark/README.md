Spark on EMR
=====================

These scripts are an example of installing Spark on EMR and configuring.   Please see https://spark.apache.org/ for details regarding the Spark project.  Additional examples can be found in [/examples/](examples/README.md).


## How to Install/Configure

### 1) Utilize a bootstrap action to install the software

#### Script:   
`s3://support.elasticmapreduce/spark/install-spark`

Note: Spark is available in cn-north-1 starting with 1.2.0.   For eu-central-1 region, adjust the bucket name to `s3://eu-central-1.support.elasticmapreduce/`

#### Arguments (optional):   
-v \<version\>

   **If no version is given, it will install the latest version available for the EMR Hadoop version.**

-g   
   Installs Ganglia metrics configuration for Spark

-l	<logging level>	- Sets log4j.rootCategory. Spark comes with INFO which might be too verbose. If so, try WARN.
                      Possible values: ALL, DEBUG, ERROR, FATAL, INFO, OFF, TRACE, WARN

-x   
   Prepares the default Spark config for dedicated Spark single application use [1 executor per core node, num of executors equivalent to core nodes at creation of cluster, all memory/vcores allocated]


#### Current versions available:
* Hadoop 1.0.3 (AMI 2.x)
 * Spark 0.8.1 
 
* Hadoop 2.2.0 (AMI 3.0.x)
 * Spark 1.0.0 
 
* Hadoop 2.4.0 (AMI 3.1.x and 3.2.0-3.2.3)
 * Spark 1.0.2
 * Spark 1.1.0
 * Spark 1.1.0.b (built with httpclient 4.2.5 to fix version conflict with AWS SDK)
 * Spark 1.1.0.c (spark-submit deploy mode default changed to cluster, kinesis examples included, ganglia metrics plugin included, sql hive dependencies fixed) 
 * Spark 1.1.0.d (kinesis jars added to lib, added JavaKinesisWordCountASLYARN example which uses yarn-cluster for master) 
 * Spark 1.1.0.e (kinesis example sources added to examples dir, includes SPARK-3595 for correct S3 output handling)
 * Spark 1.1.0.f (install script change to work with EMR AMI 3.1.4, 3.2.3 and later)
 * Spark 1.1.0.g (disables multipart upload for Hadoop output formats as workaround, Enables Pyspark support)
 * Spark 1.1.0.h (same as "g", rebuilt with git repo)  [NOTE: Last version of 1.1.0 release ]


* Hadoop 2.4.0 (AMI 3.3.x)
 * Spark 1.1.1.a (Initial version of Spark's 1.1.1 release with select changes for working on EMR)
 * Spark 1.1.1.b (Include SPARK-3595 for EMR S3 output without temporary directory)
 * Spark 1.1.1.c (Change to class path for hadoop-provided profile build, Fix to support hive-site.xml and hive-default.xml with spark-sql)
 * Spark 1.1.1.d (Addition of JVM options for GC, Add Hbase and Kinesis client jars available to classpath)
 * Spark 1.1.1.e (SparkSQL support for EMR S3 output without temporary directory)
 * --
 * *Spark 1.2.0.a (Initial build of Spark's 1.2.0 release)*


#### Experimental versions available (designed to be ran with latest AMI available at time of build)
* branch-1.1 ( "-v 1.1 -b \<buildId\>")
 * 2014112801 (includes SPARK-2848)
 * 2014121700
* branch-1.2 ( "-v 1.2 -b \<buildId\>")
 * 2014120500
 * 2014121700


#### Example:
Using AWS CLI:
```
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --alive 
```


### 2) Utilize an EMR Step to start the Spark history server (optional)

#### Script:
`s3://support.elasticmapreduce/spark/start-history-server (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
None


_Currently works for Spark 1.x._  The history server will be reachable on the master node IP using port 18080

#### Example:
Using AWS CLI:
```
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  \
  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server 
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/start-history-server" --alive
```


### 3) Utilize an EMR Step to configure the Spark default configuration (optional)

#### Script:
`s3://support.elasticmapreduce/spark/configure-spark.bash (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
A key=value pair of configuration items to add or replace in spark-defaults.conf file


#### Example:
Using AWS CLI:
```
aws emr create-cluster --name SparkCluster --ami-version 3.2 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  \
  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server Name=SparkConfigure,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=[s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=100,spark.locality.wait.rack=0]
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/start-history-server" --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=100,spark.locality.wait.rack=0" --alive 
```

