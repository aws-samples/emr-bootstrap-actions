#!/bin/bash
set -x
# Basic bash script to take key=value pairs on the command line and replace/add to config file
# doesn't handle escaped arguments and treats each space as a new argument
CONFIG_FILE=/home/hadoop/spark/conf/spark-defaults.conf

#backup file
cp -v $CONFIG_FILE $CONFIG_FILE.prev

#loop through arguments and change in config file
for var in "$@"
do
	echo "$var"
	TARGET_KEY="${var%=*}"
	NEW_VALUE="${var#*=}"
	sed -c -i "s/^$TARGET_KEY\b.*/\#\0/" $CONFIG_FILE
	if [ -n "$NEW_VALUE" ]
        then
		echo "$TARGET_KEY	$NEW_VALUE" >> $CONFIG_FILE
	fi
done

#write out new file contents
cat $CONFIG_FILE

exit 0
