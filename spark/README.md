Spark on EMR
=====================

These scripts are example of installing Spark on EMR and configuring.   


## How to Install/Configure

###1) Utilize a bootstrap action to install the software

Script:
s3://support.elasticmapreduce/spark/install-spark


Arguments (optional):
-v <spark_version>

If no version is given, it will install the latest version available for the EMR Hadoop version.

-g
Installs Ganglia metrics configuration for Spark


Current versions available:

Hadoop 1.0.3 (AMI 2.x)
    Spark 0.8.1 

Hadoop 2.2.0 (AMI 3.0.x)
    Spark 1.0.0 

Hadoop 2.4.0 (AMI 3.1.x and 3.2.x)
    Spark 1.0.2
    Spark 1.1.0
    Spark 1.1.0.b (built with httpclient 4.2.5 to fix version conflict with AWS SDK)
    Spark 1.1.0.c (spark-submit deploy mode default changed to cluster, kinesis examples included, ganglia metrics plugin included, sql hive dependencies fixed) 


Example of using with the EMR ruby CLI:
```elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark --instance-count 4 --instance-type m3.xlarge --alive 
```


###2) Utilize an EMR Step to start the Spark history server (optional)

Script:
s3://support.elasticmapreduce/spark/start-history-server (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)

Arguments:
None


Currently works for Spark 1.x.

Example of using with the EMR ruby CLI:
```elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar --args "s3://support.elasticmapreduce/spark/start-history-server" --alive
```


###3) Utilize an EMR Step to configure the Spark default configuration (optional)

Script:
s3://support.elasticmapreduce/spark/configure-spark.bash (needs to be executed by s3://elasticmapreduce/libs/script-runner/script-runner.jar)

Arguments:
A key=value pair of configuration items to add or replace in spark-defaults.conf file


Example of using with the EMR ruby CLI:
```elastic-mapreduce --create --name spark --ami-version 3.2 --bootstrap-action s3://support.elasticmapreduce/spark/install-spark --instance-count 4 --instance-type m3.xlarge --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar --args "s3://support.elasticmapreduce/spark/start-history-server" --jar s3://elasticmapreduce/libs/script-runner/script-runner.jar --args "s3://support.elasticmapreduce/spark/configure-spark.bash,spark.default.parallelism=4800,spark.locality.wait.rack=0" --alive 
```

