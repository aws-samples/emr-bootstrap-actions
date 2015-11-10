#!/usr/bin/env python

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# The EMR 4.x Bootstrap for Tajo
#
# Arguments
#
# -t, --tar
#       The tajo binary Tarball URL.(Optional)
#
#       ex) --tar http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.10.0/tajo-0.10.0.tar.gz
#       or
#       --tar s3://[your_bucket]/[your_path]/tajo-{version}.tar.gz
#
# -c, --conf
#       The tajo conf directory URL.(Optional)
#
#       ex) --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf
#
# -l, --lib
#       The tajo third party lib URL.(Optional)
#
#       ex) --lib s3://{your_bucket}/{your_lib_dir}
#       or
#       --lib http://{lib_url}/{lib_file_name.jar}
#
# -v, --tajo-version
#       The tajo release version.(Optional)
#       Default: Apache tajo stable version.
#
#       ex) x.x.x
#
# -h, --help
#       The help
#
# -e, --env
#       The item of tajo-env.sh(Optional, space delimiter)
#
#       ex) --env "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"
#
# -s, --site
#       The item of tajo-site.xml(Optional, space delimiter)
#
#       ex) --site "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore"
#
# -T, --test-home
#       The Test directory path(Only test)
#
#       ex) --test-home "/home/hadoop/bootstrap_test"
#
# -H, --test-hadoop-home
#       The Test HADOOP_HOME(Only test)
#
#       ex) --test-hadoop-home "/home/hadoop"
#

# -*- coding: utf-8 -*-
import os, sys
import argparse
import shutil
import re
import json
import socket
import tarfile
import urllib2
import time
import subprocess
from xml.etree import ElementTree
from urlparse import urlparse


class XmlUtil:
    CONFIGURATION_HEADER = '''<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>'''
    CONFIGURATION_EMPTY_NODE = '''<configuration></configuration>'''

    def header_configuration(self):
        return self.CONFIGURATION_HEADER

    def new_configuration(self):
        return self.CONFIGURATION_EMPTY_NODE

    def get_property_value(self, target, key):
        if os.path.isfile(target):
            print('Found file %s' % (target,))
            tree = ElementTree.parse(target)
            root = tree.getroot()
            for property in root.findall('property'):
                name = property.find('name')
                if name.text == key:
                    return property.find('value').text
        else:
            print('Not Found file at %s' % (target,))
            return None

    def get_property_value_from_node(self, root, key):
        for property in root.findall('property'):
            name = property.find('name')
            if name.text == key:
                return property.find('value').text
        print('Not Found The Name %s' % (key,))
        return None

    def create_node(self, parent, node, name, value):
        node = ElementTree.Element(node)
        ElementTree.SubElement(node, 'name').text = name
        ElementTree.SubElement(node, 'value').text = value
        parent.append(node)
        return parent

    def indent(self, elem, level=0):
        i = '\n' + level * '  '
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = i + '  '
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
            for elem in elem:
                self.indent(elem, level + 1)
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
        else:
            if level and (not elem.tail or not elem.tail.strip()):
                elem.tail = i


class JsonUtil:
    TARGET_JSON = None
    JSON_DATA = None

    def __init__(self, json_path):
        self.TARGET_JSON = json_path
        with open(self.TARGET_JSON, 'r') as js_data:
            self.JSON_DATA = json.load(js_data)

    def get(self, key):
        if self.JSON_DATA:
            return self.JSON_DATA[key]
        else:
            print('Json is null')
            return None


