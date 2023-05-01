EMR bootstrap actions
=====================

> **Warning**: This repository is undergoing updating and modernization – please bear with us.

A bootstrap action is a shell script stored in [Amazon S3](http://aws.amazon.com/s3/) that [Amazon EMR](https://aws.amazon.com/emr/) executes on every node of your cluster after boot and prior to application provisioning.
Bootstrap actions execute as the `hadoop` user by default; commands can be executed with root privileges if you use `sudo`.

From the [AWS CLI EMR `create-cluster` command](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/emr/create-cluster.html) you can reference a bootstrap action as follows:


```sh
--bootstrap-actions Name=action-name,Path=s3://myawsbucket/FileName,Args=arg1,arg2
```

For more information about EMR Bootstrap actions see [DeveloperGuide](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-bootstrap.html)

The code samples in this repository are meant to illustrate how to setup popular applications on Amazon EMR using bootstrap actions.
They are not meant to be run in production and all users should carefully inspect code samples before running them.

_Use at your own risk._
