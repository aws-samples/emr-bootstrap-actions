Latest Version of Livy
==========================
This Bootstrap Action provisions your cluster with the latest version of Livy available on EMR. A list of all available versions of Livy can be found further down in this Readme. 

###Bootstrap Location

s3://ifc-jeffers/bootstrap-actions/livy


###Requirements

- AWS EMR AMI >= 3.11.0


###Changes

- 03/23/2017 : Initial Creation of BA with Livy 0.3.0

###Future Improvements


##Current latest version
```
livy version 0.3.0 (http://archive.cloudera.com/beta/livy/livy-server-0.3.0.zip)
```


###Examples

Using the AWS CLI tools you can launch a cluster with the following command: 


####Default Options

```
aws emr create-cluster --name="Spark with Livy 0.3.0" --ami-version=3.11.0 --applications Name=spark --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="Install Livy",Path="s3://ifc-jeffers/bootstrap-actions/livy"
```


