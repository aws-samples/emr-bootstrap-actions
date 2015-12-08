# Bootstrap - SaltStack Setup

In many cases, remote execution can be a useful tool in clustered systems. EMR supports this functionality through a custom jar step [EMR 3.X](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-hadoop-script.html) / [EMR 4.X](http://docs.aws.amazon.com/ElasticMapReduce/latest/ReleaseGuide/emr-4.0.0/emr-hadoop-script.html), which can be comberson and does not easily support real-time filtering of stdout. This bootstrap action provides a light weight remote execution engine by installing and configuring [SaltStack](http://www.saltstack.com/). Available in the Amazon Linux epel, the _salt master_ is installed on the Master node, allowing open minion connections from all Core|Task instances. 

## Usage 

    USAGE: ./salt-setup.sh -options 

    OPTIONS                     DESCRIPTION                      
 
     OPTIONAL
     -l <loglevel>              See docs.saltstack.com for valid levels. Default:
                                info
     -f <facility>              See man syslog.h for valid facilities. Default:
                                LOG_LOCAL0
 
     FLAGS
     -D                         Enable debug mode
     -V                         Print version
     -h                         Print usage

## Testing

Ssh into the namenode, and run the salt test.ping command to see registered minions. See [](http://docs.saltstack.com/) for a list of all supported commands and modules. 

    ## Test connected nodes
    $ sudo salt '*' test.ping
    ip-10-20-128-250.us-west-2.compute.internal:
        True
    ip-10-120-202-205.us-west-2.compute.internal:
        True
    ip-10-120-7-56.us-west-2.compute.internal:
        True

    ## List java proc_nodemanager process on a single node 
    $ sudo salt 'ip-10-120-7-56.us-west-2.compute.internal' cmd.run 'ps ax | grep \[p\]roc_nodemanager
    3361 ?        Sl     1:41 /usr/lib/jvm/java-openjdk/bin/java -Dproc_nodemanager -Xmx2048m -XX:OnOutOfMemoryError=kill -9 %p -XX:OnOutOfMemoryError=kill -9 %p -server -Dhadoop.log.dir=/var/log/hadoop-yarn ...

    ## Distribute file
    $ echo 'go bears' | sudo tee /srv/salt/bar
    $ sudo salt '*' cp.get_file salt://bar /tmp/foo/bar makedirs=True
    ip-10-20-128-250.us-west-2.compute.internal:
        /tmp/foo/bar
    ip-10-120-7-56.us-west-2.compute.internal:
        /tmp/foo/bar
    ip-10-120-202-205.us-west-2.compute.internal:
        /tmp/foo/bar
    $ sudo salt '*' cmd.run 'cat /tmp/foo/bar'
    ip-10-20-128-250.us-west-2.compute.internal:
        go bears
    ip-10-120-202-205.us-west-2.compute.internal:
        go bears
    ip-10-120-7-56.us-west-2.compute.internal:
        go bears


    


