/*
Name: Word Count example on Amazon EMR
Doing word count on file present in S3 bucket
Output: Number of occurances of words 'island' and 'the'
*/

import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.log4j.Logger
import org.apache.log4j.Level

object WordCount {
  def main(args: Array[String]) {

    //Set logging level to ERROR
    Logger.getLogger("org.apache.spark").setLevel(Level.ERROR)

    //Reading a local file on HDFS
    val myInput = "s3://elasticmapreduce/samples/wordcount/input" // Should be some file on your local HDFS
    val conf = new SparkConf().setAppName("Word Count")
    val sc = new SparkContext(conf)
    val inputData = sc.textFile(myInput, 2).cache()

    //Find words having words 'island' and 'the'
    val wordA = inputData.filter(line => line.contains("islands")).count()
    val wordB = inputData.filter(line => line.contains("the")).count
    println("Number of lines with word 'islands'  %s".format(wordA))
    println("Number of lines with word 'the'  %s".format(wordB))
  }
}
