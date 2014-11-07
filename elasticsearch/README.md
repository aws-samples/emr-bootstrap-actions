Quickstart Guide:

1) To launch an EMR cluster with Elasticsearch and Kibana installed, you can use the Amazon EMR CLI from the command line:
(http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-cli-install.html)

./elastic-mapreduce --create --name TestElasticSearch --alive --key-pair your-key --ami-version 3.2.1 --num-instances 3 --instance-type m1.medium --bootstrap-action s3://your-bucket/elasticsearch_install.rb --bootstrap-name InstallElasticSearch --bootstrap-action s3://your-bucket/kibananginx_install.rb --bootstrap-name Installkibanaginx

2) To test Elasticsearch you can ssh into the master node:
http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-connect-master-node-ssh.html

And try the following commands from the command line:

2.1) To perform a health check:
curl -XGET 'http://localhost:9200/_cluster/health?pretty=true' 

you will get an output like:

{
  "cluster_name" : "j-XXXXXXXXXXXX",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0
}

2.2) To Index some content:
curl -XPUT "http://localhost:9200/movies/movie/1" -d' {
   "title": "The Godfather",
   "director": "Francis Ford Coppola",
   "year": 1972
}'

2.3) Getting by Id:
curl -XGET "http://localhost:9200/movies/movie/1"

2.4) Deleting an index'
curl -XDELETE 'http://localhost:9200/twitter/' 

2.5) Querying all the content:
curl -XGET http://localhost:9200/_search?pretty=true&q={'matchAll':{''}}

2.6) To query all the nodes configured on the Elasticsearch cluster (JSON output):
curl -XGET 'http://localhost:9200/_nodes' 

3) To check the indexed content on Kibana you can create a Windows instance on the same subnet as your Elasticsearch cluster. 
Once the instance is up and running, point the internet browser to the Master Node public DNS name (e.g. http://ec2-54-76-121-15.eu-west-1.compute.amazonaws.com). 

For more information getting started with Kibana, here you will find a walk through:
http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html
