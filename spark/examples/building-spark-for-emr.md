Building a Spark Distribution for EMR
=====================

# DISCLAIMER

The following information is for sharing with community on how to compile/build a custom installation of [Spark](http://spark.apache.org) for the EMR environment.   It does not necessarily represent how a "current" build of Spark may be done and provided by AWS or affiliates.   Please use at your own risk.

# References

The best resource available on building Spark is the official documentation itself at [http://spark.apache.org/docs/latest/building-spark.html](http://spark.apache.org/docs/latest/building-spark.html).


# Instructions

## Obtain the Spark source, modify and create clean source for build

Clone from github https://github.com/apache/spark

```
git clone https://github.com/apache/spark.git
```

Checkout branch/tag of interest to a local branch

```
git checkout -b spark-custom branch-1.3
```

Make modifications to source as desired then commit

Create a clean source source tar ball of spark-custom

```
git archive --format=tar --prefix=spark-custom/ spark-custom | gzip -c > ~/spark-custom-src.tgz
```

Then untar the spark-custom-src.tgz on a Ubuntu machine with Java 7, Scala 2.10 and at least Maven 3.0.4.

## Compile

Use `make-distribution.sh` per Spark docs to build

```
./make-distribution.sh -Pyarn -Phadoop-2.4 -Dhadoop.version=2.4.0 -DskipTests -Pkinesis-asl -Pspark-ganglia-lgpl -Phadoop-provided -Phive -Phive-thriftserver
```

Add some additional items to distribution for easier reference

```
for i in $(find . -name "*.jar" | grep -v source | grep -v dist| grep -v test | grep external) ; do cp $i dist/lib/; done 
for i in $(find . -name "*.jar" | grep -v source | grep -v dist| grep -v test | grep extra) ; do cp $i dist/lib/; done 
cp ~/.m2/repository/com/amazonaws/amazon-kinesis-client/1.1.0/amazon-kinesis-client-1.1.0.jar dist/lib/ 
find . -name "*Kinesis*.java" | grep examples | xargs -n 1 -I {} cp {} dist/examples/src/main/java/org/apache/spark/examples/streaming/. 
find . -name "*Kinesis*.scala" | grep examples | xargs -n 1 -I {} cp {} dist/examples/src/main/scala/org/apache/spark/examples/streaming/. 
```

Tar and gzip the distriburtion now located in `dist/`

## Upload and install

Upload the final tgz file to an S3 location then one can use the customer config file option of the `install-spark` script to reference the custom location for the custom build.  See [config.file](https://github.com/awslabs/emr-bootstrap-actions/blob/master/spark/config.file) for inline instructions writing a config file, call it with the `-c` option to `install-spark`.
