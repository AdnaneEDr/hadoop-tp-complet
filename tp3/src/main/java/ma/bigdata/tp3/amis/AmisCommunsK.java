package ma.bigdata.tp3.amis;
import java.io.*;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
public class AmisCommunsK {
 public static class GroupeMapper extends Mapper<LongWritable,Text,Text,Text> {
  int k;
  protected void setup(Context c){k=c.getConfiguration().getInt("amis.k",2);if(k<2||k>4)throw new IllegalArgumentException("amis.k doit etre 2, 3 ou 4");}
  protected void map(LongWritable key,Text v,Context c)throws IOException,InterruptedException {
   String[] p=v.toString().split(":",-1);
   if(p.length!=2||p[0].trim().isEmpty()){c.getCounter("Amis","LIGNES_INVALIDES").increment(1);return;}
   TreeSet<String> fs=new TreeSet<>();for(String f:p[1].split(","))if(!f.trim().isEmpty()&&!f.trim().equals(p[0].trim()))fs.add(f.trim());
   combine(fs.toArray(new String[0]),k,0,new ArrayList<String>(),p[0].trim(),c);
  }
  void combine(String[] fs,int left,int start,List<String> g,String who,Context c)throws IOException,InterruptedException {
   if(left==0){c.write(new Text(String.join(",",g)),new Text(who));c.getCounter("Amis","GROUPES_EMIS").increment(1);return;}
   for(int i=start;i<=fs.length-left;i++){g.add(fs[i]);combine(fs,left-1,i+1,g,who,c);g.remove(g.size()-1);}
  }
 }
 public static class CommunsReducer extends Reducer<Text,Text,Text,Text> {
  int min;boolean status;Map<String,Set<String>> graph=new HashMap<>();
  protected void setup(Context c)throws IOException {
   min=c.getConfiguration().getInt("amis.min",1);status=c.getConfiguration().getBoolean("amis.statut",false);
   if(status){
    if(!new File("graphe").isFile())throw new IOException("Cache distribue graphe absent");
    try(BufferedReader br=new BufferedReader(new InputStreamReader(new FileInputStream("graphe"),StandardCharsets.UTF_8))){
     String l;while((l=br.readLine())!=null){String[] p=l.split(":",-1);if(p.length==2){Set<String> fs=new HashSet<>();for(String f:p[1].split(","))if(!f.trim().isEmpty())fs.add(f.trim());graph.put(p[0].trim(),fs);}}
    }
   }
  }
  protected void reduce(Text key,Iterable<Text> vs,Context c)throws IOException,InterruptedException {
   TreeSet<String> friends=new TreeSet<>();for(Text v:vs)friends.add(v.toString());if(friends.size()<min)return;
   String result=friends.size()+"\t"+friends;
   if(status){boolean all=true;String[] g=key.toString().split(",");for(int i=0;i<g.length;i++)for(int j=i+1;j<g.length;j++)
    all &= graph.getOrDefault(g[i],Collections.emptySet()).contains(g[j])&&graph.getOrDefault(g[j],Collections.emptySet()).contains(g[i]);
    result+="\t"+(all?"amis entre eux":"PAS tous amis");}
   c.write(key,new Text(result));
  }
 }
 public static void main(String[] args)throws Exception {
  Configuration conf=new Configuration();String[] a=new GenericOptionsParser(conf,args).getRemainingArgs();
  if(a.length!=2)throw new IllegalArgumentException("AmisCommunsK [-D amis.k=2] entree sortie");
  Job j=Job.getInstance(conf,"TP3 - amis communs k="+conf.getInt("amis.k",2));j.setJarByClass(AmisCommunsK.class);
  if(conf.getBoolean("amis.statut",false))j.addCacheFile(new URI(a[0]+"#graphe"));
  j.setMapperClass(GroupeMapper.class);j.setReducerClass(CommunsReducer.class);j.setOutputKeyClass(Text.class);j.setOutputValueClass(Text.class);
  FileInputFormat.addInputPath(j,new Path(a[0]));FileOutputFormat.setOutputPath(j,new Path(a[1]));System.exit(j.waitForCompletion(true)?0:1);
 }
}
