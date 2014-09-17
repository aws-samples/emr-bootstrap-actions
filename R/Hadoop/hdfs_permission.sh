#!/bin/bash

# AWS EMR step script 
# for changing HDFS /tmp permission
#
# tested with AMI 3.1.1 (hadoop 2.4.0)
#
# schmidbe@amazon.de
# 26. August 2014
##############################

# change HDFS /tmp permissions to r+w everyone
# this is required for R tmp data in hadoop streaming jobs
hadoop fs -chmod -R 777 /tmp