Install and configure SaltStack
===============================
This Bootstrap Action will install and configure [SaltStack](https://docs.saltstack.com/en/2015.5/) on the EMR nodes. It will add some
useful configurations in the form of [grains](https://docs.saltstack.com/en/2015.5/topics/targeting/grains.html) (like 'Facts' in other simliar software) and [nodegroups](https://docs.saltstack.com/en/2015.5/topics/targeting/nodegroups.html).


## Usage ##

There are basically three modes. If no argument given, **-I** is assumed.

     MODES:
      -I (DEFAULT)              Independent mode. EMR Master node is the salt
                                master, slave nodes (task, core) are minions. If
                                no argument is used, this mode will be deployed.

      -E <master-hostname/ip>   External master mode. Register all EMR nodes as
                                minions on the external master specified

      -S <master-hostname/ip>   Syndicated mode. Like -I but also syndicates EMR
                                master node to the specified external master

    Important: If the external master (-E/-S modes) is not reachable, the bootstrap
               action will fail.

     OPTIONS
      -l <loglevel>             See docs.saltstack.com for valid levels. Default:
                                info
      -f <facility>             See man syslog.h for valid facilities. Default:
                                LOG_LOCAL0

     FLAGS
      -d                         Enable debug mode
      -V                         Print version
      -h                         Print usage


## SaltStack on EMR: remote command execution cheatsheet ##

 __NOTE:__ all the commands will run on the minions as root. The commands need to be executed from a salt master, this would be:

  - Independent mode: EMR master node.

  - External mode: external master

  - Syndicated mode: EMR master node (will contact all nodes in the cluster) or external master (will contact all nodes in all clusters).

Example:

- Check connectivity to all registered nodes:

        sudo salt '\*' test.ping

We can leverage the predefined configuration via _grains_ and _nodegroups_.


### Examples using nodegroups ###

- Execute command (for example, __whoami__) on core nodes:

        sudo salt -N core cmd.run whoami

- Execute script located in S3 on task nodes:

        sudo salt -N task cmd.script s3://bucket/command

- Copy file from salt master to every EMR slave node (core, task):

        sudo cp /path/to/myfile /srv/salt/
        sudo salt -N slave cp.get_file salt://myfile /path/to/myfile makedirs=True


### Examples using grains ###

- Execute script /srv/salt/myscript from master on all nodes in instance group ig-FFFFFFFFFFFF:

        sudo salt -G 'emr:instance_group_id:ig-FFFFFFFFFFFF' cmd.script salt://myscript

- Check status of the nodemanager service on every c3.2xlarge:

        sudo salt -G 'instance_type:c3.2xlarge' service.status hadoop-yarn-nodemanager

- Examples useful in external or syndicated mode:
    - Check uptime of every EMR master node on every cluster with release 4.7.2:

            sudo salt -C 'G@emr:version:4.7.2 and G@emr:instance_role:master' status.uptime

    - Execute script on all nodes of a particular cluster-id (managed by external SaltStack master):

            sudo salt -G 'emr:job_flow_id:j-FFFFFFFFFFFFF' cmd.run myscript


## Grains and nodegroups provided by this Bootstrap action ##

Each instance has its grains, they are intended to be static (or semi-static) data that gives information about the underlying system.

    emr:
        instance_group_id: ig-XXXXXXXXXXXXX
        instance_group_name: Arbitrary name of the instance group (user given)
        instance_role: master/core/task
        cluster_name: Arbitrary name of the cluster (user given)
        job_flow_id: j-FFFFFFFFFFFFF
        type: ami (3.11 or less)/bigtop (4.0 onwards)
        version: 3.11 or 4.7.2 or 5.0.0, etc
    instance_type: c3.xlarge (or whatever)
    instance_id: i-XXXXXXXX

The nodegroups are defined based on grains rules:

    nodegroups:
      core: 'G@emr:instance_role:Core'
      master: 'G@emr:instance_role:Master'
      task: 'G@emr:instance_role:Task'
      slave: 'G@emr:instance_role:Core or G@emr:instance_role:Task'


## Known issues ##

When running in syndicated mode, sometimes the minions fail to unregister from the master of masters when they are shutdown (such as after a resize of a instance group). Most people would probably use the default mode which doesn't exhibit this problem. The script 'salt_clean.sh' can be run in the master of masters (as root user) to clean the "zombie" unregistered minions.


## Brief introduction to SaltStack ##

[SaltStack](https://docs.saltstack.com/en/2015.5/) is an open source tool for automation and infrastructure management (such as Chef or Puppet). It started as a remote execution engine, it's based on ZeroMQ.

What's the benefit of this? Among others:

- Fast parallel remote command execution in every node of the cluster, or a selection of them.
- Scales much better to large number of nodes than SSH-based solutions.
- Easy way to change configurations on running EMR clusters.
- Possibility to manage several clusters from a central location.
- .. many more..

In SaltStack lingo, the master sends commands or configurations to the minions (slaves). This bootstrap action by default installs and configures the SaltStack master in the EMR master node and all the rest of the nodes get installed and configured as minions, and they autoregister with the master.

Optionally, the master can also be registered as minion, so the commands could be run on the whole cluster. Alternatively, all the EMR nodes (master and the rest) can be minions and register to an external master (an EC2 instance for example). This enables control from that EC2 instance to several clusters.

The bootstrap also configures some SaltStack [grains](https://docs.saltstack.com/en/2015.5/topics/targeting/grains.html) and [nodegroups](https://docs.saltstack.com/en/2015.5/topics/targeting/nodegroups.html).


## Tested releases ##
Tested on EMR AMI 3.11 and releases 4.7.X and 5.0.0. It should work on any 4.X, 5.X and probably on most 3.X.
