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
    -m [ Memory Specified in Mb ],
        --MaxMemory                  Ex : 512 )
    -n [ Nursery Memory Specified in Mb],
        --NurseryMem                 Ex : 512 )
    -v [ Version of Presto to Install. For Future Use, not currently active ],
        --version                    Ex : 0.95 )
    -h, --help                       Display this message 
```

###Requirements
This BA requires that you also install Hive 13 on your cluster as it uses Hive as the default catalog.  
Only tested against AMI 3.3.2 >

###Changes
- 26/02/2015 : Added Support for AWS EC2 Roles 
- 26/02/2015 : Backported S3PrestoFileSystem Patches from 0.96 [ Development ]

###Examples
Using the AWS CLI tools you can launch a cluster with the following command: 
####Default Options
```
aws emr create-cluster --name="PRESTO-0-95" --ami-version=3.2.3 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/install-presto"
```

####Optional Params
```
aws emr create-cluster --name="PRESTO-0-95" --ami-version=3.2.3 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/install-presto",Args="[-p,8989,-m,1024,-n,128]"
```

###Running Queries
After cluster launch is successfull, ssh into the master node   
Create a new table in HIVE using the HIVE CLI
```
#> hive
CREATE EXTERNAL TABLE test(id int, name string, surname string, emails string, country string, ip string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION "s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/Query_Sample/";

#> presto-cli --catalog hive
show tables; 
SELECT name,COUNT(name) FROM test GROUP BY name;
```


