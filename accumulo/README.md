Running open-source Accumulo on EMR
====================================

[Accumulo](https://accumulo.apache.org/) requires a [Zookeeper](http://zookeeper.apache.org/). It is installed as part of this bootstrap on master node.  You can refer to AWS Big data blog [Running Apache Accumulo on Amazon EMR](http://blogs.aws.amazon.com/bigdata/post/Tx15973X6QHUM43/Running-Apache-Accumulo-on-Amazon-EMR) for more information.

Creating cluster 
-----------------

```
aws emr create-cluster --name Accumulo --no-auto-terminate \
--bootstrap-actions Path=s3://elasticmapreduce.bootstrapactions/accumulo/1.6.1/install-accumulo_mj,Name=Install_Accumulo --ami-version 3.3.1 \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge 
InstanceGroupType=CORE,InstanceCount=2,InstanceType=m3.xlarge \
--ec2-attributes KeyName=<YOURKEY>
```


Running a sample
----------------

* SSH to master node

* Log into the accumulo shell:

`$ ~/accumulo/bin/accumulo shell -u username -p password`

* Create a table called 'hellotable':

`username@instance> createtable hellotable`

* Launch a Java program that inserts data with a BatchWriter:

```
~/accumulo/bin/accumulo
org.apache.accumulo.examples.simple.helloworld.InsertWithBatchWriter
-i instance -z 127.0.0.1 -u root -p secret -t hellotable
```
`ZK_IPADDR: IP address of a Master EMR node`

On the accumulo status page at the URL below (where 'master' is replaced with the name or IP of your accumulo master), you should see 50K entries
* To view the entries, use the shell to scan the table:

```sh
username@instance> table hellotable
username@instance hellotable> scan
```

* Or you can go to Accumulo UI (`http://[master-node]:50095`) 

