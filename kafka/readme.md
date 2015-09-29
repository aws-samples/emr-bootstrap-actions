Apache Kafka is publish-subscribe messaging system as a distributed commit log.

A single Kafka broker can handle hundreds of megabytes of reads and writes per second from thousands of clients.

It uses ZooKeeper so you need to first start a ZooKeeper server

Bootstrap action for EMR 3.x:
s3://support.elasticmapreduce/bootstrap-actions/other/kafka_install.rb

To launch a cluster with Kafka installed using CLI Tools use the following command:
aws emr create-cluster \ --ec2-attributes KeyName="<YOUR_EC2_KEYNAME>" \ --log-uri="<YOUR_LOGGING_BUCKET>" \ --bootstrap-action \ Name="Install Kafka",Path="s3://support.elasticmapreduce/bootstrap-actions/other/kafka_install.rb" \ --ami-version=3.9.0 \ --instance-count=3 \ --instance-type=m1.medium \ --name="TestKafka"

Basic commands for Kafka:

create topic (from master node):
./kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic test

list topics:
./kafka-topics.sh --zookeeper localhost:2181 --list

send a message (from master node):
./kafka-console-producer.sh --broker-list localhost:9092 --topic test

read messages from consumer (from slave node - change localhost by the master dns name):
kafka-console-consumer.sh --zookeeper localhost:2181 --topic test --from-beginning
