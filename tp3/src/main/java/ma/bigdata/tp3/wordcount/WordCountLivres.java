package ma.bigdata.tp3.wordcount;
import java.io.IOException;
import java.util.*;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
public class WordCountLivres {
 public static class MotMapper extends Mapper<LongWritable,Text,Text,IntWritable> {
  final Set<String> stop=new HashSet<>(); int min;
  protected void setup(Context c) { min=c.getConfiguration().getInt("wc.longueur.min",1);
   for(String s:c.getConfiguration().get("wc.mots.vides","").split(",")) if(!s.trim().isEmpty()) stop.add(s.trim().toLowerCase(Locale.ROOT)); }
  protected void map(LongWritable k,Text v,Context c) throws IOException,InterruptedException {
   for(String s:v.toString().toLowerCase(Locale.ROOT).split("[^\\p{L}]+")) {
    if(s.isEmpty()) continue;
    if(s.length()<min || stop.contains(s)) {c.getCounter("Mots","IGNORES").increment(1);continue;}
    c.getCounter("Mots","GARDES").increment(1);c.write(new Text(s),new IntWritable(1));
   }
  }
 }
 public static class SommeReducer extends Reducer<Text,IntWritable,Text,IntWritable> {
  protected void reduce(Text k,Iterable<IntWritable> vs,Context c) throws IOException,InterruptedException {
   int n=0;for(IntWritable v:vs)n+=v.get();c.write(k,new IntWritable(n));
  }
 }
 public static void main(String[] args) throws Exception {
  Configuration conf=new Configuration();String[] a=new GenericOptionsParser(conf,args).getRemainingArgs();
  if(a.length!=2)throw new IllegalArgumentException("WordCountLivres [-D cle=valeur] entree sortie");
  Job j=Job.getInstance(conf,"TP3 - comptage des mots");j.setJarByClass(WordCountLivres.class);
  j.setMapperClass(MotMapper.class);j.setReducerClass(SommeReducer.class);
  if(conf.getBoolean("wc.combiner",true))j.setCombinerClass(SommeReducer.class);
  j.setOutputKeyClass(Text.class);j.setOutputValueClass(IntWritable.class);
  FileInputFormat.addInputPath(j,new Path(a[0]));FileOutputFormat.setOutputPath(j,new Path(a[1]));
  System.exit(j.waitForCompletion(true)?0:1);
 }
}
