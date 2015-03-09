Spark (Java) example of newAPIHadoopFile() with TeraInputFormat
=====================

# Goals of this document

Provide basic example of using the newAPIHadoopFile() method, also demonstrates setting Hadoop configuration items (in this example, we use `mapreduce.input.fileinputformat.split.minsize` and `fs.s3n.block.size`) to influence the behaviour of the Hadoop input format. This example code uses Hadoop's TeraInputFormat from Hadoop examples.

# Background

Spark provides multiple methods to read input including [textFile()](http://spark.apache.org/docs/latest/programming-guide.html). The textFile() method is not always sufficient for processing input and at times it makes assumptions that are not appropiate for the input format (such as assuming all compressed input is not splittable).  Through the use of the newAPIHadoopFile() method one can utilize any Hadoop input format to ingest data into a RDD. 

# Example

```
public final class TeraInputOutput {

    public static void main(String[] args) throws Exception {
        JavaSparkContext spark = new JavaSparkContext();

        Configuration jobConf = new Configuration();
       	jobConf.set("mapreduce.input.fileinputformat.split.minsize", args[1]);
       	jobConf.set("fs.s3n.block.size", args[2]);
        
        JavaPairRDD<Text, Text> inputRDD = spark.newAPIHadoopFile(args[0],TeraInputFormat.class,Text.class,Text.class, jobConf);
        System.out.println(inputRDD.count());

        spark.stop();
        System.exit(0);
    }
}
