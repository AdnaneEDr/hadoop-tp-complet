"""Genere un cluster Hadoop 3.4.3 isole, deux DataNodes et deux NodeManagers."""
from pathlib import Path
from xml.sax.saxutils import escape
import os,shutil
base=Path.home()/'tp-hadoop-runtime';h=base/'hadoop-3.4.3';state=base/'etat';state.mkdir(parents=True,exist_ok=True)
common={
'core-site.xml':{'fs.defaultFS':'hdfs://localhost:19000','hadoop.tmp.dir':str(state/'tmp')},
'hdfs-site.xml':{'dfs.replication':'2','dfs.permissions.enabled':'false','dfs.namenode.name.dir':'file://'+str(state/'name'),'dfs.datanode.data.dir':'file://'+str(state/'data1'),'dfs.namenode.http-address':'0.0.0.0:19870','dfs.namenode.rpc-address':'localhost:19000','dfs.datanode.address':'0.0.0.0:19866','dfs.datanode.http.address':'0.0.0.0:19864','dfs.datanode.ipc.address':'0.0.0.0:19867'},
'mapred-site.xml':{'mapreduce.framework.name':'yarn','mapreduce.application.classpath':str(h)+'/share/hadoop/mapreduce/*,'+str(h)+'/share/hadoop/mapreduce/lib/*','yarn.app.mapreduce.am.env':'HADOOP_MAPRED_HOME='+str(h),'mapreduce.map.env':'HADOOP_MAPRED_HOME='+str(h),'mapreduce.reduce.env':'HADOOP_MAPRED_HOME='+str(h),'mapreduce.map.memory.mb':'1024','mapreduce.reduce.memory.mb':'1024','yarn.app.mapreduce.am.resource.mb':'1024','mapreduce.map.java.opts':'-Xmx512m','mapreduce.reduce.java.opts':'-Xmx512m','yarn.app.mapreduce.am.command-opts':'-Xmx512m','mapreduce.jobhistory.address':'localhost:11020'},
'yarn-site.xml':{'yarn.resourcemanager.hostname':'localhost','yarn.resourcemanager.webapp.address':'0.0.0.0:18088','yarn.nodemanager.aux-services':'mapreduce_shuffle','yarn.nodemanager.resource.memory-mb':'4096','yarn.nodemanager.resource.cpu-vcores':'8','yarn.scheduler.minimum-allocation-mb':'512','yarn.scheduler.maximum-allocation-mb':'8192','yarn.nodemanager.pmem-check-enabled':'false','yarn.nodemanager.vmem-check-enabled':'false','yarn.log-aggregation-enable':'true','yarn.nodemanager.local-dirs':str(state/'nm1-local'),'yarn.nodemanager.log-dirs':str(state/'nm1-logs'),'yarn.nodemanager.address':'localhost:14541','yarn.nodemanager.localizer.address':'localhost:18040','yarn.nodemanager.webapp.address':'0.0.0.0:18042','yarn.nodemanager.env-whitelist':'JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME,PATH,LANG,TZ'},
'capacity-scheduler.xml':{'yarn.scheduler.capacity.root.queues':'default,dev','yarn.scheduler.capacity.root.default.capacity':'70','yarn.scheduler.capacity.root.dev.capacity':'30','yarn.scheduler.capacity.root.dev.maximum-capacity':'50','yarn.scheduler.capacity.maximum-am-resource-percent':'0.5','yarn.scheduler.capacity.root.default.acl_submit_applications':'*','yarn.scheduler.capacity.root.dev.acl_submit_applications':'*','yarn.scheduler.capacity.resource-calculator':'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'}}
for role in ('main','dn2','nm2'):
 conf=base/('conf-'+role);conf.mkdir(exist_ok=True)
 for name,props0 in common.items():
  props=dict(props0)
  if role=='dn2' and name=='hdfs-site.xml':props.update({'dfs.datanode.data.dir':'file://'+str(state/'data2'),'dfs.datanode.address':'0.0.0.0:19876','dfs.datanode.http.address':'0.0.0.0:19874','dfs.datanode.ipc.address':'0.0.0.0:19877'})
  if role=='nm2' and name=='yarn-site.xml':props.update({'yarn.nodemanager.local-dirs':str(state/'nm2-local'),'yarn.nodemanager.log-dirs':str(state/'nm2-logs'),'yarn.nodemanager.address':'localhost:14542','yarn.nodemanager.localizer.address':'localhost:18050','yarn.nodemanager.webapp.address':'0.0.0.0:18043','mapreduce.shuffle.port':'13563'})
  (conf/name).write_text('<configuration>\n'+''.join(f'<property><name>{k}</name><value>{escape(v)}</value></property>\n' for k,v in props.items())+'</configuration>\n')
 shutil.copy(h/'etc/hadoop/log4j.properties',conf/'log4j.properties')
 (conf/'hadoop-env.sh').write_text('export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\nexport HADOOP_HEAPSIZE_MAX=256\n')
print('Configurations creees dans',base)
