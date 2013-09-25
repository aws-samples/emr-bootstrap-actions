Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You
may not use this file except in compliance with the License. A copy of
the License is located at

     http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
ANY KIND, either express or implied. See the License for the specific
language governing permissions and limitations under the License.


A Bootstrap Action is a shell script stored in Amazon S3 that Amazon EMR executes on every node of your cluster.  Bootstrap actions execute as the Hadoop user by default; they execute with root privileges if you use sudo.  From the EMR Command Line Interface you can reference a Bootstrap Action as follows:

--bootstrap-action "s3://myawsbucket/FileName" --args "arg1,arg2"

For more information about EMR Bootstrap actions, see http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-plan-bootstrap.html

The code samples in this repository are meant to illustrate how to setup popular applications on Amazon EMR using bootstrap actions.
They are not meant to be run in production and all users should carefully inspect code samples before running them.

Use at your own risk.