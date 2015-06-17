Understanding Spark memory configuration on YARN
=====================

## Note on Spark versions

This information is based on Spark 1.3.1 on YARN.   Given the speed of development of the Spark project please review Spark documentation for the version being utilized.
* [Running on YARN](http://spark.apache.org/docs/latest/running-on-yarn.html)

## Review of Spark architecture and integration with YARN cluster manager

For a detailed description of YARN, see [Hadoop YARN](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html) documentation.  The key components of concern to Spark on YARN is the containers and the special container given the role of Application Master.  Recall that containers are allocated according the YARN scheduler implemented (`yarn.resourcemanager.scheduler.class`).   The primary properties of consideration for container allocation is memory and vcores.  All containers will be allocated at least `yarn.scheduler.minimum-allocation-mb` of memory and within `yarn.scheduler.maximum-allocation-mb`.  If the requested memory amount is more than `yarn.scheduler.minimum-allocation-mb` then memory is allocated in multiples of this value.

For a detailed description of Spark on a cluster manager such as YARN please see the Spark documentation [Cluster Mode Overview](http://spark.apache.org/docs/latest/cluster-overview.html).  In brief, Spark uses the concept of *driver* and *executor*.  The SparkContext and client application interface occurs within the driver while the executors handle the computations and in-memory data store as directed by the Spark engine.  It is within the executors that distributed/parallel processing occurs.  The driver can be running in its own JVM when the Spark application is submitted in a client deployment mode or the driver can be running within the YARN Application Master container.

## Driver

The driver may run in its own JVM or within the Application Master container depending on the deployment mode.  The memory for the driver is determined by the Spark property `spark.driver.memory` plus an overhead set by property `spark.yarn.driver.memoryOverhead`.   If the deployment mode is client, the Application Master container uses the memory setting from property `spark.yarn.am.memory` plus the overhead amount defined by `spark.yarn.am.memoryOverhead`.  If the deployment mode is cluster, the Application Master container is the same JVM as the driver which would be `spark.driver.memory` plus `spark.yarn.driver.memoryOverhead`.

## Executors

Regardless of deployment mode, the executors will use a memory allocation based on the property of `spark.executor.memory` plus an overhead defined by `spark.yarn.executor.memoryOverhead`.

## Memory aligned with YARN container allocation

Provided that Spark on YARN is running as a YARN application a memory allocation request for a container (whether it be for driver or executor) must follow the memory size formula as determined by YARN.  Therefore, it is possible for YARN to allocate more total memory per container than requested by the Spark application due to the YARN's handling of memory in multiples of `yarn.scheduler.minimum-allocation-mb`.  The larger the difference between the Spark requested memory size and the actual container memory the greater the waste of memory on the cluster.  For efficient memory utilization be sure to select total memory values which are multiples of `yarn.scheduler.minimum-allocation-mb`.

