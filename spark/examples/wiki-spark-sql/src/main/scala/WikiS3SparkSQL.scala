/*

Name: Sample doing SparkSQL on top of Wikipedia data sitting in S3
Output: Result of SQL queries 
	1) Count of records
	2) Show pages with views between 1000 and 2000

Author: Manjeet Chayel
Date: March 10, 2015
Amazon Web Services

*/
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import org.apache.spark.sql._
import org.apache.log4j.Logger
import org.apache.log4j.Level


case class WikiS3Data(projectcode: String, pagename: String, pageviews: Int, bytes: String)

object WikiS3SparkSQL {
 def main(args: Array[String]) {

         //Set logging level to ERROR
        Logger.getLogger("org.apache.spark").setLevel(Level.ERROR)

        val conf = new SparkConf().setAppName("WikiData-Spark SQL")
        val sc = new SparkContext(conf)
        val sqlContext = new org.apache.spark.sql.SQLContext(sc)
        import sqlContext.createSchemaRDD

        val wData = sc.textFile("s3://support.elasticmapreduce/bigdatademo/sample/wiki").map(_.split(" ")).map(p=> WikiS3Data(p(0),p(1),p(2).toInt,p(3)))

        wData.registerAsTable("wiki_data")

        val wcount = sqlContext.sql("SELECT count(pagename)  from wiki_data")

        wcount.map(t => "Count: " + t(0)).collect().foreach(println)

      // Show top 10 Pages
        val topPages = sqlContext.sql("SELECT pagename, pageviews from wiki_data order by pageviews desc limit 5")
        topPages.map(t => "Page=> " + t(0) + " Views =>  " + t(1)).collect().foreach(println)

       //Show pages with between 1000 and 2000 views
        val betweenPages = sqlContext.sql("SELECT pagename, pageviews from wiki_data where pageviews >= 1000 and pageviews <= 2000")
        betweenPages.map( t => "PageName: " + t(0) + "(" + t(1) + ")").collect().foreach(println)
  }
}
