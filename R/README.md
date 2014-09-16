Running open-source R on EMR with Rhadoop packages and RStudio
=====================

More documentation you can find at the following AWS Big Data Blog post (link comming soon, planed for 2. October)

Please copy all files to a S3 bucket.

With the following command you can start an EMR cluster with R, Rhadoop and RStudio installed. Please replace <YOUR-X> with your data:

aws emr create-cluster --ami-version 3.1.1 --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m1.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m1.large --bootstrap-actions Path=s3://<YOUR-BUCKET>/emRStudio_bootstrap.sh,Name=CustomAction Path=s3://<YOUR-Bucket>/emR_bootstrap.sh,Name=CustomAction --steps Name=HDFS_tmp_permission,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://<YOUR-BUCKET>/hdfs_permission.sh  --region us-east-1 --ec2-attributes KeyName=<YOUR-SSH-KEY> --no-auto-terminate --name emR-example --log-uri s3://<YOUR-LOG-BUCKET>/logs


File documentation
=====================

RStudio_bootstrap.sh - installs RStudio on the master node on port 80. (user: rstudio, pw: rstudio)
emR_bootstrap.sh - installes rmr2, rhdfs and plyrmr packages on all EMR instances
hdfs_permission.sh - fixes /tmp permission in hdfs to provide tmp storage for R streaming jobs

rmr2_ecample.R - simple example for mapReduce jobs with R
biganalyses_example.R - bigger script with some bigger analyses using plyrmr package