class FileUtil:
    TEST_MODE = False
    HADOOP_HOME = ""

    def __init__(self, hadoop_home):
        self.HADOOP_HOME = hadoop_home

    def rm(self, path):
        if os.path.isdir(path):
            shutil.rmtree(path)
        elif os.path.exists(path):
            os.remove(path)

    def cp2(self, src, dest):
        shutil.copy2(src, dest)

    def ln(self, src, dest):
        return os.symlink(src, dest)

    def ln(self, src, dest, forced):
        if forced:
            self.rm(dest)
        return os.symlink(src, dest)

    def copytree(self, src, dest):
        return shutil.copytree(src, dest)

    def copytree(self, src, dest, forced):
        if forced:
            self.cleanup(dest)
        return shutil.copytree(src, dest)

    def mkdir(self, src):
        if not os.path.exists(src):
            return os.mkdir(src);
        return True

    def mv(self, src, dest):
        shutil.move(src, dest)

    def chmod(self, fname, permit):
        os.chmod(fname, permit)

    def cleanup(self, path):
        print('Info: Clean up. (%s)' % (path,))
        self.rm(path)

    def download(self, src, dest):
        print('Info: Download package from %s' % (src,))
        parser = urlparse(src.strip())
        if parser.scheme == 'http' or parser.scheme == 'https':
            response = urllib2.urlopen(src)
            handle = open('%s/%s' % (dest, os.path.basename(src)), 'w')
            handle.write(response.read())
            handle.close()
        else:
            if self.TEST_MODE:
                return self.cp2(src, dest)
            else:
                return os.system('hdfs dfs -copyToLocal %s %s' % (src, dest))

    def unpack(self, pack, dest):
        print('Info: Unpack. (%s, %s)' % (pack, dest))
        tar = tarfile.open(pack)
        tar.extractall(dest)
        tar.close()

    def invoke_run(self, fname, values, hadoop_home):
        self.ln(__file__, './installtajolib.py', True)
        invoke = InvokeUtil()
        fname = invoke.makeInvoke(fname, hadoop_home)
        values.insert(0, fname)
        pid = subprocess.Popen(values)
        return pid


