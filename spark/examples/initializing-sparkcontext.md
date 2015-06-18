Initializing SparkContext to Scala and Java
========================

The [Spark Programming Guide](https://spark.apache.org/docs/latest/programming-guide.html) from the official documentation provides many examples and notes around creating a Spark application in Scala, Java and Python.  This  document strives to provide a very basic template for minimal code required to write a Spark application.


Important: When initiating the SparkContext do *not* use a constructor or method to set the master value from within the code.  There is a number of examples available on the Internet (not official Spark examples) that take this action which will end up overriding the configuration provided by `spark-submit` and may cause the application to fail or not perform as expected when used with a cluster manager.


## Java

```
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.api.java.function.*;

public final class SparkApp {

    public static void main(String[] args) throws Exception {
	
	//Create SparkContext
        JavaSparkContext spark = new JavaSparkContext(
        		new SparkConf().setAppName("SparkApp")
        		);

	...

	//cleanly shutdown
    	spark.stop();
    	System.exit(0);
    }
}
```

## Scala

```
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

object SparkApp {
 def main(args: Array[String]) {

        // Create SparkContext
        val conf = new SparkConf().setAppName("SparkApp")
        val sc = new SparkContext(conf)

        ...

       //cleanly shutdown
       sc.stop()
 }

}
```
