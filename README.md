Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You
may not use this file except in compliance with the License. A copy of
the License is located at

http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
ANY KIND, either express or implied. See the License for the specific
language governing permissions and limitations under the License.


EMR bootstrap actions
=====================

A bootstrap action is a shell script stored in [Amazon S3](http://aws.amazon.com/s3/) that [Amazon EMR](http://aws.amazon.com/elasticmapreduce/) executes on every node of your cluster.
Bootstrap actions execute as the `hadoop` user by default; they execute with root privileges if you use `sudo`.<br>From the [Ruby EMR Command Line Interface](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-cli-reference.html) you can reference a bootstrap action as follows:


```sh
--bootstrap-action "s3://myawsbucket/FileName" --args "arg1,arg2"
```

For more information about EMR Bootstrap actions see [DeveloperGuide](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-plan-bootstrap.html)

The code samples in this repository are meant to illustrate how to setup popular applications on Amazon EMR using bootstrap actions.
They are not meant to be run in production and all users should carefully inspect code samples before running them.

_Use at your own risk._
