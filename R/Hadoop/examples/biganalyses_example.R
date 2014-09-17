# R (r-project.org) example 
# for analysing "Daily Global Weather Measurements dataset" (https://aws.amazon.com/datasets/2759 
# with R and plyrmr package and RStudio server on AWS EMR
#
# please be aware of the coresponding bootstraping script
#
# schmidbe@amazon.de
# 12. September 2014
##############################

# set R environments
Sys.setenv(HADOOP_CMD="/home/hadoop/bin/hadoop")
Sys.setenv(HADOOP_STREAMING="/home/hadoop/contrib/streaming/hadoop-streaming.jar")
Sys.setenv(JAVA_HOME="/usr/java/latest/jre")

# load librarys
library(rmr2)
library(rhdfs)
library(plyrmr)

# initiate rhdfs package
hdfs.init()

# a very simple plyrmr example to test the package
library(plyrmr)
# running code localy
bind.cols(mtcars, carb.per.cyl = carb/cyl)
# same code on Hadoop cluster
to.dfs(mtcars, output="/tmp/mtcars")
bind.cols(input("/tmp/mtcars"), carb.per.cyl = carb/cyl)
# reading input data back from hdfs - example to learn reading hdfs files
res <- from.dfs("/tmp/mtcars")

# find and check the gsod data on hdfs
hdfs.ls("/tmp/data/gsod")
hdfs.ls("/tmp/data/gsod/1957")
hdfs.ls("/tmp/data/gsod/1957/480570-99999-1957.op")
hdfs.cat("/tmp/data/gsod/1957/480570-99999-1957.op")

# some test read to ensure the right input format
res <- from.dfs("/tmp/data/gsod/1957/480570-99999-1957.op", 
                format = make.input.format("csv"))  	
head(res$val)

# calculate the average temp per station and month
# in this case we use the (new) unix like pipe operator from the dplyr and plyrmr package
# 1) read data
# 2) group by station
# 3) groub by month
# 4) calculate mean over groups
# Hadoop job will be started as soon as you use the "res" object the first time.
# here I use the small trick as.data.frame() to start the Hadoop job
res <- input("/tmp/data/gsod/1957/480570-99999-1957.op", 
             format = make.input.format("csv")) %|%
  group(V1) %|% group(substr(V3,1,6)) %|%
  transmute(mean.temp = mean(V4))
temp <- as.data.frame(res)


# the first example was only for one file in 1957
# now run it for all data in 1957
#res <- input("/tmp/data/gsod/1957", 
#             format = make.input.format("csv")) %|%
#  group(V1) %|% group(substr(V3,1,6)) %|%
#  transmute(mean.temp = mean(V4))

# now run it for all data in 195*
#res <- input("/tmp/data/gsod/195*", 
#             format = make.input.format("csv")) %|%
#  group(V1) %|% group(substr(V3,1,6)) %|%
#  transmute(mean.temp = mean(V4))

# check the result and name it correctly
head(temp)	
dim(temp)
temp[,2] <- as.integer(temp[,2])
colnames(temp) <- c("station", "yearMonth", "mean.temp")

# average monthes per station
mean( table(temp[,1]) )
# average of stations per month
mean( table(temp[,2]) )

# and create a nice plot with ggplot2
install.packages("ggplot2")
library(ggplot2)

ggplot(temp, aes(yearMonth, mean.temp, group=station, colour=station)) + 
  geom_line() +
  labs(x="Date", y="Temperature in F", title="Changes in Average Temperature") +
  theme(legend.position = "none") +
  scale_x_continuous(breaks=195701:195712) +
  stat_summary(fun.y = mean, colour = "red", geom="line", aes(group = 1)) 


