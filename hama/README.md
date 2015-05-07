Hama on EMR
=====================

This script is a sample of installing and configuring Hama on EMR.

## Quick start guide

* Using AWS Command Line Interface(for more information, see http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
* Script : s3://hamacluster/install-hama.sh

### Arguments (optional)

    -u, --url 
          Hama release download URL. Only tarball file is possible.
          ex)
            -u http://apache.mirror.cdnetworks.com/hama/hama-{version}/hama-{version}.tar.gz
            --url s3://[your_bucket]/[path_to]/hama-{version}.tar.gz
    
    -c, --conf 
          Addtional properties for Hama configuration.(Space-separated delimiter)
          ex)
            -c "bsp.master.address=host1.mydomain.com:40000 hama.zookeeper.quorum=host1.mydomain.com,host2.mydomain.com"
   
    -e, --env 
          Set environment variables in hama-env.sh.(Space-separated delimiter)
          ex)
            -e "HAMA_LOG_DIR=[path_to_log_dir] HAMA_MANAGE_ZK=true"

### Example

#### 1. Launching a Hama cluster with default configuration.

We provide only AMI 3.7.0(hadoop 2.4.0) with default configuration. If you want to bootstrap hama for the other hadoop version, you would use hama to compile other hadoop version and then run -u(--url) argument before launching this script.

```
$ aws emr create-cluster     \
    --name="Test Cluster"    \
    --ami-version=3.7.0      \
    --no-auto-terminate      \
    --use-default-roles --ec2-attributes KeyName=[your keyname] \
    --applications Name=Ganglia \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=9,InstanceType=m3.xlarge \
    --bootstrap-action Name="Install Hama",Path=s3://hamacluster/install-hama.sh
```

#### 2. Launching a Hama cluster with additional configuration.

```
$ aws emr create-cluster     \
    --name="Test Cluster"  \
    --ami-version=3.7.0    \
    --no-auto-terminate    \
    --use-default-roles --ec2-attributes KeyName=[your keyname] \
    --applications Name=Ganglia \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=9,InstanceType=m3.xlarge \
    --bootstrap-action Name="Install Hama",Path=s3://hamacluster/install-hama.sh,Args=["-c","hama.graph.thread.pool.size=256 bsp.child.java.opts=-Xmx3072m","-e","HAMA_HOME=/home/hadoop/hama-0.7.0"]
```
