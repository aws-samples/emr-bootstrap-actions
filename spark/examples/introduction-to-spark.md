Introduction to Spark
=====================

For the official documentation regarding Spark please see https://spark.apache.org/.  The books ["Learning Spark: Lightning-Fast Big Data Analysis"](http://www.amazon.com/Learning-Spark-Lightning-Fast-Data-Analysis/dp/1449358624/ref=sr_1_1?ie=UTF8&qid=1425312574&sr=8-1&keywords=apache+spark) and ["Advanced Analytics with Spark: Patterns for Learning from Data at Scale"](http://www.amazon.com/Advanced-Analytics-Spark-Patterns-Learning/dp/1491912766/ref=sr_1_2?ie=UTF8&qid=1425312574&sr=8-2&keywords=apache+spark) are good resources.  Installing and configuring Spark on EMR can be found at [/spark/README.md](../README.md).  Examples of using Spark with EMR can be found at [/examples/](README.md).


## What is Spark?

As the official documentation states: ["Apache Spark is a fast and general-purpose cluster computing system"](http://spark.apache.org/docs/latest/).  Think of Spark as the next iteration in the evolution of cluster computing such that the user can further distance one self from the mechanics, problems and difficulties of distributed/parallel processing of data at scale for a cluster.  For the user, Spark strives to provide a common, high-level API that can be used by multiple programming languages (Java, Scala, Python) and extend the Spark core through tools ([SparkSQL](https://spark.apache.org/sql/),[MLib](https://spark.apache.org/docs/1.2.0/mllib-guide.html),[Spark Streaming](https://spark.apache.org/docs/1.2.0/streaming-programming-guide.html), etc.) to provide often used interfaces (such as interactive shell, SQL) and common algorithms/processes (MapReduce, graph processing, machine learning, stream processing, plus more).


## Is this not the same definition of Hadoop?  Are Spark and Hadoop the same? Does Spark replace Hadoop?

Spark and Hadoop do share overlapping areas in regards to distributed computing and Spark can utilize Hadoop project components (HDFS, YARN, Input/Output formats) and other Hadoop-related projects (Hive, HBase), but Spark is not built on the Hadoop framework nor does it require Hadoop to operate.  Spark can co-exist with a Hadoop cluster and often interfaces with data located in HDFS.  A view on Spark/Hadoop can be found at Databricks' article https://databricks.com/blog/2014/01/21/spark-and-hadoop.html.


## Why use Spark?  What are the advantages to using Spark?  
* Single coding/application interface  
 * The same code works locally and across clusters.  
 * Cluster deployment and execution is abstracted away from user. (http://spark.apache.org/docs/latest/submitting-applications.html)  
 
* [Resilient Distributed Datasets (RDDs)](http://spark.apache.org/docs/latest/programming-guide.html#resilient-distributed-datasets-rdds)  
  * A collection of elements that represent a data set either in-memory, on disk and/or both.  
  * Maintained lineage graph through transformations of RDDs which allows for Spark to automatically identify and recompute missing elements of data as needed.  
  * Spark engine understands when/how to perform parallel computations based on actions/transformations requested by user.  

* Big Data oriented engine design  
 * Spark as an engine is built to be efficient and intelligent about computations across a distributed data set.  
 * Through actions, transformations and tools common techniques/processes in data processing are handled effectively for the user ([example of PageRank](https://spark.apache.org/docs/latest/graphx-programming-guide.html#pagerank)).

  
## How does Spark work with EMR?  Isn't EMR just Hadoop?

Spark can run on multiple types of clusters including Hadoop YARN.   EMR makes it easy to turn up a Hadoop cluster with Spark preconfigured to integrate with YARN ([instructions for Spark on EMR](../README.md)).   Running Spark within YARN allows for other YARN applications such as Hadoop MapReduce jobs to share cluster resources.  


## How does a Spark application run in YARN?

Spark uses an application model that consists of a driver process and multiple executor processes.   The driver process is where the user provided code runs and interfaces with the Spark engine through a SparkContext ([see this doc for more details about SparkConext](http://spark.apache.org/docs/latest/programming-guide.html)).  The executors provide a distributed memory cache for RDDs and local resources per executor for distributed computing.   An action or transformation of a RDD or set of RDDs as requested by the user provided code that result in a distributed or parallel processing work will be planned and executed by the Spark engine using the executors.   

The Spark engine builds a DAG ([directed acyclic graph](http://en.wikipedia.org/wiki/Directed_acyclic_graph)) of the work to be performed and models these as stages with each stage consisting of distributed tasks.  The Spark engine handles the management and scheduling of the stage and task processing utilizing the compute resources of each executor.  

When a Spark application is running in YARN the driver process either runs as the client application interfacing with the YARN cluster or within the ApplicationMaster container itself of the YARN application launched ([Spark supports yarn-client and yarn-cluster modes of deployment](https://spark.apache.org/docs/latest/running-on-yarn.html).  Each executor will be run within its own YARN container.

For full details about running Spark on YARN please see https://spark.apache.org/docs/latest/running-on-yarn.html.


## How do I learn Spark?

* Installing and configuring Spark on EMR can be found at [/spark/README.md](../README.md).
* [Spark's quick start documentation](http://spark.apache.org/docs/latest/quick-start.html)
* ["Learning Spark: Lightning-Fast Big Data Analysis"](http://www.amazon.com/Learning-Spark-Lightning-Fast-Data-Analysis/dp/1449358624/ref=sr_1_1?ie=UTF8&qid=1425312574&sr=8-1&keywords=apache+spark)   
* ["Advanced Analytics with Spark: Patterns for Learning from Data at Scale"](http://www.amazon.com/Advanced-Analytics-Spark-Patterns-Learning/dp/1491912766/ref=sr_1_2?ie=UTF8&qid=1425312574&sr=8-2&keywords=apache+spark)   
*   Examples of using Spark with EMR can be found at [/examples/](README.md)
