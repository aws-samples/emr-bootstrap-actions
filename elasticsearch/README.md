Quickstart Guide:

1) To launch an EMR cluster with Elasticsearch installed, you can use the Amazon EMR CLI from the command line:
(http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-cli-install.html)

./elastic-mapreduce --create --name TestElasticSearch --alive --key-pair your-key \
--ami-version 3.2.0 \
--num-instances 3 \
--instance-type m1.medium \
--bootstrap-action s3://your-bucket/elasticsearch_install.rb \
--bootstrap-name InstallElasticSearch

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

