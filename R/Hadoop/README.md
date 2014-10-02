Running open-source R on EMR with Rhadoop packages and RStudio
=====================

More documentation you can find at the following AWS Big Data Blog post (http://blogs.aws.amazon.com/bigdata/post/Tx37RSKRFDQNTSL/Statistical-Analysis-with-Open-Source-R-and-RStudio-on-Amazon-EMR)

Please copy all files to a S3 bucket.

With the following command you can start an EMR cluster with R, Rhadoop and RStudio installed. Please replace <YOUR-X> with your data:

``aws emr create-cluster --ami-version 3.2.1 --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m1.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m1.large --bootstrap-actions  Path=s3://<YOUR-Bucket>/emR_bootstrap.sh,Name=CustomAction,Args=[--rstudio,--rhdfs,--plyrmr,--rexamples] --steps Name=HDFS_tmp_permission,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=s3://<YOUR-BUCKET>/hdfs_permission.sh  --region us-east-1 --ec2-attributes KeyName=<YOUR-SSH-KEY> --no-auto-terminate --name emR-example --log-uri s3://<YOUR-LOG-BUCKET>/logs```


File documentation
=====================
* emR_bootstrap.sh - installes RStudio and RHadoop packages depending on the provided arguments on all EMR instances
  * --rstudio - installs rstudio-server default false
  * --rexamples - adds R examples to the user home dir, default false
  * --rhdfs - installs rhdfs package, default false
  * --plyrmr - installs plyrmr package, default false
  * --updater - installs latest R version, default false
  * --user - sets user for rstudio, default "rstudio"
  * --user-pw - sets user-pw for user USER, default "rstudio"
  * --rstudio-port - sets rstudio port, defaul 80
* hdfs_permission.sh - fixes /tmp permission in hdfs to provide tmp storage for R streaming jobs

* rmr2_ecample.R - simple example for mapReduce jobs with R
* biganalyses_example.R - bigger script with some bigger analyses using plyrmr package
* change_pw.R - simple script to change unix (rstudio user) password from R session
