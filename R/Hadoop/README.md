Running open-source R on EMR with RHadoop packages and RStudio
=====================

More documentation you can find at the [AWS Big Data Blog post](http://blogs.aws.amazon.com/bigdata/post/Tx37RSKRFDQNTSL/Statistical-Analysis-with-Open-Source-R-and-RStudio-on-Amazon-EMR).

Please copy all files to a S3 bucket.

With the following command you can start an [EMR](http://aws.amazon.com/elasticmapreduce/) cluster with
[R](http://www.r-project.org/),
[RHadoop](https://github.com/RevolutionAnalytics/RHadoop/wiki)
and [RStudio](http://www.rstudio.com/) installed.
<br>Please replace `<YOUR-X>` with your data:

```sh
bucket="<YOUR_BUCKET>"
region="<YOUR_REGION>"
keypair="<YOUR_KEYPAIR>"

aws emr create-cluster --name emR-example \
--ami-version 3.2.1 \
--region $region \
--ec2-attributes KeyName=$keypair \
--no-auto-terminate \
--instance-groups \
InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m1.large \
InstanceGroupType=CORE,InstanceCount=2,InstanceType=m1.large \
--bootstrap-actions \
Name=emR_bootstrap,\
Path="s3://$bucket/emR_bootstrap.sh",\
Args=[--rstudio,--rhdfs,--plyrmr,--rexamples] \
--steps \
Name=HDFS_tmp_permission,\
Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",\
Args="s3://$bucket/hdfs_permission.sh"
```


File documentation
------------------
* `emR_bootstrap.sh` - installs RStudio and RHadoop packages
  depending on the provided arguments on all EMR instances
  * `--rstudio` - installs rstudio-server, default false
  * `--rexamples` - adds R examples to the user home directory, default false
  * `--rhdfs` - installs rhdfs package, default false
  * `--plyrmr` - installs plyrmr package, default false
  * `--updater` - installs latest R version, default false
  * `--user` - sets user for rstudio, default "rstudio"
  * `--user-pw` - sets user-pw for user USER, default "rstudio"
  * `--rstudio-port` - sets rstudio port, default 80
* `hdfs_permission.sh` - fixes `/tmp` permission in hdfs to provide temporary storage for R streaming jobs

* `rmr2_example.R` - simple example for mapReduce jobs with R
* `biganalyses_example.R` - bigger script with some bigger analyses using plyrmr package
* `change_pw.R` - simple script to change Unix (rstudio user) password from R session
