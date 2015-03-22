
ElasticSearch on EMR
=====================

##Quickstart Guide:

Using AWS CLI (for more on AWS CLI, see http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html):

### 1) To launch an EMR cluster with Elasticsearch, Kibana and Logstash installed, use the following command.

```
aws emr create-cluster \
--ec2-attributes KeyName="<YOUR_EC2_KEYNAME>" \
--log-uri="<YOUR_LOGGING_BUCKET>" \
--bootstrap-action \
  Name="Install ElasticSearch",Path="s3://support.elasticmapreduce/bootstrap-actions/other/elasticsearch_install.rb" \
  Name="Installkibanaginx",Path="s3://support.elasticmapreduce/bootstrap-actions/other/kibananginx_install.rb" \
  Name="Installlogstash",Path="s3://support.elasticmapreduce/bootstrap-actions/other/logstash_install.rb" \
--ami-version=3.5.0 \
--instance-count=3 \
--instance-type=m1.medium \
--name="TestElasticSearch" 
```

### 2) To test Elasticsearch you can ssh into the master node: 
http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-connect-master-node-ssh.html

And try the following commands from the command line:

#### 2.1) To perform a health check: 

```
 $ curl -XGET 'http://localhost:9200/_cluster/health?pretty=true'
```
you will get an output like:

```
 {
  "cluster_name" : "j-1EGUTF5M4NAK9",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 22,
  "active_shards" : 44,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0
 }
```

#### 2.2) To Index some content: 

```
$ curl -XPUT "http://localhost:9200/movies/movie/1" -d' { "title": "The Godfather", "director": "Francis Ford Coppola", "year": 1972 }'
```

#### 2.3) Getting by Id: 

```
curl -XGET "http://localhost:9200/movies/movie/1"
```

#### 2.4) Deleting an index:

```
$ curl -XDELETE 'http://localhost:9200/twitter/'
```

#### 2.5) Querying all the content: 

```
$ curl -XGET 'http://localhost:9200/_search?pretty'
```

#### 2.6) To query all the nodes configured on the Elasticsearch cluster (JSON output):

```
$ curl -XGET 'http://localhost:9200/_nodes'
```

### 3) To check the indexed content on Kibana you can create a Windows instance on the same subnet as your Elasticsearch cluster. 

Once the instance is up and running, point the internet browser to the Master Node public DNS name (e.g. http://ec2-54-76-121-15.eu-west-1.compute.amazonaws.com).

For more information getting started with Kibana, here you will find a walk through: http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html

### 4) Logstash is installed on the master node of the cluster and can communicate with Elasticsearch installed on the same cluster.

#### 4.1)  To listen from stdin and write to stdin:

```
$ logstash/logstash-1.4.2/bin/logstash -e 'input { stdin { } } output { stdout {} }'
```
If you type something at the command prompt you will get Logstash output.


#### 4.2) Listening from stdin and writing to Elasticsearch:

```
$ logstash/logstash-1.4.2/bin/logstash -e 'input { stdin { } } output { elasticsearch { host => localhost protocol => "http" port => "9200" } }'
```
If you type something at the command prompt, the output will be indexed directly by Elasticsearch.

To check the output, open another session to the master node and run the following:

```
$ curl -XGET 'http://localhost:9200/_search?pretty'
```
