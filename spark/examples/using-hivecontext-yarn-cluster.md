Using HiveContext in YARN cluster mode
=====================

## Note on Spark versions

Since the beginning of Spark the exact instructions about how one goes about influencing the CLASSPATH and environment variables of driver, executors and other cluster manager JVMs have often changed from release to release.   This information is current as of Spark release 1.3.1.  Please cross reference the appropriate [Spark documentation](http://spark.apache.org/docs/latest/) for the version in use.   

Key reference points in the documentation to consider:
* [Configuration](http://spark.apache.org/docs/latest/configuration.html)
* [Running on YARN](http://spark.apache.org/docs/latest/running-on-yarn.html)

## Review of Spark architecture and integration with YARN cluster manager

For a detailed description of Spark on a cluster manager such as YARN please see the Spark documentation [Cluster Mode Overview](http://spark.apache.org/docs/latest/cluster-overview.html).  In brief, Spark uses the concept of *driver* and *executor*.  The SparkContext and client application interface occurs within the driver while the executors handle the computations and in-memory data store as directed by the Spark engine.  It is within the executors that distributed/parallel processing occurs.  The driver JVM when in cluster deployment mode executes as part of the YARN Application Master container.   This Application Master container may execute on any of the nodemanager nodes as selected by the Resource Manager.
The default YARN classpath is defined by the YARN configuration property `yarn.application.classpath` which will be prepended with the container's current working directory and the Spark assembly jar.   For more information on CLASSPATH and environment variables see [Understanding CLASSPATH and Environment variables with Spark on YARN](understanding-classpath-envvars-yarn.md).


## Making HiveContext work with cluster mode

Given the driver will execute within the YARN Application Master container JVM, it is necessary to utilize Spark configuration properties to alter the YARN container CLASSPATH and environment variables.
Any additional properties set by the Spark configuration property `spark.driver.extraClassPath` will prepend to this path just for the Application Master which makes it available to the driver.

HiveContext interfaces with the Hive metastore using the datanucleus libraries combined with any potentially required DB driver.   The driver also likely needs `hive-site.xml` in order to determine its jdbc connection settings.

Example of additional options provided to `spark-submit` on a master node of EMR cluster running AMI 3.8.0 with Spark 1.3.1 and Hive installed with a MySQL DB metastore external to the cluster that has been configured per [EMR documentation for creating a Hive metastore outside the cluster](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-dev-create-metastore-outside.html):
```
--driver-class-path /home/hadoop/spark/lib/datanucleus-api-jdo-3.2.6.jar:/home/hadoop/spark/lib/datanucleus-core-3.2.10.jar:/home/hadoop/spark/lib/datanucleus-rdbms-3.2.9.jar:/home/hadoop/spark/classpath/emr/mysql-connector-java-5.1.30.jar:hive-site.xml --files /home/hadoop/spark/conf/hive-site.xml --driver-java-options -XX:MaxPermSize=512M 
```

Notice that `hive-site.xml` appears on the classpath and additional files options.   In this example the MySQL DB resource has been configured to allow for IP connections from any of the work nodes.  In the above example it was also necessary to increase the default PermGen size of the Application Master JVM in order to handle the additional Java classes utilized.

### Note about using the master node metastore on EMR in Spark YARN cluster mode

Using the metastore built-in to the master node of an EMR cluster with Spark in YARN cluster mode is the same to Spark as given in the example above with the additional requirement that the `hive-site.xml` jdbc connection URL may need to be altered to change the default value of `localhost` to the full internal hostname with domain name (`hostname -f`) of the master node.   Also, the MySQL DB hive user will likely need to be given additional permissions to be accessible from outside the master node (`echo "grant all on *.* to hive@'%' identified by 'hive'" | mysql -u root`).

