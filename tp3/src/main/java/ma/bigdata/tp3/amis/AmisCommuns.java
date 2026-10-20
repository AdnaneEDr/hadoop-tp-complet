package ma.bigdata.tp3.amis;
import java.io.IOException;
import java.util.*;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
public class AmisCommuns {
 public static class PaireMapper extends Mapper<LongWritable,Text,Text,Text> {
  protected void map(LongWritable k,Text v,Context c)throws IOException,InterruptedException {
   String[] p=v.toString().split(":",-1);
   if(p.length!=2 || p[0].trim().isEmpty()){c.getCounter("Amis","LIGNES_INVALIDES").increment(1);return;}
   String who=p[0].trim();TreeSet<String> friends=new TreeSet<>();
   for(String f:p[1].split(","))if(!f.trim().isEmpty()&&!f.trim().equals(who))friends.add(f.trim());
   for(String f:friends)c.write(new Text(who.compareTo(f)<0?who+","+f:f+","+who),new Text(String.join(",",friends)));
  }
 }
 public static class IntersectionReducer extends Reducer<Text,Text,Text,Text> {
  protected void reduce(Text k,Iterable<Text> vs,Context c)throws IOException,InterruptedException {
   List<TreeSet<String>> lists=new ArrayList<>();for(Text v:vs)lists.add(new TreeSet<>(Arrays.asList(v.toString().split(","))));
   if(lists.size()!=2){c.getCounter("Amis","AMITIES_A_SENS_UNIQUE").increment(1);return;}
   lists.get(0).retainAll(lists.get(1));c.write(k,new Text(lists.get(0).toString()));
  }
 }
 public static void main(String[] args)throws Exception {
  Configuration conf=new Configuration();String[] a=new GenericOptionsParser(conf,args).getRemainingArgs();
  if(a.length!=2)throw new IllegalArgumentException("AmisCommuns entree sortie");
  Job j=Job.getInstance(conf,"TP3 - amis communs M1");j.setJarByClass(AmisCommuns.class);
  j.setMapperClass(PaireMapper.class);j.setReducerClass(IntersectionReducer.class);j.setOutputKeyClass(Text.class);j.setOutputValueClass(Text.class);
  FileInputFormat.addInputPath(j,new Path(a[0]));FileOutputFormat.setOutputPath(j,new Path(a[1]));System.exit(j.waitForCompletion(true)?0:1);
 }
}
