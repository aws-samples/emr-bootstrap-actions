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

�� ��� �ɼ��� ���û����̴�. Ư�� -T�� -H�� local pc���� Test������ ����Ѵ�.


Sample Commands:
================

1. Default: �ɼ��� ���� ���� �⺻ �����̴�. tajo_root_dir�� EMR�� HDFS�� ����Ѵ�.

    aws emr create-cluster --name="[CLUSTER_NAME]" --ami-version=3.3 --ec2-attributes KeyName=[KEY_FIAR_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge --bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh

2. Override Tajo Config and third party lib: -t, -c, -l�� ����� �����̴�. -c �� Tajo ���������� ���Ե� s3 ���丮 ��ην� tajo_root_dir�� s3�� ����Ϸ��� tajo-site.xml�� �˸°� �����Ͽ� �� ���丮�� �־�ξ�� �Ѵ�. -l�� �ܺ� ���̺귯���� Tajo�� ����ϰ� �� ��� �� ���̺귯���� ��Ƴ��� s3 ���丮 ��ην� RDS(mysql)�� ����� ��� mysql-connector.jar�� ���ԵǾ�� �Ѵ�.   

    aws emr create-cluster --name="[CLUSTER_NAME]" --ami-version=3.3 --ec2-attributes KeyName=[KEY_FIAR_NAME] --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=c3.xlarge --bootstrap-action Name="Install tajo",Path=s3://[your_bucket]/[your_path]/install-tajo.sh,Args=["-t","s3://[your_bucket]/tajo-0.9.0.tar.gz","-c","s3://[your_bucket]/conf","-l","s3://[your_bucket]/lib"]


Test:
================
install-tajo.sh ��ũ��Ʈ�� �� �۵��ϴ��� Test�ϱ� ���� ������ -T, -H �ɼ��� �̿��ϴ� ���̴�. �̰��� EMR�� �ƴ� �ڽ��� local pc���� �����Ѵ�. -T�� local���� Test�ϱ� ���� ������ ���丮 ����̴�. �� ���丮�� hadoop,tajo�� ��ġ�� ���̴�. -H�� local�� ��ġ�Ǿ��ִ� hadoop_home�̴�. �׽�Ʈ�� ���� �� hadoop_home�� ������ ���̴�.
    
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
Tajo ���� ������ �ν��Ͻ� Ÿ�Ժ��� template�� �����Ѵ�.


NOTES: 
=====
##I'm going to update this section.
...��ť��Ƽ �׷� 
...���..


Sample Usage
============
##I'm going to update this section.
...tpc �׽�Ʈ 
...��ũ��ġ �� 
...���..