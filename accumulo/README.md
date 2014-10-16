Running open-source Accumulo on EMR
====================================

[Accumulo](https://accumulo.apache.org/) requires a [Zookeeper](http://zookeeper.apache.org/) as a prerequisite.

You can download one from [here](http://www.apache.org/dyn/closer.cgi/zookeeper/). Use a version greater than 3.3.X.
Follow the [instructions](http://zookeeper.apache.org/doc/r3.3.4/zookeeperStarted.html) for setting up Zookeeper.

Sample Zookeeper configuration
--------------------------------

```
syncLimit=5
tickTime=2000
initLimit=10
maxClientCnxns=100
clientPort=2181
```

Note: After you have Zookeeper installed, you must ensure that the Zookeeper security group allows traffic from your Amazon EMR master and slave node security groups.

Bootstrap action 
-----------------

```sh
BUCKET="<YOUR_BUCKET>"
REGION="<YOUR_REGION>"
KEYPAIR="<YOUR_KEYPAIR>"

aws emr create-cluster --name Accumulo \
--ami-version 3.2.1 \
--region $REGION \
--ec2-attributes KeyName=$KEYPAIR \
--no-auto-terminate \
--instance-groups \
InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge \
InstanceGroupType=CORE,InstanceCount=2,InstanceType=m3.xlarge \
--bootstrap-actions \
Name=Accumulo_bootstrap,\
Path="s3://elasticmapreduce/samples/accumulo/1.6.1/install-accumulo.sh",\
Args=["ZK_IPADDR,DBNAME,PASSWORD"] \
--log-uri "s3://BUCKETNAME/accumulo-logs/"
```

<i>Note: To launch Accumulo 1.4.2 use bootstrap at `s3://elasticmapreduce/samples/accumulo/1.4.2/install-accumulo.sh` </i>

Bootstrap action usage
---------------------

```
ZK_IPADDR: IP address of a Zookeeper node
DBNAME: Name of the database that you would like to create in Accumulo
PASSWORD: Accumulo DB password
BUCKETNAME: Your Amazon S3 bucket name where the Amazon EMR logs will be uploaded
```

Running a sample
----------------

* SSH to master node

* Log into the accumulo shell:

`$ ./bin/accumulo shell -u username -p password`

* Create a table called 'hellotable':

`username@instance> createtable hellotable`

* Launch a Java program that inserts data with a BatchWriter:

```sh
accumulo/bin/accumulo org.apache.accumulo.examples.simple.helloworld.InsertWithBatchWriter \
-i big -z ZK_IPADDR -u root -p 1234 -t hellotable
```
`ZK_IPADDR: IP address of a Zookeeper node`

* To view the entries, use the shell to scan the table:

```sh
username@instance> table hellotable
username@instance hellotable> scan
```

* Or you can go to Accumulo UI (`http://[master-node]:50095/status`) and check that it shows 50k entries.
