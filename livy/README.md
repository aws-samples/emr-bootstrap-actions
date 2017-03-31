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
aws emr create-cluster --release-label emr-5.4.0 --name="Spark with Livy 0.3.0" --service-role EMR_DefaultRole --applications Name=Spark Name=Ganglia --ec2-attributes KeyName=sandbox-emr-us-east-1,InstanceProfile=EMR_EC2_DefaultRole,SubnetIds=['subnet-0937f240'],EmrManagedMasterSecurityGroup=sg-d8ab72a7,EmrManagedSlaveSecurityGroup=sg-d7ab72a8 --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.large InstanceGroupType=CORE,InstanceCount=1,InstanceType=m4.large --bootstrap-action Name="Install Livy",Path="s3://ifc-jeffers/livy" --no-auto-terminate
```


