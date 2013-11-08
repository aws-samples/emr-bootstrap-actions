#!/bin/bash
set -e -x

# Usage:
#  --user-home - an alternative user to install into, default /home/hadoop
#  --tmpdir - an alternative temporary directory, default TMPDIR or /tmp if not set
#  --no-screen - do not install screen, screen is installed by default on the master as a convenience
#  --latest - url to text file referencing the latest version
#  --no-bash - do not update .bashrc
#  --gradle-ver - the version of name of gradel. defaults to "gradle-1.7"
#  --gradle-file - the packaged file extension of the file. defaults to "<-gradel-ver>all-zip" 
#  --gradle-bucket - the root site url or S3 bucket of the install file defaults to "http://services.gradle.org/distributions/"
#  --gradle-home - the directory that gradle will be install into. defaults to "/usr/share/"

CASCADING_COMP_REPO=https://github.com/AmazonEMR/cascading.compatibility.git
HADOOP_TEST_JAR=http://preprod.us-east-1.elasticmapreduce.testing.s3.amazonaws.com/libs/hadoop/hadoop-test-1.0.3.jar
GRADLE_VER=gradle-1.7
GRADLE_FILE=$GRADLE_VER-all.zip
GRADLE_BUCKET=http://services.gradle.org/distributions/
GRADLE_HOME=/usr/share/

LATEST=$GRADLE_BUCKET$GRADLE_FILE


case "`uname`" in
  Darwin)
    USER_HOME=/Users/$USER;;
  *)
    USER_HOME=/home/$USER;;
esac

INSTALL_ON_SLAVES=false
BASH_PROFILE=.bashrc
INSTALL_SCREEN=y
INSTALL_GIT=y
UPDATE_BASH=y

IS_MASTER=true
if [ -f /mnt/var/lib/info/instance.json ]
then
  IS_MASTER=`cat /mnt/var/lib/info/instance.json | tr -d '\n ' | sed -n 's|.*\"isMaster\":\([^,]*\).*|\1|p'`
  USER_HOME=/home/hadoop
fi

[ -z "$TMPDIR" ] && TMPDIR=/tmp/

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
    --latest)
      shift
      LATEST=$1
      ;;
    --user-home)
      shift
      USER_HOME=$1
      ;;
    --tmpdir)
      shift
      TMPDIR=$1
      ;;
    --no-screen)
      INSTALL_SCREEN=
      ;;
    --no-bash)
      UPDATE_BASH=
      ;;
    --slaves)
      INSTALL_ON_SLAVES=true
      ;;
    --gradle-ver)
      GRADLE_VER=
      ;;
    --gradle-file)
      GRADLE_FILE=
      ;;
    --gradle-bucket)
      GRADLE_BUCKET=
      ;;
    --gradle-home)
      GRADLE_HOME=
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

# fetch the install zip file
wget -S -T 10 -t 5 $LATEST -P $TMPDIR

sudo unzip -o /$TMPDIR$GRADLE_FILE -d $GRADLE_HOME

if [ -n "$UPDATE_BASH" ]; then
cat >> $USER_HOME/$BASH_PROFILE <<- EOF

# Amazon Elastic Map Reduce Gradle Bootstrap
export PATH=$GRADLE_HOME/$GRADLE_VER/bin:\$PATH

EOF
fi

if [ "$IS_MASTER" = "true" ]; then
  [ -n "$INSTALL_SCREEN" ] && sudo apt-get --force-yes install screen -y
fi

if [ "$IS_MASTER" = "true" ]; then
  [ -n "$INSTALL_GIT" ] && sudo apt-get --force-yes install git -y
fi

# clean up
sudo rm $TMPDIR$GRADLE_FILE

#pulldown hadoop-test.jar file
wget -S -T 10 -t 5 $HADOOP_TEST_JAR -P $USER_HOME/

if [ "$IS_MASTER" = "true" ]; then
  #pull down the cascading compatiblity repo
  CASCADING_COMP_DIR=$USER_HOME/cascading.compatibility
  mkdir $CASCADING_COMP_DIR
  git clone $CASCADING_COMP_REPO $CASCADING_COMP_DIR
  cd $CASCADING_COMP_DIR
  git checkout 2.2
  cd
fi
