#!/bin/bash

is_aml=`uname -r | grep amzn1.x86_64 | wc -l`

if [ is_aml=1 ]; then
	# install node through yum
	sudo yum -y install nodejs npm --enablerepo=epel

	# install nvm and update to Node v 0.12
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
	. ~/.nvm/nvm.sh
	nvm install 0.12
	nvm alias default 0.12
else
	echo "Unsupported OS"
	exit -1
fi