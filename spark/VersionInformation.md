Spark Versions and Builds Available 
===================================

**IMPORTANT!! Beginning with EMR AMI 3.8, Spark is available as a native application in EMR.  Please see [EMR's Spark on EMR page](http://aws.amazon.com/elasticmapreduce/details/spark/). Please refer to the EMR documentation for instructions on configuring and using the native Spark.  The use of this 3rd party style installation is out of date and is surpased by the native Spark versions available on EMR.**


For installation and examples see  [README.md](README.md).


Each of the below EMR AMIs will install the last Spark build available for that AMI.


To request a specific Spark version build use "-v" to request a specific build version.   


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


* Hadoop 2.4.0 (AMI 3.3.x and 3.4.x)
 * Spark 1.1.1.a (Initial version of Spark's 1.1.1 release with select changes for working on EMR)
 * Spark 1.1.1.b (Include SPARK-3595 for EMR S3 output without temporary directory)
 * Spark 1.1.1.c (Change to class path for hadoop-provided profile build, Fix to support hive-site.xml and hive-default.xml with spark-sql)
 * Spark 1.1.1.d (Addition of JVM options for GC, Add Hbase and Kinesis client jars available to classpath)
 * Spark 1.1.1.e (SparkSQL support for EMR S3 output without temporary directory)
 * --
 * Spark 1.2.0.a (Initial build of Spark's 1.2.0 release)
 * Spark 1.2.1.a (Initial build of Spark's 1.2.1 release)
 * --
 * Spark 1.2.2.a (Initial build of Spark's 1.2.2 release)

* Hadoop 2.4.0 (AMI 3.5.x, 3.6.x, 3.7.x)
 * Spark 1.3.0.a (Initial build of Spark's 1.3.0 release) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.0.a)
 * Spark 1.3.0.b (Minor patches to support S3 direct commit with SparkSQL and disable multipart uploads as workaround) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.0.b)
 * Spark 1.3.0.c (Includes Parquet fix for [SPARK-6330](https://issues.apache.org/jira/browse/SPARK-6330)) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.0.c)
 * Spark 1.3.0.d (Removes no longer relevant JavaKinesisWordCountASLYARN example, just reference stock JavaKinesisWordCountASL example)* [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.0.d)
 * --
 * Spark 1.3.1.a (Initial build of Spark's 1.3.1 release) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.a)
 * Spark 1.3.1.b (Includes classpath workaround for comptability with EMR Step usage) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.b)
 * Spark 1.3.1.c (Includes workaround for Ganglia/SPARK-6484) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.c)
 * Spark 1.3.1.d (Fix SparkHistory server startup error with EMR step) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.d)
 * *Spark 1.3.1.e (Includes SPARK-6352 for Parquet and SparkSQL use of predefined output committer)* [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.e)
 * Spark 1.3.1.f (Aligns AWS SDK version and htpclient version with AMI 3.9) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.3.1.f)
 * Spark 1.4.0.a (Initial build of Spark's 1.4.0 release including SPARK-8329) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.4.0.a)
 * Spark 1.4.0.b (Includes sparkR) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.4.0.b)
 * Spark 1.4.1.a (Includes sparkR) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.4.1.a)
 * Spark 1.4.1.b (Aligns AWS SDK version with AMI 3.9) [(Build source for reference)](https://github.com/christopherbozeman/spark/tree/bozemanc-v1.4.1.b)

#### Experimental versions available (designed to be ran with latest AMI available at time of build)
* branch-1.1 ( "-v 1.1 -b \<buildId\>")
 * 2014112801 (includes SPARK-2848)
 * 2014121700
* branch-1.2 ( "-v 1.2 -b \<buildId\>")
 * 2014120500
 * 2014121700

**IMPORTANT!! Beginning with EMR AMI 3.8, Spark is available as a native application in EMR.  Please see [EMR's Spark on EMR page](http://aws.amazon.com/elasticmapreduce/details/spark/). Please refer to the EMR documentation for instructions on configuring and using the native Spark.**

