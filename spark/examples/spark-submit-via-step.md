Spark on EMR - How to Submit a Spark Application with EMR Steps
=====================

# Goals of this document

Demonstrate how to:
1. execute a Spark applicatoin on EMR without using SSH or directly accessing the master node
2. set the executor memory and the driver memory
3. run a specific jar/class
4. shut down the cluster then the application concludes
5. configure the logs to be saved to S3


# Some background

Spark is compatible with Hadoop filesystems and formats so this allows it to access HDFS and S3.

The Spark build installed on EMR as described at https://github.com/awslabs/emr-bootstrap-actions/tree/master/spark allows the Spark application to access S3 out of the box without any additional configuration needed. For example, if a cluster is created with IAM roles (http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-iam-roles-launch-jobflow.html) then S3 will be accessible according to the policy of the associated role.

Spark is ran using YARN (https://spark.apache.org/docs/1.2.0/running-on-yarn.html) thus the stderr/stdout/syslog output of a Spark application is captured by the standard YARN logging For example, the Spark driver will be the YARN application master container and the executors will each have their own container.

Finally, Spark provides the spark-submit utility (https://spark.apache.org/docs/1.2.0/submitting-applications.html) which can either be used interactively with a cluster or via the EMR step framework as a script (http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-hadoop-script.html).



# Examples

To demonstrate I will step through an example using AWS CLI with current latest AMI branch at time of this post. Please replace <YOUR_EC2_KEY_NAME> and <YOUR_VPC_SUBNET_ID> accordingly to match your EC2 key pair name and VPC subnet. There will be a number of <YOUR_VALUE_HERE> replacements that will need to be done with these examples.

## Launch cluster with Spark 

This command creates running cluster with Spark installed and uses an optional install-spark argument to override Spark's defaults with a dedicated Spark application configuration (1 executor per node, use as much memory as possible, see [install-spark readme for more details](../README.md)) and enable logging to a S3 bucket.

```
aws emr create-cluster --name EMR-Spark-Step-Example --ami-version 3.7 \
--instance-type=m3.2xlarge --instance-count 3 --applications Name=Hive  \
--use-default-roles --ec2-attributes KeyName=<YOUR_EC2_KEY_NAME>,SubnetId=<YOUR_VPC_SUBNET_ID> \
--log-uri s3://<YOUR_BUCKET>/<YOUR_PATH> \
--bootstrap-action Name=Spark,Path=s3://support.elasticmapreduce/spark/install-spark,Args=[-x]
```


This command will return a cluster id of the form j-#####. The cluster will also turn up and wait for user to terminate, so be sure to terminate the cluster when done.

## Add an EMR step to the cluster to execute SparkPi example via spark-submit and EMR script execution with the spark-examples jar located in S3

```
aws emr add-steps --cluster-id <YOUR_CLUSTER_ID> --steps \
Name=SparkPi,Jar=s3://<REGION_OF_CLUSTER>.elasticmapreduce/libs/script-runner/script-runner.jar,Args=[/home/hadoop/spark/bin/spark-submit,--deploy-mode,cluster,--master,yarn,--class,org.apache.spark.examples.SparkPi,s3://support.elasticmapreduce/spark/1.2.0/spark-examples-1.2.0-hadoop2.4.0.jar,10],ActionOnFailure=CONTINUE
```


## Add an EMR step to the cluster to execute Spark's JavaWordCount example while modifying driver and executor properties via spark-submit and EMR script execution with the spark-examples jar located in S3

```
aws emr add-steps --cluster-id <YOUR_CLUSTER_ID> --steps \
Name=JavaWordCount,Jar=s3://<REGION_OF_CLUSTER>.elasticmapreduce/libs/script-runner/script-runner.jar,Args=[/home/hadoop/spark/bin/spark-submit,--deploy-mode,cluster,--master,yarn,--driver-memory,1G,--executor-memory,1G,--num-executors,4,--class,org.apache.spark.examples.JavaWordCount,s3://support.elasticmapreduce/spark/1.2.0/spark-examples-1.2.0-hadoop2.4.0.jar,s3://support.elasticmapreduce/spark/examples/wordcountdata],ActionOnFailure=CONTINUE
```


Now view the status of the steps via EMR console or AWS CLI. Once done, be sure to terminate cluster via console or AWS CLI.

## Terminate cluster

```
aws emr terminate-clusters --cluster-id <YOUR_CLUSTER_ID>
```


The above examples logged the step output and YARN application and container output of stdout/stderr/syslog to the logging path specified at creation of s3://<YOUR_BUCKET>/<YOUR_PATH>/<YOUR_CLUSTER_ID>. (Reference http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-manage-view-web-log-files.html)


## Example of an all-in-one AWS CLI command that creates the cluster, runs a Spark application, then terminates

```
aws emr create-cluster --name EMR-Spark-Step-Example --ami-version 3.7 \
--instance-type=m3.2xlarge --instance-count 3 --applications Name=Hive  \
--use-default-roles --ec2-attributes KeyName=<YOUR_EC2_KEY_NAME>,SubnetId=<YOUR_VPC_SUBNET_ID> \
--log-uri s3://<YOUR_BUCKET>/<YOUR_PATH> \
--bootstrap-action Name=Spark,Path=s3://support.elasticmapreduce/spark/install-spark,Args=[-x] \
--steps Name=SparkPi,Jar=s3://<REGION_OF_CLUSTER>.elasticmapreduce/libs/script-runner/script-runner.jar,Args=[/home/hadoop/spark/bin/spark-submit,--deploy-mode,cluster,--master,yarn,--class,org.apache.spark.examples.SparkPi,s3://support.elasticmapreduce/spark/1.2.0/spark-examples-1.2.0-hadoop2.4.0.jar,10] \
--auto-terminate
```



