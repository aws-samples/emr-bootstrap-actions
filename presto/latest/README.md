Latest Presto With Java 1.8
==========================
This Bootstrap Action will install Java 1.8 and install and configure Presto to work with EMR.  
You can specify a version of presto supported by the BA, or specify your own compiled version.

###Bootstrap Location
s3://support.elasticmapreduce/bootstrap-actions/presto/runnable/install-presto

###Usage
The Bootstrap Action takes these optional arguments. 
```
Usage: presto-install [OPTIONS]
    -d [ Home Directory ],           Ex : /home/hadoop/.versions/presto-server-0.95/ )
        --home-dir
    -p [ Hive Metastore Port ],      Ex : 9083 )
        --hive-port
    -m [ Memory (in MB) Specified in Java -Xmx Formatting ],
        --MaxMemory                  Ex : 512 )
    -n [ Nursery Memory (in MB) Specified in Java -Xmn Formatting ],
        --NurseryMem                 Ex : 512 )
    -v [ Version of Presto to Install. See README for supported versions ],
        --version                    Ex : 0.95 )
    -b [ Location of Self Compiled Binary of Presto. See README for details on what package structure must look like. ],
        --binary                     Ex : s3://mybucket/compiled/presto-compiled.tar.gz
    -c [ Install Presto-CLI. By default set to true ],
        --install-cli                Ex : false
    -j [ Location of custom CLI jar (implies -c option). By default, uses CLI of version set with -v ],
        --cli-jar                    Ex : s3://mybucket/presto-cli.jar
    -M [ Location of Already Running Hive MetaStore. This will stop the BA from launching the Hive MetaStore Service on the Master Instance ],
        --metastore-uri              Ex : thrift://192.168.0.1:9083
    -h, --help                       Display this message
```

###Requirements
This BA requires that you also install Hive 13 on your cluster as it uses Hive as the default catalog.  
Only tested against AMI 3.3.2 >

###Changes
- 09/06/2015 : Added custom CLI jar support. Changed support for custom binary: No need to repackage, just download from Prestodb.io and upload to S3. (Also typos and documentation corrections)
- 07/04/2015 : Added support to specify a Remote MetaStore Service
- 31/03/2015 : Added Support for Selective CLI installation and to specify your own compiled Presto Binary
- 26/02/2015 : Added Support for AWS EC2 Roles 
- 26/02/2015 : Backported S3PrestoFileSystem Patches from 0.96 [ Development ]

###Future Improvememnts
- Pass config file properties as arguments
- [JSON tuple generation](https://github.com/facebook/presto/pull/1724)
- [Foreground metastore refresh](https://github.com/facebook/presto/pull/1744)
- [Handling s3 Socket Timeout](https://github.com/facebook/presto/pull/1478)

###Supported Versions
 - 0.99
 - 0.95

###Examples
Using the AWS CLI tools you can launch a cluster with the following command: 
####Default Options
```
aws emr create-cluster --name="PRESTO" --ami-version=3.3.2 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/runnable/install-presto"
```

####Optional Params
```
aws emr create-cluster --name="PRESTO" --ami-version=3.3.2 --applications Name=hive --ec2-attributes KeyName=[KEY_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m3.xlarge --bootstrap-action Name="install presto",Path="s3://support.elasticmapreduce/bootstrap-actions/presto/runnable/install-presto",Args="[-p,8989,-m,1024,-n,128]"
```

###Running Queries
After cluster launch is successfull, ssh into the master node   
Create a new table in HIVE using the HIVE CLI
```
#> hive
CREATE EXTERNAL TABLE test(name string, surname string, emails string, country string, ip string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION "s3://support.elasticmapreduce/bootstrap-actions/presto/0.95/Query_Sample/";

#> presto-cli --catalog hive
show tables; 
SELECT name,COUNT(name) FROM test GROUP BY name;
```

###Build your own Binary
We have added the ability for you to compile your own version (or download a pre-compiled version) of Presto and download it from S3. 

In order for the installation to be successful the binary must be compressed into a .tar.gz file with the presto-server-0.xyz directory at the root, **unlike previous version of this script**.

In other words, the tarball **must** have a folder within it, so the tar can be extracted into /home/hadoop/.versions/presto-server-0.xyz/. **This has changed since last version**.

Once extraction is completed all the relevant symlinks will be added to make the folder accessible from /home/hadoop/presto-server/   


