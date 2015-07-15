Latest Version of Impala
==========================
This Bootstrap Action provisions your cluster with the latest version of Impala available on EMR. A list of all available versions of Impala can be found further down in this Readme. 

###Bootstrap Location
s3://support.elasticmapreduce/bootstrap-actions/impala/impala-install

###Requirements
- AWS EMR AMI >= 3.7.0

###Changes
- 10/06/2015 : Initial Creation of BA with Impala 2.2.0

###Future Improvements
- Support for custom remote metastore passed as argument
- Support for Custom Config Parameters
- Selective Impala Shell install on master

##Current latest version
```
impalad version 2.2.0-AMZ RELEASE (build b7f0e80e29971632ae1c422243d56c9ef65b8c5b)
Built on Sun, 07 Jun 2015 13:17:11 UTC
```

###Examples
Using the AWS CLI tools you can launch a cluster with the following command: 
####Default Options
```
aws emr create-cluster --name="Impala 2.2.0" --ami-version=3.7.0 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="Install Impala2",Path="s3://support.elasticmapreduce/bootstrap-actions/impala/impala-install"
```


