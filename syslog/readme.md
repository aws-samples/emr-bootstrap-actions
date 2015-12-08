# Bootstrap - Syslog Setup

Elastic MapReduce offers an array of logging mechanisms that end up on HDFS and/or S3. In some cases, especially during development sprints, one needs access to real-time logging. This [bootstrap](http://docs.aws.amazon.com/ElasticMapReduce/latest/ManagementGuide/emr-plan-bootstrap.html) action configures rsyslogd on the Master, allowing both TCP and UDP connections from Task and Core instance groups. It defines the forwarding of a single facility, writing to configurable log location on the Master node. For performance purposes, the default log location is on the in-memory file store, `/dev/shm/emr.log`. If a S3 location is provided, or the cluster has been started with debug enabled, log files are compressed and upload once the max size (1G) is reached, or the cluster is terminated. The -s option overrides the clusters `Log URI` if set. 

## Usage 

    USAGE: ./syslog-setup.sh -options 

    OPTIONS                     DESCRIPTION                      
 
     OPTIONAL
     -s <s3path>                S3 path for logfile upload. i.e. <bucket>/logs
     -f <facility>              Facility for EMR syslog traffic. Default:local0 
     -l <logfile>               EMR logfile. Default:/dev/shm/emr.log

    FLAGS
     -D                         Enable debug mode
     -V                         Print version
     -h                         Print usage
     -u                         Enable udp mode

## Testing

Ssh into the Master node and tail `/dev/shm/emr.log`. Ssh into ANY Core|Task node and send a message on facility local0. Verify the message appears in the _emr.log_ file on the NameNode. 

    ## Master 
    $ sudo tail -f /dev/shm/emr.log
    
    ## Any Core|Task node
    $ logger -p local0.info "Go Bears"
    
    ## Output on Master
    Jan  2 23:47:41 ip-172-31-38-61 hadoop: Go Bears

    ## From Master, force S3 log file upload (if configured)
    $ sudo /usr/sbin/logrotate -f /etc/logrotate.d/emr



