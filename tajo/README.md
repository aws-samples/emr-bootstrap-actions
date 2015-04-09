Running Tajo on EMR:
======================
Currently Tajo is supported on EMR through a bootstrap action.

* Installing the AWS Command Line Interface
  * link: http://docs.aws.amazon.com/cli/latest/userguide/installing.html

* s3 path
  * script: s3://beta.elasticmapreduce/bootstrap-actions/tajo/install-tajo.sh
    * direct link : https://s3.amazonaws.com/beta.elasticmapreduce/bootstrap-actions/tajo/install-tajo.sh
  * template: s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0
   
Bootstrap Action Arguments:
==========================

Usage: install-tajo.sh [-t|--tar] [-c|--conf] [-l|--lib] [-h|--help] [-e|--env] [-s|--site] [-T|--test-home] [-H|--test-hadoop-home]

    -t, --tar [S3_PATH_TO_TAJO_BIN_TARBALL]
       Tajo binary tarball URL.
       Default: http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.10.0/tajo-0.10.0.tar.gz
       Ex: s3://[your_bucket]/[your_path]/tajo-0.10.0.tar.gz or http://apache.mirror.cdnetworks.com/tajo/tajo-0.10.0/tajo-0.10.0.tar.gz
    -c, --conf [S3_PATH_TO_TAJO_CONF_DIR] 
       Tajo conf directory URL.
       Ex: --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf
    -l. --lib [S3_PATH_TO_THIRD_PARTY_JARS_DIR]
       Tajo third party lib URL.
       Ex: --lib s3://{your_bucket}/{your_lib_dir} or http://{lib_url}/{lib_file_name.jar}
    -v, --tajo-version [INSTALL_TAJO_VERSION]
       Default: Apache tajo stable version.
       Ex: --tajo-version x.x.x
    -h, --help
       Display help message
    -e, --env
       Item of tajo-env.sh(space delimiter)
       Ex: --env "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"
    -s, --site
       Item of tajo-site(space delimiter)
       Ex: --site "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore"
    -T, --test-hadoop-home [LOCAL_PATH_TO_TEST_ROOT] (only used for local test)
       Local test directory path
       Ex: /[LOCAL_PATH_TO_TEST_ROOT]
    -H, --test-hadoop-home [LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST] (only used for local test)
       Local test HADOOP_HOME
       Ex: /[LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST]

 * Note that all arguments are optional. ``-T`` and ``-H`` are only used for local test.
 * ``-t`` allows a user to specify a custom Tajo binary archive file through S3 URL or HTTP URL.
 * ``-e`` allows a user to specify environment variables in tajo-env.sh. Multiple environment variables can be combined in a space delimted list. Please refer to the above example.
 * ``-s`` allows a user to specify config properties in tajo-site.xml. Multiple properties can be combined in a space delimited list. Please refer to the above example.

Sample Commands:
================

Launching a Tajo cluster with a default configurations
-------------------------------------------------------
 * It uses EMR HDFS as ```tajo.root``` which includes the warehouse directory
 * It uses all default heap and concurrency configs.
 * It is good for a simple test. 
 
```
$ aws emr create-cluster    \
	--name="[CLUSTER_NAME]"  \
	--ami-version=3.3        \
	--no-auto-terminate	\
	--ec2-attributes KeyName=[KEY_PAIR_NAME] \
	--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge \
	--bootstrap-action Name="Install tajo",Path=s3://beta.elasticmapreduce/bootstrap-actions/tajo/install-tajo.sh
```

Launching a Tajo cluster with additional configurations
-------------------------------------------------------


 * To use your Tajo tarball, you should use ```-t``` to specify S3 URL.
 * To change ```tajo.rootdir```, you should make your own ```tajo-site.xml``` and use ```-c``` option to specify S3 URL for config dirs.
   * You can find appropriate config templates in https://github.com/awslabs/emr-bootstrap-actions/tree/master/tajo/template.
 * if you need third party(external) library like xxx.jar, use ```-l``` option to specify S3 directory URL, including third party Jars.
 
```
    aws emr create-cluster \
    --name="[CLUSTER_NAME]" \
    --ami-version=3.3 \
    --no-auto-terminate	\
    --ec2-attributes KeyName=[KEY_PAIR_NAME] \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge \
    --bootstrap-action Name="Install tajo",Path=s3://beta.elasticmapreduce/bootstrap-actions/tajo/install-tajo.sh,Args=["-t","s3://[your_bucket]/tajo-0.10.0.tar.gz","-c","s3://[your_bucket]/conf","-l","s3://[your_bucket]/lib"]
```

Terminating a Tajo cluster
-------------------------------------------------------

You need to remember your cluster id when you launch an Tajo cluster. Please replace ```<CLUSTER_ID>``` by your cluster id.

```
    aws emr terminate-clusters --cluster-ids "<CLUSTER ID>"
```

Listing a instance of Tajo cluster
-------------------------------------------------------

You need to remember your cluster id when you launch an Tajo cluster. Please replace ```<CLUSTER_ID>``` by your cluster id.

```
    aws emr list-instances --cluster-ids "j-FC5DVH3RI6AA"
```

How to test bootstrap in local machine
=======================================
```install-tajo.sh``` allows users to test the bootstrap in local machine without EMR instances. For it, you need to use ```-T``` and ```-H``` options.
 * ```-T``` - Testing root dir which is temporarily used for testing.
 * ```-H``` - Hadoop binary directory which is used to pretended to be EMR Hadoop home

```   
$ ./install-EMR-tajo.sh -t /[your_local_binary_path]/tajo-0.10.0.tar.gz -c /[your_test_conf_dir]/conf -l /[your_test_lib_dir]/lib -T /[LOCAL_PATH_TO_TEST_ROOT] -H /[LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST]
```


Running with AWS RDS
====================
Tajo can use RDS. For it:
 * You need to make sure you already have a running RDS instance. And then infomation about RDS set to ```-s``` option.
 * To use RDS, you needs appropriate JDBC jars like mysql-connector.jar. ```-l``` option allows you to specify S3 directory URL, including third party Jars.

```
    aws emr create-cluster \
    --name="[CLUSTER_NAME]" \
    --ami-version=3.3 \
    --ec2-attributes KeyName=[KEY_PAIR_NAME] \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge \
    --bootstrap-action Name="Install tajo",Path=s3://beta.elasticmapreduce/bootstrap-actions/tajo/install-tajo.sh,Args=["-t","s3://[your_bucket]/tajo-0.10.0.tar.gz","-c","s3://[your_bucket]/conf","-l", \
    "http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.28/mysql-connector-java-5.1.28.jar", \
    "-s","tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore tajo.catalog.jdbc.connection.id={id} tajo.catalog.jdbc.connection.password={password} tajo.catalog.jdbc.uri=jdbc:mysql://{RDS_URL}:3306/tajo?createDatabaseIfNotExist=true"]
```

Please refer to [Catalog configuration documentation] (http://tajo.apache.org/docs/current/configuration/catalog_configuration.html) in Tajo doc.

