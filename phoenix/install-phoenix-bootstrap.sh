#!/bin/bash
set -e -x

# Usage:
#  --download-location - Base URL to find the Phoenix files, default http://s3.amazonaws.com/elasticmapreduce/bootstrap-actions/phoenix/2.1.2/
#  --phoenix-server - Phoenix Server file that will be copied to the Hbase Lib folder on all servers, default is phoenix-2.1.2.jar
#  --hbase-version - an alternative HBase Verison path to use, default /home/hadoop/.versions/<$HBASE_VERSION>/

PRODUCTNAME=phoenix
VERSION=2.1.2
DOWNLOAD_LOCATION=http://s3.amazonaws.com/elasticmapreduce/bootstrap-actions/$PRODUCTNAME/$VERSION/
HBASE_VERSION=hbase-0.94.7


INSTALL_DIR=/home/hadoop/.versions/$HBASE_VERSION/lib/
PHOENIX_SERVER=$PRODUCTNAME-$VERSION.jar
PHOENIX_PACKAGE_NAME=$PRODUCTNAME-$VERSION-install
PHOENIX_PACKAGE=$PHOENIX_PACKAGE_NAME.tar

INSTALL_ON_SLAVES=true


IS_MASTER=true
if [ -f /mnt/var/lib/info/instance.json ]
then
  IS_MASTER=`cat /mnt/var/lib/info/instance.json | tr -d '\n ' | sed -n 's|.*\"isMaster\":\([^,]*\).*|\1|p'`
  USER_HOME=/home/hadoop
fi


error_msg () # msg
{
  echo 1>&2 "Error: $1"
}

error_exit () # <msg> <cod>
{
  error_msg "$1"
  exit ${2:-1}
}

while [ $# -gt 0 ]
do
  case "$1" in
    --hbase-version)
      shift
      HBASE_VERSION=$1
      ;;
    --phoenix-server)
      shift
      PHOENIX_SERVER=$1
      ;;
    --phoenix-version)
      shift
      VERSION=$1
      ;;
    --slaves)
      INSTALL_ON_SLAVES=true
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


if [ "$IS_MASTER" = "false" && "$INSTALL_ON_SLAVES" = "false" ]; then
  exit 0
fi

# show error and exit if HBase version is not present
if ! [ -d $INSTALL_DIR ]; then
    error_exit "The specifie HBase path is not present: $1"
fi

# install the phoenix service jar on the all nodes
if [ -f $INSTALL_DIR$PHOENIX_SERVER ]; then
    rm $INSTALL_DIR$PHOENIX_SERVER
fi

wget -S -T 10 -t 5 $DOWNLOAD_LOCATION$PHOENIX_SERVER -P $INSTALL_DIR
chmod 755 $INSTALL_DIR$PHOENIX_SERVER


# also, if we're on the master node, get the full install package
if [ "$IS_MASTER" = "true" ]; then
    
    PHOENIX_DIR=$INSTALL_DIR$PRODUCTNAME/
    
    
    if [ -d $PHOENIX_DIR ]; then
        sudo rm -rf $PHOENIX_DIR
    fi
    wget -S -T 10 -t 5 $DOWNLOAD_LOCATION$PHOENIX_PACKAGE -P $INSTALL_DIR
    mkdir $PHOENIX_DIR
    tar xvf $INSTALL_DIR$PHOENIX_PACKAGE -C $PHOENIX_DIR
  
    chmod -R 755 $PHOENIX_DIR
    
    #remove downloaded jar
    rm $INSTALL_DIR$PHOENIX_PACKAGE
    #remove duplicate service jar to avoid confusion of which jar is installed 
    rm $PHOENIX_DIR$PRODUCTNAME-$VERSION.jar
    
fi


