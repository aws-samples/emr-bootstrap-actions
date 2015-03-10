# Runnging Wikipedia SparkSQL example on Amazon EMR
The document shows how to run a simple word count example for files sitting on Amazon S3

#Contents
This project has two files 
- ``build.sbt`` File containing the build defination
- ```WikiS3SparkSQL.scala``` Our word count code

Querying data sitting in S3 bucket 
```
s3://support.elasticmapreduce/bigdatademo/sample/wiki
```
Each line in the log file has four fields: ``projectcode, pagename, pageviews, and bytes``. 
A sample of the type of data stored in Wikistat is shown below.

```
en Barack_Obama 997 123091092
en Barack_Obama%27s_first_100_days 8 850127
en Barack_Obama,_Jr 1 144103
en Barack_Obama,_Sr. 37 938821
en Barack_Obama_%22HOPE%22_poster 4 81005
en Barack_Obama_%22Hope%22_poster 5 102081
```

# Build using SBT
Download the two files and build this project using SBT. Keep in mind to maintain the directory structure

```
./build.sbt
./src
./src/main
./src/main/scala
./src/main/scala/WikiS3SparkSQL.scala
```

#Submitting code to cluster
Copy your project JAR to your [Amazon EMR] cluster running Spark and from command line run the following command. This will submit our spark job to cluster and print the results on screen. 

```MASTER=yarn-client /home/hadoop/spark/bin/spark-submit --class WikiS3SparkSQL /path/to//example-wikisparksql_2.10-1.0.jar```


