Running Tajo on EMR:
======================
Currently Tajo is supported on EMR through a bootstrap action.

* s3 path : s3://tajo-emr/install-tajo.sh

Bootstrap Action Arguments:
==========================

Usage: install-tajo.sh [OPTIONS]

    -t [S3_PATH_TO_TAJO_BIN_TARBALL]
       Ex: s3://[your_bucket]/[your_path]/tajo-{version}.tar.gz
       Default: http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.9.0/tajo-0.9.0.tar.gz
    -c [S3_PATH_TO_TAJO_CONF_DIR] 
       Ex: s3://[your_bucket]/[your_path]/conf
    -l [S3_PATH_TO_THIRD_PARTY_JARS_DIR]
       Ex: s3://[your_bucket]/[your_path]/lib
    -h
       Display help message
    -T [LOCAL_PATH_TO_TEST_ROOT] (only used for local test)
       Ex: /[LOCAL_PATH_TO_TEST_ROOT]
    -H [LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST] (only used for local test)
       Ex: /[LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST]

Note that all arguments are optional. ``-T`` and ``-H`` are only for local test.


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
	--ec2-attributes KeyName=[KEY_FIAR_NAME] \
	--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge \
	--bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh
```

Launching a Tajo cluster with additional configurations
-------------------------------------------------------


 * To use your Tajo tarball, you should use ```-t``` to specify S3 URL.
 * To change ```tajo.rootdir```, you should make your own ```tajo-site.xml``` and use ```-c``` option to specify S3 URL for config dirs.
   * You can find appropriate config templates in https://github.com/gruter/emr-bootstrap-actions/tree/tajo/tajo/template.
 * To use RDS, you needs appropriate JDBC jars like mysql-connector.jar. ```-l``` option allows you to specify S3 directory URL, including third party Jars.

 
```
    aws emr create-cluster \
    --name="[CLUSTER_NAME]" \
    --ami-version=3.3 \
    --ec2-attributes KeyName=[KEY_FIAR_NAME] \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge \
    --bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh,Args=["-t","s3://[your_bucket]/tajo-0.9.0.tar.gz","-c","s3://[your_bucket]/conf","-l","s3://[your_bucket]/lib"]
```


How to test bootstrap in local machine
=======================================
```install-tajo.sh``` allows users to test the bootstrap in local machine without EMR instances. For it, you need to use ```-T``` and ```-H``` options.
 * ```-T``` - Testing root dir which is temporarily used for testing.
 * ```-H``` - Hadoop binary directory which is used to pretended to be EMR Hadoop home

```   
$ ./install-EMR-tajo.sh -t /[your_local_binary_path]/tajo-0.9.0.tar.gz -c /[your_test_conf_dir]/conf -l /[your_test_lib_dir]/lib -T /[LOCAL_PATH_TO_TEST_ROOT] -H /[LOCAL_PATH_TO_HADOOP_HOME_FOR_TEST]
```


Running with AWS RDS
====================
Tajo can use RDS. For it, you need to make sure you already have a running RDS instance. Then, you need to make your ```catalog-site.xml```. Please refer to [Catalog configuration documentation] (http://tajo.apache.org/docs/current/configuration/catalog_configuration.html) in Tajo doc.

Also, you should use ```-c``` option in order to use your custom ```catalog-site.xml``` file.
