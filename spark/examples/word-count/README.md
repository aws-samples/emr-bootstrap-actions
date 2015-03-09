# Runnging Spark Word Count example on Amazon EMR
The document shows how to run a simple word count example for files sitting on Amazon S3

#Contents
This project has two files 
- ``build.sbt`` File containing the build defination
- ```WordCount.scala``` Our word count code

# Build using SBT
Download the two files and build this project using SBT. Keep in mind to maintain the directory structure

```
./build.sbt
./src
./src/main
./src/main/scala
./src/main/scala/WordCount.scala
```

#Submitting code to cluster
Copy your project JAR to your [Amazon EMR] cluster running Spark and from command line run the following command. This will submit our spark job to cluster and print the results on screen. 

```MASTER=yarn-client /home/hadoop/spark/bin/spark-submit --class WordCount path/to/JAR/wordcount_2.10-1.0.jar```

