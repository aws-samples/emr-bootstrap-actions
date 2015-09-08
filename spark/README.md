Spark on EMR
=====================

**IMPORTANT!! Beginning with EMR AMI 3.8, Spark is available as a native application in EMR.  Please see [EMR's Spark on EMR page](http://aws.amazon.com/elasticmapreduce/details/spark/). Please refer to the EMR documentation for instructions on configuring and using the native Spark.**

These scripts are an example of installing Spark on EMR as a 3rd party application and configuring.   Please see https://spark.apache.org/ for details regarding the Spark project.  Additional examples can be found in [/examples/](examples/README.md).


## How to Install/Configure

### 1) Utilize a bootstrap action to install the software

#### Script:   
`s3://support.elasticmapreduce/spark/install-spark`

Note: Spark is available in cn-north-1 starting with 1.2.0.   For eu-central-1 region, adjust the bucket name to `s3://eu-central-1.support.elasticmapreduce/`

#### Arguments (optional):   
-c \<config_file_on_s3\>   
    The install-spark config file which tells the script where to find version specific install scripts and binaries, defaults to AWS provided config.

-v \<version\>   
   **If no version is given, it will install the latest version available for the EMR Hadoop version.**

-g   
   Installs Ganglia metrics configuration for Spark (requires Ganglia to be installed, see http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/UsingEMR_Ganglia.html)
   (Deprecated) Ganglia metrics are now always configured if the Ganglia app is installed.

-x   
   Prepares the default Spark config for dedicated Spark single application use [1 executor per node, num of executors equivalent to core nodes at creation of cluster, all memory/vcores allocated]

-u \<s3://bucket/path_to_find_jars/\>   
   Add the jars in the given S3 path to spark classpath in the user-provided directory (ahead of all other dependencies) 

-a   
   (Use cautiously) Place spark-assembly-*.jar ahead of all system jars on spark classpath (user-provided via -u will still precede.

-l \<threshold\>   
   Set the log level of log4j.logger.org.apache.spark for the driver, defaults to INFO (OFF,ERROR,WARN,INFO,DEBUG,ALL)

-h   
   Utilize EMR Hive jars in Spark classpath instead of the prebuilt Spark Hive jars    

-d \<key\>=\<value\>
   Set <key> to <value> in spark-defaults.conf (may be specified multiple times, prefixing each key-value pair with -d)

#### Current version available:

Default is Spark 1.3.1 (1.3.1.e) with EMR AMI 3.5.x  to 3.8.0 *Beginning with EMR AMI 3.8, Spark is available as a native application in EMR.  Please see [EMR's Spark on EMR page](http://aws.amazon.com/elasticmapreduce/details/spark/).*

Spark 1.4.0 (1.4.0.b) is available with EMR AMI 3.8.x when explicitly requested with `-v 1.4.0.b`.

*All native support for Spark on EMR and subsequent versions (for example, Spark 1.4, 1.5, etc) can be found in the latest releases of EMR without the need for this 3rd party style installation.*


See [VersionInformation.md](VersionInformation.md) for detailed Spark version information and previous versions.


#### Example:
Using AWS CLI (for more on AWS CLI, see http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html):
```
aws emr create-cluster --name SparkCluster --ami-version 3.7 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.7 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --alive 
```

For eu-central-1 region, adjust the bucket name to `s3://eu-central-1.support.elasticmapreduce/`


### 2) Utilize an EMR Step to start the Spark history server (optional)

#### Script:
`s3://support.elasticmapreduce/spark/start-history-server (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
None


_Currently works for Spark 1.x._  The history server will be reachable on the master node IP using port 18080

#### Example:
Using AWS CLI:
```
aws emr create-cluster --name SparkCluster --ami-version 3.7 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  \
  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server 
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.7 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/start-history-server" --alive
```


### 3) Utilize an EMR Step to configure the Spark default configuration (optional - can also use -d flag in install-spark BA)

#### Script:
`s3://support.elasticmapreduce/spark/configure-spark.bash (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)`

#### Arguments:
A key=value pair of configuration items to add or replace in spark-defaults.conf file


#### Example:
Using AWS CLI:
```
aws emr create-cluster --name SparkCluster --ami-version 3.7 --instance-type m3.xlarge --instance-count 3 \
  --ec2-attributes KeyName=<MYKEY> --applications Name=Hive \
  --bootstrap-actions Path=s3://support.elasticmapreduce/spark/install-spark  \
  --steps Name=SparkHistoryServer,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://support.elasticmapreduce/spark/start-history-server Name=SparkConfigure,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=[s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=100,spark.locality.wait.rack=0]
```
EMR Ruby CLI:
```
elastic-mapreduce --create --name spark --ami-version 3.7 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark \
  --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/start-history-server" --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar \
  --args "s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=100,spark.locality.wait.rack=0" --alive 
```

