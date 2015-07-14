Understanding CLASSPATH and Environment variables with Spark on YARN
=====================

## Note on Spark versions

Since the beginning of Spark the exact instructions about how one goes about influencing the CLASSPATH and environment variables of driver, executors and other cluster manager JVMs have often changed from release to release.   This information is current as of Spark release 1.3.1.  Please cross reference the appropriate [Spark documentation](http://spark.apache.org/docs/latest/) for the version in use.   

Key reference points in the documentation to consider:
* [Configuration](http://spark.apache.org/docs/latest/configuration.html)
* [Running on YARN](http://spark.apache.org/docs/latest/running-on-yarn.html)

## Review of Spark architecture and integration with YARN cluster manager

For a detailed description of Spark on a cluster manager such as YARN please see the Spark documentation [Cluster Mode Overview](http://spark.apache.org/docs/latest/cluster-overview.html).  In brief, Spark uses the concept of *driver* and *executor*.  The SparkContext and client application interface occurs within the driver while the executors handle the computations and in-memory data store as directed by the Spark engine.  It is within the executors that distributed/parallel processing occurs.  When Spark is running on YARN the executor JVM runs within a container (one executor per container).  The driver JVM may run within a YARN Application Master container or external to the YARN as a free standing JVM depending on the deployment mode.

Deployment mode:
* client  
** Driver run is its own JVM on the machine upon which the spark-submit is executed  
** Application Master container exists but only performs minimal interaction as needed to provide YARN container management, no user application code executes here  
* cluster  
** Driver executes within the Application Master container JVM  

## YARN client

To adjust the CLASSPATH of the driver in YARN client mode alter the `SPARK_CLASSPATH` variable within `spark-env.sh`.  If using the EMR bootstrap action to install Spark, these setting may also be altered using the `-u` and `-a` arguments as detailed in the [README](../README.md).   The environment variables available to the driver are the same within the shell within which spark-submit is executing.

The executors will use the default YARN classpath as defined by the YARN configuration property `yarn.application.classpath` which will be prepended with the container’s current working directory and the Spark assembly jar.   Any additional properties set by the Spark configuration property `spark.executor.extraClassPath` will prepend to this path as well.

Example of an executor classpath:
```
CLASSPATH=$PWD:$PWD/__spark__.jar:$HADOOP_CONF_DIR:$HADOOP_COMMON_HOME/share/hadoop/common/*:$HADOOP_COMMON_HOME/share/hadoop/common/lib/*:...
```

To set environment variables for executors use the `spark.executorEnv.[EnvironmentVariableName]`, see [runtime environment configuration docs](http://spark.apache.org/docs/latest/configuration.html#runtime-environment) for more details.

## YARN cluster

Given the driver will execute within the YARN Application Master container JVM, it is necessary to utilize Spark configuration properties to alter the YARN container CLASSPATH and environment variables.

The driver and executors will use both start with using the default YARN classpath as defined by the YARN configuration property `yarn.application.classpath` which will be prepended with the container's current working directory and the Spark assembly jar.   

Any additional properties set by the Spark configuration property `spark.driver.extraClassPath` will prepend to this path just for the Application Master which makes it available to the driver.

Any additional properties set by the Spark configuration property `spark.executor.extraClassPath` will prepend to this path just for the executors.  It is rare this property needs to be changed.

To set the driver environment variables, use the `spark.yarn.appMasterEnv.[EnvironmentVariableName]`, see [runtime environment configuration docs](http://spark.apache.org/docs/latest/configuration.html#runtime-environment) for more details.

Setting the environment variables for executors is the same with YARN client, use the `spark.executorEnv.[EnvironmentVariableName]`.

An example of altering the Spark classpath for a driver in YARN cluster mode is given in [Using HiveContext in Cluster Mode](using-hivecontext-yarn-cluster.md).
