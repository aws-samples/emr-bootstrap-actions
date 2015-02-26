Presto 0.95 With Java 1.8
==========================
This Bootstrap Action will install Java 1.8 and install and configure Presto 0.95 to work with EMR.

###Bootstrap Location
s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/install-presto

###Usage
The Bootstrap Action takes these optional arguments. 
```
Usage: presto-install [OPTIONS]
    -d [ Home Directory ],           Ex : /home/hadoop/.versions/presto-server-0.95/ )
        --home-dir
    -p [ Hive Metastore Port ],      Ex : 9083 )
        --hive-port
    -m [ Memory Specified in Java -Xmx Formatting ],
        --MaxMemory                  Ex : 512M )
    -n [ Nursery Memory Specified in Java -Xmn Formatting ],
        --NurseryMem                 Ex : 512M )
    -v [ Version of Presto to Install. For Future Use, not currently active ],
        --version                    Ex : 0.95 )
    -h, --help                       Display this message 
```

###Changes
- 26/02/2015 : Added Support for AWS EC2 Roles 
- 26/02/2015 : Backported S3PrestoFileSystem Patches from 0.96 [ Development ]

###Examples
Using the AWS CLI tools you can launch a cluster with the following command: 
aws emr create-cluster --name="PRESTO-default" --ami-version=3.2.3 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/install-presto"