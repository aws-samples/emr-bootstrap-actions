Using Hive and SparkSQL together with Parquet storage on EMR AMI 3.x
=====================

# Goals of this document

To provide guidance and examples of how to use Parquet tables interchangeably between Hive and SparkSQL.  

# Requirements for this example
* Hive 0.13.x
* Spark 1.3
* Spark property `spark.sql.hive.convertMetastoreParquet` set to `false` (https://spark.apache.org/docs/1.3.1/sql-programming-guide.html#configuration)
* Create tables in Hive/SparkSQL using Hive 0.13 DDL, `STORED AS PARQUET` (https://cwiki.apache.org/confluence/display/Hive/Parquet#Parquet-Hive0.13andlater)


# Example

1) Launch a SparkSQL shell on the master node of the cluster to manipulate the data.  This example assumes Spark default configuration already defines the number of cores, memory and instances of executors (https://spark.apache.org/docs/latest/running-on-yarn.html).  The install-spark bootstrap action does provide a `-x` argument to assist in creating a maximized default configuration (https://github.com/awslabs/emr-bootstrap-actions/blob/master/spark/README.md)

```
/home/hadoop/spark/bin/spark-sql --master yarn
```

2) Create a simple external table to use as source for a parquet table.

```
create external table wikistat (projectcode string, pagename string, pageviews int, pagesize int) ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' location 's3://support.elasticmapreduce/bigdatademo/sample/wiki';
```

3) Set the SparkSQL  `spark.sql.hive.convertMetastoreParquet` property. *Important!* (This propery may also be set in `spark-defaults.conf`.)

```
set spark.sql.hive.convertMetastoreParquet=false;
```

4) Define an external table using Parquet on HDFS, insert values and then query.

```
create external table wikistatparquet (projectcode string, pagename string, pageviews int, pagesize int) stored as parquet location '/wikistatparquet';

insert overwrite table wikistatparquet select * from wikistat;

select count(projectcode) from wikistatparquet;
```

5) Exit SparkSQL and start up Hive CLI, then perform query.

```
select count(projectcode) from wikistatparquet;
```


