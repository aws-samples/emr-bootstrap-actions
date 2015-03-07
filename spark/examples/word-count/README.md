# Runnging Spark Word Count example on Amazon EMR
The document shows how to run a simple word count example for files sitting on Amazon S3

#Contents
This project has two files 
- ``build.sbt`` File containing the build defination
- ```WordCount.scala``` Our word count code

# Prerequisites
- Amazon Web Services account
- [AWS Command Line Interface (CLI)]
- Amazon EMR cluster running Apache Spark

# How to build
Build this project using SBT

#Submitting code to cluster
Copy your project JAR to your [Amazon EMR] cluster running Spark and from command line run the following command. This will submit our spark job to cluster and print the results on screen. 

```MASTER=yarn-client /home/hadoop/spark/bin/spark-submit --class WordCount path/to/JAR/wordcount_2.10-1.0.jar```

[Amazon EMR]:http://aws.amazon.com/elasticmapreduce/
[AWS Command Line Interface (CLI)]:http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html

