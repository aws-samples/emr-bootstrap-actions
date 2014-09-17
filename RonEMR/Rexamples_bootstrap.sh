#/bin/bash

# AWS EMR bootstrap script 
# for running open-source R (www.r-project.org) with RHadoop packages on AWS EMR
#
# tested with AMI 3.2.1 (hadoop 2.4.0)
#
# schmidbe@amazon.de
# 17. September 2014
##############################

# check for master node using security group name
secgroup=$(curl http://169.254.169.254/latest/meta-data/security-groups)

# only run if master node
if [ "$secgroup" == "ElasticMapReduce-master" ]
then
  
  # and copy R example scripts to user's home dir amd set permission
  wget --no-check-certificate https://github.com/schmidb/emr-bootstrap-actions/blob/master/RonEMR/examples/rmr2_example.R
  wget --no-check-certificate https://github.com/schmidb/emr-bootstrap-actions/blob/master/RonEMR/examples/biganalyses_example.R
  sudo mv *.R /home/rstudio/.
  sudo chown rstudio:rstudio -Rf /home/rstudio
fi