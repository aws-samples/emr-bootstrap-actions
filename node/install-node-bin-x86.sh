# Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

#!/bin/bash

cwd=`pwd`

wget http://nodejs.org/dist/v0.10.8/node-v0.10.8-linux-x86.tar.gz
gzip -d node-v0.10.8-linux-x86.tar.gz && tar -xvf node-v0.10.8-linux-x86.tar

echo "export PATH=$cwd/node-v0.10.8-linux-x86/bin:$PATH" >> ~/.bashrc