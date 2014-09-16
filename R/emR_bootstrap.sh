#/bin/bash

# AWS EMR bootstrap script 
# for running open-source R (www.r-project.org) with RHadoop packages on AWS EMR
#
# tested with AMI 3.1.1 (hadoop 2.4.0)
#
# schmidbe@amazon.de
# 26. August 2014
##############################

# set unix environment variables
sudo su << EOF1
echo '
export HADOOP_HOME=/home/hadoop
export HADOOP_CMD=/home/hadoop/bin/hadoop
export HADOOP_STREAMING=/home/hadoop/contrib/streaming/hadoop-streaming.jar
export JAVA_HOME=/usr/java/latest/jre
' >> /etc/profile
EOF1
sudo sh -c "source /etc/profile"

# fix hadoop tmp permission
sudo chmod 777 -R /mnt/var/lib/hadoop/tmp

# RCurl package needs curl-config unix package
sudo yum install -y curl-devel

# fix java binding - R and packages have to be compiled with the same java version as hadoop
sudo R CMD javareconf

# install required packages
sudo R --no-save << EOF
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava'),
repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
# here you can add your required packages which should be installed on ALL nodes
# install.packages(c(''), repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
EOF

# install rmr2 package
rm -rf RHadoop
mkdir RHadoop
cd RHadoop
curl --insecure -L https://raw.github.com/RevolutionAnalytics/rmr2/master/build/rmr2_3.1.2.tar.gz | tar zx
sudo R CMD INSTALL --byte-compile rmr2

# install rhdfs package
curl --insecure -L https://raw.github.com/RevolutionAnalytics/rhdfs/master/build/rhdfs_1.0.8.tar.gz | tar zx
sudo R CMD INSTALL --byte-compile --no-test-load rhdfs

# install plyrmr package
# This takes a lot of time. Please remove if not required.
sudo R --no-save << EOF
install.packages(c('dplyr', 'R.methodsS3', 'Hmisc'),
repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
EOF
curl --insecure -L https://raw.github.com/RevolutionAnalytics/plyrmr/master/build/plyrmr_0.3.0.tar.gz | tar zx
sudo R CMD INSTALL --byte-compile plyrmr 

