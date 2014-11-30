Running Tajo on EMR:
======================
Tajo is supported on EMR through a bootstrap action. 
* s3 path : s3://

Bootstrap Action Arguments:
==========================

Usage: install-tajo.sh [OPTIONS]

    -t [TAJO_BINARY_TARBALL_URL]
       Ex : s3://[your_bucket]/[your_path]/tajo-{version}.tar.gz or http://apache.org/dyn/closer.cgi/tajo/tajo-{version}/tajo-{version}.tar.gz
    -c [TAJO_CONF_DIR_URL] 
       Ex : s3://[your_bucket]/[your_path]/conf
    -l [TAJO_THIRD_PARTY_LIB_DIR_URL]
       Ex : s3://[your_bucket]/[your_path]/lib
    -h
       Display help message
    -T [TEST_DIR]  
       Ex: /[your_local_test_dir]
    -H [TEST_HADOOP_HOME]
       Ex: /[your_local_test_hadoop_home]

위 모든 옵션은 선택사항이다. 특히 -T와 -H는 local pc에서 Test용으로 사용한다.


Sample Commands:
================

1. Default: 옵션이 전혀 없는 기본 설정이다. tajo_root_dir은 EMR의 HDFS를 사용한다.

    aws emr create-cluster --name="[CLUSTER_NAME]" --ami-version=3.3 --ec2-attributes KeyName=[KEY_FIAR_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge --bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh

2. Override Tajo Config and third party lib: -t, -c, -l을 사용한 설정이다. -c 는 Tajo 설정파일이 포함된 s3 디렉토리 경로로써 tajo_root_dir을 s3로 사용하려면 tajo-site.xml을 알맞게 수정하여 이 디렉토리에 넣어두어야 한다. -l은 외부 라이브러리를 Tajo가 사용하게 할 경우 이 라이브러리들 모아놓은 s3 디렉토리 경로로써 RDS(mysql)를 사용할 경우 mysql-connector.jar가 포함되어야 한다.   

    aws emr create-cluster --name="[CLUSTER_NAME]" --ami-version=3.3 --ec2-attributes KeyName=[KEY_FIAR_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge --bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh,Args=["-t","s3://[your_bucket]/tajo-0.9.0.tar.gz","-c","s3://[your_bucket]/conf","-l","s3://[your_bucket]/lib"]


Test:
================
install-tajo.sh 스크립트가 잘 작동하는지 Test하기 위한 설정은 -T, -H 옵션을 이용하는 것이다. 이것은 EMR이 아닌 자신의 local pc에서 동작한다. -T는 local에서 Test하기 위해 생성할 디렉토리 경로이다. 이 디렉토리에 hadoop,tajo가 설치될 것이다. -H는 local에 설치되어있는 hadoop_home이다. 테스트를 위해 이 hadoop_home을 복사할 것이다.
    
    ./install-EMR-tajo.sh -t /[your_local_binary_path]/tajo-0.9.0.tar.gz -T /[your_test_dir] -H /[your_test_hadoop_home] -c /[your_test_conf_dir]/conf -l /[your_test_lib_dir]/lib


Running with AWS RDS
====================
Tajo can also use RDS, but you will need to make sure you have an RDS instance running. And you will make tajo-catalog.xml.
##I'm going to update this section.
...
...
... 


Tajo Configuration:  
=====================
Tajo 설정 파일은 인스턴스 타입별로 template를 제공한다.


NOTES: 
=====
##I'm going to update this section.
...시큐리티 그룹 
...등등..


Sample Usage
============
##I'm going to update this section.
...tpc 테스트 
...워크벤치 툴 
...등등..