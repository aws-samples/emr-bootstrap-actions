Reading LZO files with Spark
=====================

# Goals of this document

Discussion and examples of working with LZO files.

# Background

LZO compressed files are commonly used in big data processing.   Traditionally with Hadoop MapReduce LZO files are not splittable without first being indexed.   Indexing of LZO files can be done using the [twitter/hadoop-lzo](https://github.com/twitter/hadoop-lzo) project.   The `hadoop-lzo.jar` is preinstalled on EMR AMIs at `/home/hadoop/share/hadoop/common/lib/hadoop-lzo.jar`.

Spark provides multiple methods to read in datasets such as `.textFile()`.  The problem with `.textFile()` and LZO compression is that this input format does not understand how to split LZO files even if an indexing is available.

# Example

In order to effectively read LZO datasets utilize the `.newAPIHadoopFile()` method specifying the Hadoop LZO input format `com.hadoop.mapreduce.LzoTextInputFormat` then transform the returned data structure into a RDD for use in the application.  Please note the LZO data should be already indexed ([see twitter/hadoop-lzo](https://github.com/twitter/hadoop-lzo)).

```
val files = sc.newAPIHadoopFile("s3://<YOUR_BUCKET>/<YOUR_PATH_TO_LZO_FILES/*.lzo", classOf[com.hadoop.mapreduce.LzoTextInputFormat],classOf[org.apache.hadoop.io.LongWritable],classOf[org.apache.hadoop.io.Text])
val lzoRDD = files.map(_._2.toString)
```

In this example, `lzoRDD` is now ready to be used with any other transformation and action.  

A working example via spark-shell may be seen with:

```
sc.newAPIHadoopFile("s3://support.elasticmapreduce/spark/examples/lzodataindexed/*.lzo", classOf[com.hadoop.mapreduce.LzoTextInputFormat],classOf[org.apache.hadoop.io.LongWritable],classOf[org.apache.hadoop.io.Text]).map(_._2.toString).count
```


## Credits
Thank you to the open discussions of such issues by users at http://stackoverflow.com/questions/25248170/spark-hadoop-throws-exception-for-large-lzo-files.

