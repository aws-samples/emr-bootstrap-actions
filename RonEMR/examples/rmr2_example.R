# R (r-project.org) example 
# for running R with rmr2 package and RStudio server on AWS EMR
# please be aware of the coresponding bootstraping script
#
# schmidbe@amazon.de
# 31. July 2014
##############################

# set environments
Sys.setenv(HADOOP_CMD="/home/hadoop/bin/hadoop")
Sys.setenv(HADOOP_STREAMING="/home/hadoop/contrib/streaming/hadoop-streaming.jar")
Sys.setenv(JAVA_HOME="/usr/java/latest/jre")

# load library
library(rmr2)

# run locally - good for debuging
# rmr.options(backend="local")

# now run it on the AWS EMR Hadoop Cluster
rmr.options(backend="hadoop")

# write some data to hdfs
small.ints <- to.dfs(keyval(1, 1:10000))

# a simple mapReduce job (no reduce function)
out <- mapreduce(
  input = small.ints, 
  map = function(k, v) cbind(v, v^2))
res <- from.dfs(out)

# no map and no reduce function
out <- mapreduce(
  input = small.ints)
res <- from.dfs(out)
# please be aware, dfs objects will be a list with two fielfs: key and val
res$key
res$val

# mapreduce job with map and reduce function
out <- mapreduce(
  input = small.ints, 
  map = function(k, v){
      keyval(ifelse(v > 10, 0, 1), v)
  },
  reduce = function(k,v){
    keyval(k, length(v))
  }
)
res <- from.dfs(out)
head(res$key)
head(res$val)