class NetworkUtil:
    def scan(self, host, port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex((host, port))
        sock.close()
        return result


class InvokeUtil:
    INVOKE_SOURCE_STR = '''#!/usr/bin/env python
import os
from datetime import datetime
import time
from xml.etree import ElementTree
import re
from installtajolib import *

targetFile="%s/etc/hadoop/yarn-site.xml"
launcherUtil = LauncherUtil()
launcherUtil.options = launcherUtil.parse_opts()
fname="./history.log"
flog = open(fname, "w", 0)
flog.write("%%s\\tWaiting for creating hadoop environment.\\n" %% (datetime.now(),) )
isMaster = False
loop = 0
master = ""
detected = False
while os.path.isfile(targetFile) is False or isMaster is False :
  if os.path.isfile(targetFile) :
    if not detected:
       flog.write("%%s\\tFound It! : %%s\\n" %% (datetime.now(), targetFile))
       flog.write("%%s\\tWaiting for looking master..\\n" %% (datetime.now(),))
       detected = True
    tree = ElementTree.parse(targetFile)
    root = tree.getroot()
    for property in root.findall("property"):
      name = property.find("name")
      if name.text == "yarn.resourcemanager.address" :
        master = property.find("value").text
        m = re.search("[^:<]+", master)
        master = m.group()
        isMaster = True
  if loop > launcherUtil.MAX_WAITING_SEC:
    flog.write("Break running! (Loop greater than %%d secs)\\n" %% (launcherUtil.MAX_WAITING_SEC,) )
    break
  time.sleep(1)
  flog.write(".")
  loop += 1
  if loop%%60 == 0:
    flog.write("\\n")
flog.write("%%s\\tMaster:%%s\\n" %% (datetime.now(), master) )
flog.close()
launcherUtil.build()
launcherUtil.start()'''

    def getSrc(self, hadoop_home):
        return self.INVOKE_SOURCE_STR % (hadoop_home,)

    def makeInvoke(self, fname, hadoop_home):
        fname = "./%s" % (fname,)
        if os.path.exists(fname):
            os.remove(fname)
        finvoke = open(fname, 'w')
        finvoke.write(self.getSrc(hadoop_home))
        finvoke.close()
        os.chmod(fname, 0775)
        return fname


class LauncherUtil:
    EXPORT_LIBS = '''
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk.x86_64
export HADOOP_HOME=%s
export HADOOP_MAPREDUCE_HOME=%s
export HADOOP_HDFS_HOME=%s
export HADOOP_YARN_HOME=%s
export HADOOP_LZO_HOME=%s
export TAJO_CLASSPATH="$TAJO_CLASSPATH:/usr/share/aws/emr/emrfs/lib:/usr/share/aws/emr/lib"
export TAJO_CLASSPATH="$TAJO_CLASSPATH:$HADOOP_HOME:$HADOOP_HOME/lib"
export TAJO_CLASSPATH="$TAJO_CLASSPATH:$HADOOP_MAPREDUCE_HOME"
export TAJO_CLASSPATH="$TAJO_CLASSPATH:$HADOOP_HDFS_HOME:$HADOOP_HDFS_HOME/lib"
export TAJO_CLASSPATH="$TAJO_CLASSPATH:$HADOOP_YARN_HOME"
export TAJO_CLASSPATH="$TAJO_CLASSPATH:$HADOOP_LZO_HOME/lib"
'''
    HADOOP_MODULE_DIRS_REGEX = r'''# HADOOP JAR DIRS
HADOOP_MODULE_DIRS="$HADOOP_HOME/share/hadoop/common/lib
$HADOOP_HOME/share/hadoop/common
$HADOOP_HOME/share/hadoop/hdfs
$HADOOP_HOME/share/hadoop/hdfs/lib
$HADOOP_HOME/share/hadoop/yarn
$HADOOP_HOME/share/hadoop/mapreduce
$HADOOP_HOME/share/hadoop/tools/lib"'''

    HADOOP_MODULE_DIRS = '''
HADOOP_MODULE_DIRS="/usr/share/aws/emr/emrfs/lib
/usr/share/aws/emr/lib
$HADOOP_HOME
$HADOOP_HOME/lib
$HADOOP_MAPREDUCE_HOME
$HADOOP_HDFS_HOME
$HADOOP_HDFS_HOME/lib
$HADOOP_YARN_HOME
$HADOOP_LZO_HOME/lib"
'''

    DEFAULT_HELP_MESSAGE = '''usage : install-tajo.py [-t|--tar] [-c|--conf] [-l|--lib] [-h|--help] [-e|--env] [-s|--site] [-T|--test-home] [-H|--test-hadoop-home]
 -t, --tar
       The tajo binary Tarball URL.(Optional)
       ex) --tar http://apache.mirror.cdnetworks.com/tajo/tajo-0.10.0/tajo-0.10.0.tar.gz
       or
       --tar s3://[your_bucket]/[your_path]/tajo-0.10.0.tar.gz
 -c, --conf
       The tajo conf directory URL.(Optional)
       ex) --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf
 -l, --lib
       The tajo third party lib URL.(Optional)
       ex) --lib s3://{your_bucket}/{your_lib_dir}
       or
       --lib http://{lib_url}/{lib_file_name.jar}
 -v, --tajo-version
       The tajo release version.(Optional)
       Default: Apache tajo stable version.
       ex) x.x.x
 -h, --help
       The help
 -e, --env
       The item of tajo-env.sh(Optional, space delimiter)
       ex) --tajo-env.sh "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"
 -s, --site
       The item of tajo-site.xml(Optional, space delimiter)
       ex) --tajo-site.xml "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore"
 -T, --test-home
       The Test directory path(Only test)
       ex) --test-home "/home/hadoop/bootstrap_test"
 -H, --test-hadoop-home
       The Test HADOOP_HOME(Only test)
       ex) --test-hadoop-home "/home/hadoop"'''

    TAJO_BASE = '/home/hadoop'
    TAJO_VERSION = None
    TAJO_PACKAGE_URI = None
    TAJO_CONF_URI = None
    TAJO_HOME = None
    LIBRARY_URI = None
    STORAGE = None
    NAME_NODE = None
    NAME_NODE_PORT = 8020
    TEST_MODE = False
    TEST_DIR = None
    TEST_HADOOP_HOME = None
    TAJO_MASTER = None
    TAJO_ENV = None
    TAJO_SITE = None
    JAVA_HOME = None
    fileUtil = None
    xmlUtil = None
    options = None
    START_INVOKE_FILE = 'invoke-install-tajo.py'
    MAX_WAITING_SEC = 600

    # Parses command line arguments.
    def parse_opts(self):
        parser = argparse.ArgumentParser(description='Tajo Installer on EMR-4.x')
        parser.add_argument('-t', '--tar',
                            dest='tajo_package_uri',
                            required=False,
                            help='''The tajo binary Tarball URL.(Optional)
                        ex) --tar http://d3kp3z3ppbkcio.cloudfront.net/tajo-0.10.0/tajo-0.10.0.tar.gz
                        or --tar s3://[your_bucket]/[your_path]/tajo-{version}.tar.gz''')
        parser.add_argument('-c', '--conf',
                            dest='conf',
                            required=False,
                            help='''The tajo conf directory URL.(Optional)
                        ex) --conf s3://beta.elasticmapreduce/bootstrap-actions/tajo/template/tajo-0.10.0/c3.xlarge/conf''')
        parser.add_argument('-l', '--lib',
                            dest='lib',
                            required=False,
                            help='''The tajo third party lib URL.(Optional)
                        ex) --lib s3://{your_bucket}/{your_lib_dir}
                        or
                        --lib http://{lib_url}/{lib_file_name.jar}''')
        parser.add_argument('-v', '--tajo-version',
                            dest='tajo_version',
                            required=False,
                            help='''The tajo release version.(Optional)
                        Default: Apache tajo stable version.
                        ex) x.x.x''')
        parser.add_argument('-e', '--env',
                            dest='env',
                            required=False,
                            help='''The item of tajo-env.sh(Optional, space delimiter)
                        ex) --tajo-env.sh "TAJO_PID_DIR=/home/hadoop/tajo/pids TAJO_WORKER_HEAPSIZE=1024"''')
        parser.add_argument('-s', '--site',
                            dest='site',
                            required=False,
                            help='''The item of tajo-site.xml(Optional, space delimiter)
                        ex) --tajo-site.xml "tajo.rootdir=s3://mybucket/tajo tajo.worker.start.cleanup=true tajo.catalog.store.class=org.apache.tajo.catalog.store.MySQLStore''')
        parser.add_argument('-T', '--test-home',
                            dest='test_dir',
                            required=False,
                            help='''The Test directory path(Only test)
                        ex) --test-home "/home/hadoop/bootstrap_test"''')
        parser.add_argument('-H', '--test-hadoop-home',
                            dest='test_hadoop_home',
                            required=False,
                            help='''The Test HADOOP_HOME(Only test)
                        ex) --test-hadoop-home "/home/hadoop"''')
        return parser.parse_args()

    ## Print Help
    def help(self):
        print(self.DEFAULT_HELP_MESSAGE)

    def dic_name_value(self, txt):
        d = {}
        pieces = txt.split('=')
        d['name'] = pieces[0]
        d['value'] = '='.join(pieces[1:])
        return d

    def trip(self, value):
        if value:
            return value.strip()
        return value

    def init(self, fileUtil, opt):
        print('Info: Initializing.')
        self.fileUtil = fileUtil
        self.options = opt

        self.TAJO_VERSION = self.trip(opt.tajo_version)
        self.TAJO_PACKAGE_URI = self.trip(opt.tajo_package_uri)
        self.TAJO_CONF_URI = self.trip(opt.conf)
        self.TAJO_HOME = None
        self.LIBRARY_URI = self.trip(opt.lib)
        self.STORAGE = None
        self.NAME_NODE = None
        if opt.test_dir:
            self.TEST_MODE = True
        self.TEST_DIR = self.trip(opt.test_dir)
        self.TEST_HADOOP_HOME = self.trip(opt.test_hadoop_home)
        self.TAJO_ENV = self.trip(opt.env)
        self.TAJO_SITE = self.trip(opt.site)
        self.JAVA_HOME = os.environ['JAVA_HOME']

        self.xmlUtil = XmlUtil()
        if self.TEST_MODE:
            if not self.JAVA_HOME:
                print('Error: JAVA_HOME is not set.')
                sys.exit(1)
            if not self.TEST_DIR:
                print('Error: -T is not set.')
                self.help()
                sys.exit(1)
            if not self.TEST_HADOOP_HOME:
                print('Error: -H is not set.')
                self.help()
                sys.exit(1)
            self.fileUtil.mkdir(self.TEST_DIR)
            self.fileUtil.copytree(self.TEST_HADOOP_HOME, '%s/hadoop' % (self.TEST_DIR,), True)
            os.environ['HADOOP_HOME'] = '%s/hadoop' % (self.TEST_DIR,)
            self.TAJO_MASTER = 'localhost'
        else:
            master = self.xmlUtil.get_property_value('/usr/lib/hadoop/etc/hadoop/yarn-site.xml',
                                                     'yarn.resourcemanager.address')
            m = re.search('[^:<]+', master)
            master = m.group()
            self.TAJO_MASTER = master
            self.TEST_MODE = False
        self.STORAGE = 'S3'
        self.NAME_NODE = self.TAJO_MASTER
        if not self.TAJO_PACKAGE_URI:
            self.TAJO_PACKAGE_URI = 'http://d3kp3z3ppbkcio.cloudfront.net/tajo-$TAJO_VERION/tajo-%s.tar.gz' % (
                self.TAJO_VERSION,)

    def download(self):
        src = self.TAJO_PACKAGE_URI
        dest = self.TAJO_BASE
        if self.TEST_MODE:
            dest = self.TEST_DIR
        return self.fileUtil.download(src, dest)

    def unpack(self):
        tarball = '%s/%s' % (self.TAJO_BASE, os.path.basename(self.TAJO_PACKAGE_URI))
        dest = self.TAJO_BASE
        if self.TEST_MODE:
            dest = self.TEST_DIR
            tarball = '%s/%s' % (dest, tarball)
        return self.fileUtil.unpack(tarball, dest)

    def makeln(self):
        c = re.compile(r'(?P<name>.*).tar.gz')
        m = c.match(os.path.basename(self.TAJO_PACKAGE_URI))
        name = m.group('name')
        src = '%s/%s' % (self.TAJO_BASE, name)
        dest = '%s/%s' % (self.TAJO_BASE, 'tajo')
        if self.TEST_MODE:
            src = '%s/%s' % (self.TEST_DIR, name)
            dest = '%s/%s' % (self.TEST_DIR, 'tajo')
        print('makeln: %s, %s' % (src, dest))
        os.symlink(src, dest)
        self.TAJO_HOME = dest

    def set_hadoop_modules(self):
        print('Info: Setting hadoop modules in tajo script.')
        if self.TEST_MODE:
            return
        org = '%s/bin/tajo' % (self.TAJO_HOME,)
        src = '%s/bin/tajo.tmp' % (self.TAJO_HOME,)
        target = r'''^# HADOOP JAR DIRS
HADOOP_MODULE_DIRS="\$HADOOP_HOME/share/hadoop/common/lib
\$HADOOP_HOME/share/hadoop/common
\$HADOOP_HOME/share/hadoop/hdfs
\$HADOOP_HOME/share/hadoop/hdfs/lib
\$HADOOP_HOME/share/hadoop/yarn
\$HADOOP_HOME/share/hadoop/mapreduce
\$HADOOP_HOME/share/hadoop/tools/lib"$'''
        change = r'''
# HADOOP JAR DIRS
HADOOP_MODULE_DIRS="/usr/share/aws/emr/emrfs/lib
usr/share/aws/emr/lib
$HADOOP_HOME
$HADOOP_HOME/lib
$HADOOP_MAPREDUCE_HOME
$HADOOP_HDFS_HOME
$HADOOP_HDFS_HOME/lib
$HADOOP_YARN_HOME
$HADOOP_LZO_HOME/lib"'''
        match = re.compile(target, re.M)
        self.fileUtil.cp2(org, src)
        with open(src, 'r') as content_file:
            content = content_file.read()
            ret = match.search(content)
            if ret:
                print ret.group()
                ret = match.sub(change, content)
                fnew = open(org, 'w')
                fnew.write(ret)
                fnew.close()
                self.fileUtil.rm(src)
                print "Successed to change content."
            else:
                print "Failed set hadoop modules : Not found target and not changed env."


    def set_tajo_conf(self):
        print('Info: Setting tajo conf.')
        if self.TAJO_CONF_URI:
            self.fileUtil.mkdir('%s/conf/temp' % (self.TAJO_HOME,))
            # Test mode
            if self.TEST_MODE:
                src = '%s/*' % (self.TAJO_CONF_URI,)
                dest = '%s/conf/temp' % (self.TEST_DIR,)
                self.fileUtil.copytree(src, dest)
            else:
                os.system('hdfs dfs -copyToLocal %s/* %s/conf/temp' % (self.TAJO_CONF_URI, self.TAJO_HOME))
                src = '%s/conf/temp' % (self.TAJO_HOME,)
                dest = '%s/conf' % (self.TAJO_HOME,)
            for f in os.listdir(src):
                self.fileUtil.cp2('%s/%s' % (src, f), dest)
            self.fileUtil.cleanup(src)
            self.fileUtil.chmod('%s/conf/tajo-env.sh' % (self.TAJO_HOME,), 0775)
        tajo_env_sh = '%s/conf/tajo-env.sh' % (self.TAJO_HOME,)
        ftajo_env_sh = open(tajo_env_sh, 'a', 0)
        echo_hadoop_home = '/usr/lib/hadoop'
        echo_hadoop_mapreduce_home = '%s-mapreduce' % (echo_hadoop_home,)
        echo_hadoop_hdfs_home = '%s-hdfs' % (echo_hadoop_home,)
        echo_hadoop_yarn_home = '%s-yarn' % (echo_hadoop_home,)
        echo_hadoop_lzo_home = '%s-lzo' % (echo_hadoop_home,)
        # Test mode
        if self.TEST_MODE:
            echo_hadoop_home = self.TEST_HADOOP_HOME
        export_libs = self.EXPORT_LIBS % (echo_hadoop_home, echo_hadoop_mapreduce_home, echo_hadoop_hdfs_home, echo_hadoop_yarn_home, echo_hadoop_lzo_home,)
        ftajo_env_sh.write(export_libs)

        # using --env option
        if self.TAJO_ENV:
            for property in self.TAJO_ENV.replace(' ', '\n').split():
                ftajo_env_sh.write('export %s' % (property,))
        ftajo_env_sh.close()

        tajo_site_xml = '%s/conf/tajo-site.xml' % (self.TAJO_HOME,)
        if not os.path.exists(tajo_site_xml):
            ftajo_site_xml = open(tajo_site_xml, 'w', 0)
            ftajo_site_xml.write(self.xmlUtil.new_configuration())
            ftajo_site_xml.close()

        tree = ElementTree.parse(tajo_site_xml)
        root = tree.getroot()
        root = self.xmlUtil.create_node(root, 'property', 'tajo.master.umbilical-rpc.address',
                                        '%s:26001' % (self.TAJO_MASTER,))
        root = self.xmlUtil.create_node(root, 'property', 'tajo.master.client-rpc.address',
                                        '%s:26002' % (self.TAJO_MASTER,))
        root = self.xmlUtil.create_node(root, 'property', 'tajo.resource-tracker.rpc.address',
                                        '%s:26003' % (self.TAJO_MASTER,))
        root = self.xmlUtil.create_node(root, 'property', 'tajo.catalog.client-rpc.address',
                                        '%s:26005' % (self.TAJO_MASTER,))

        # setting tmp_dir
        tmpdir = None
        if not self.TEST_MODE:
            tmpdirs = self.xmlUtil.get_property_value('/usr/lib/hadoop/etc/hadoop/hdfs-site.xml', 'dfs.name.dir')
            for dir in tmpdirs.replace(',', '\n').split():
                if not tmpdir:
                    tmpdir = '%s/tajo/tmp' % (dir,)
                else:
                    tmpdir = '%s,%s/tajo/tmp' % (tmpdir, dir)
            root = self.xmlUtil.create_node(root, 'property', 'tajo.worker.tmpdir.locations', '%s' % (tmpdir,))
        # using --site option
        if self.TAJO_SITE:
            for property in self.TAJO_SITE.replace(',', '\n').split():
                d = self.dic_name_value(property)
                name = d['name']
                value = d['value']
                root = self.xmlUtil.create_node(root, 'property', name, value)
        # Default rootdir is EMR hdfs
        if not self.xmlUtil.get_property_value_from_node(root, 'tajo.rootdir'):
            self.STORAGE = 'local'
            if self.TEST_MODE:
                root = self.xmlUtil.create_node(root, 'property', 'tajo.rootdir', 'file:///%s/tajo' % (self.TAJO_HOME,))
            else:
                root = self.xmlUtil.create_node(root, 'property', 'tajo.rootdir',
                                                'hdfs://%s:%d/tajo' % (self.NAME_NODE, self.NAME_NODE_PORT))
        self.xmlUtil.indent(root)
        with open('%s/conf/tajo-site.xml' % (self.TAJO_HOME,), "w", 0) as f:
            f.write(self.xmlUtil.header_configuration())
            f.write(ElementTree.tostring(root))

    ## Download Third party Library
    def third_party_lib(self):
        print('Info: Download Third party Library.')
        if self.LIBRARY_URI:
            parser = urlparse(self.LIBRARY_URI.strip())
            if parser.scheme == 'http' or parser.scheme == 'https':
                return os.system(
                    'curl -o %s/lib/%s %s' % (self.TAJO_HOME, os.path.basename(self.LIBRARY_URI), self.LIBRARY_URI))
            else:
                # Test mode
                if self.TEST_MODE:
                    self.fileUtil.copytree('%s/*' % (self.LIBRARY_URI,), '%s/lib' % (self.TAJO_HOME,))
                else:
                    return os.system('hdfs dfs -copyToLocal %s/* %s/lib' % (self.LIBRARY_URI, self.TAJO_HOME))

    def parse_args(self, opt):
        values = []
        if opt.conf:
            values.append('-c')
            values.append('%s' % (opt.conf,))
        if opt.tajo_package_uri:
            values.append('-t')
            values.append('%s' % (opt.tajo_package_uri,))
        if opt.site:
            values.append('-s')
            values.append('%s' % (opt.site,))
        if opt.tajo_version:
            values.append('-v')
            values.append('%s' % (opt.tajo_version,))
        if opt.env:
            values.append('-e')
            values.append('%s' % (opt.env,))
        if opt.lib:
            values.append('-l')
            values.append('%s' % (opt.lib,))
        if opt.test_hadoop_home:
            values.append('-H')
            values.append('%s' % (opt.test_hadoop_home,))
        if opt.test_dir:
            values.append('-T')
            values.append('%s' % (opt.test_dir,))
        return values

    def build(self):
        self.fileUtil = FileUtil(self.TAJO_BASE)
        self.init(self.fileUtil, self.options)
        self.download()
        self.unpack()
        self.makeln()
        self.set_tajo_conf()
        self.set_hadoop_modules()
        self.third_party_lib()

    def start(self):
        print('Info: Start Tajo.')
        networkUtil = NetworkUtil()
        if self.TEST_MODE:
            os.system('%s/bin/tajo-daemon.sh start master' % (self.TAJO_HOME,))
            os.system('%s/bin/tajo-daemon.sh start worker' % (self.TAJO_HOME,))
        else:
            jsonUtil = JsonUtil('/mnt/var/lib/info/instance.json')
            if jsonUtil.get('isMaster'):
                if self.STORAGE == "local":
                    result = networkUtil.scan(self.NAME_NODE, self.NAME_NODE_PORT)
                    while result != 0:
                        time.sleep(5)
                        result = networkUtil.scan(self.NAME_NODE, self.NAME_NODE_PORT)
                os.system('%s/bin/tajo-daemon.sh start master' % (self.TAJO_HOME,))
            else:
                result = networkUtil.scan(self.TAJO_MASTER, 26001)
                while result != 0:
                    time.sleep(5)
                    result = networkUtil.scan(self.NAME_NODE, self.NAME_NODE_PORT)
                    result = networkUtil.scan(self.TAJO_MASTER, 26001)
                os.system('%s/bin/tajo-daemon.sh start worker' % (self.TAJO_HOME,))


def main():
    launcherUtil = LauncherUtil()
    opt = launcherUtil.parse_opts()
    values = launcherUtil.parse_args(opt)
    fileUtil = FileUtil(launcherUtil.TAJO_BASE)
    hadoop_home = '/usr/lib/hadoop'
    if opt.test_hadoop_home:
        hadoop_home = opt.test_hadoop_home
    pid = fileUtil.invoke_run(launcherUtil.START_INVOKE_FILE, values, hadoop_home)
    print('> Created a new process : %s %s' % (pid, values))


if __name__ == '__main__':
    sys.exit(main())
