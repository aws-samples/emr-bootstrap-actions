#/bin/bash

# AWS EMR bootstrap script 
# for installing open-source R (www.r-project.org) with RHadoop packages and RStudio on AWS EMR
#
# tested with AMI 3.2.1 (hadoop 2.4.0)
#
# schmidbe@amazon.de
# 24. September 2014
##############################


# Usage:
# --rstudio - installs rstudio-server default false
# --rexamples - adds R examples to the user home dir, default false
# --rhdfs - installs rhdfs package, default false
# --plyrmr - installs plyrmr package, default false
# --updateR - installs latest R version, default false
# --user - sets user for rstudio, default "rstudio"
# --user-pw - sets user-pw for user USER, default "rstudio"
# --rstudio-port - sets rstudio port, default 80




# check for master node
IS_MASTER=true
if [ -f /mnt/var/lib/info/instance.json ]
then
	IS_MASTER=`cat /mnt/var/lib/info/instance.json | tr -d '\n ' | sed -n 's|.*\"isMaster\":\([^,]*\).*|\1|p'`
fi

# error message
error_msg ()
{
	echo 1>&2 "Error: $1"
}

# get input parameters
RSTUDIO=false
REXAMPLES=false
USER="rstudio"
USERPW="rstudio"
PLYRMR=false
RHDFS=false
UPDATER=false
RSTUDIOPORT=80
while [ $# -gt 0 ]; do
	case "$1" in
		--rstudio)
			RSTUDIO=true
			;;
		--rexamples)
			REXAMPLES=true
			;;
		--plyrmr)
			PLYRMR=true
			;;
		--rhdfs)
			RHDFS=true
			;;
		--updateR)
			UPDATER=true
			;;
        --rstudio-port)
            shift
            RSTUDIOPORT=$1
            ;;
		--user)
		   shift
		   USER=$1
		   ;;
   		--user-pw)
   		   shift
   		   USERPW=$1
   		   ;;
		-*)
			# do not exit out, just note failure
			error_msg "unrecognized option: $1"
			;;
		*)
			break;
			;;
	esac
	shift
done

# install latest R version from AWS Repo
sudo yum update R-base -y

# create rstudio user on all machines
# we need a unix user with home directory and password and hadoop permission
sudo adduser $USER
sudo sh -c "echo '$USERPW' | passwd $USER --stdin"


# install rstudio
# only run if master node
if [ "$IS_MASTER" = true -a "$RSTUDIO" = true ]; then
  # install Rstudio server
  # please check and update for latest RStudio version
  wget http://download2.rstudio.org/rstudio-server-0.98.983-x86_64.rpm
  sudo yum install --nogpgcheck -y rstudio-server-0.98.983-x86_64.rpm
  
  # change port - 8787 will not work for many companies
  sudo sh -c "echo 'www-port=$RSTUDIOPORT' >> /etc/rstudio/rserver.conf"
  sudo rstudio-server restart
fi


# add examples to user
# only run if master node
if [ "$IS_MASTER" = true -a "$REXAMPLES" = true ]; then
  # and copy R example scripts to user's home dir amd set permission
  wget --no-check-certificate https://raw.githubusercontent.com/schmidb/emr-bootstrap-actions/master/R/Hadoop/examples/rmr2_example.R
  wget --no-check-certificate https://raw.githubusercontent.com/schmidb/emr-bootstrap-actions/master/R/Hadoop/examples/biganalyses_example.R
  wget --no-check-certificate https://raw.githubusercontent.com/schmidb/emr-bootstrap-actions/master/R/Hadoop/examples/change_pw.R
  sudo mv *.R /home/$USER/.
  sudo chown $USER:$USER -Rf /home/$USER
fi


# update to latest R version
if [ "$UPDATER" = true ]; then
	mkdir R-latest
	cd R-latest
	wget http://cran.r-project.org/src/base/R-latest.tar.gz
	tar -xzf R-latest.tar.gz
	sudo yum install -y gcc
	sudo yum install -y gcc-c++
	sudo yum install -y gcc-gfortran
	sudo yum install -y readline-devel
	cd R-3*
	./configure --with-x=no --with-readline=no --enable-R-profiling=no --enable-memory-profiling=no
	make
	sudo make install
    sudo su << EOF1
echo '
export PATH=$PATH:~/R-latest/bin/
' >> /etc/profile
EOF1
fi


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
if [ "$RHDFS" = true ]; then
	curl --insecure -L https://raw.github.com/RevolutionAnalytics/rhdfs/master/build/rhdfs_1.0.8.tar.gz | tar zx
	sudo R CMD INSTALL --byte-compile --no-test-load rhdfs
fi


# install plyrmr package
if [ "$PLYRMR" = true ]; then
	# This takes a lot of time. Please remove if not required.
	sudo R --no-save << EOF
install.packages(c('dplyr', 'R.methodsS3', 'Hmisc'),
repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
EOF
	curl --insecure -L https://raw.github.com/RevolutionAnalytics/plyrmr/master/build/plyrmr_0.3.0.tar.gz | tar zx
	sudo R CMD INSTALL --byte-compile plyrmr 
fi

