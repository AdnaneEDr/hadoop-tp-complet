#!/usr/bin/env bash
# Executer depuis WSL apres demarrer_wsl.sh, ou dans namenode Docker.
set -euo pipefail
if [ -d /opt/donnees ]; then
 TP_ROOT=/opt; RESULT=/opt/resultats/cluster; EX="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.3.jar"
else
 source "$(dirname "$0")/env_wsl.sh"; RESULT="$TP_ROOT/resultats/cluster"
fi
mkdir -p "$RESULT"
exec > >(tee "$RESULT/execution_complete.log") 2>&1
PS4='+ ${LINENO}: ';set -x
BASE=/user/etudiant
java -version; hadoop version; jps
hdfs getconf -confKey dfs.replication
hdfs getconf -confKey fs.defaultFS
hdfs dfsadmin -report
yarn node -list -all
hdfs dfs -mkdir -p "$BASE/tp1/livres" "$BASE/tp1/archives" "$BASE/tp2" "$BASE/tp3"
hdfs dfs -put -f "$TP_ROOT/donnees/bonjour.txt" "$BASE/bonjour.txt"
hdfs dfs -cat "$BASE/bonjour.txt"
for f in carroll-alice shakespeare-hamlet melville-moby_dick austen-emma chesterton-brown; do
 hdfs dfs -put -f "$TP_ROOT/donnees/livres/$f.txt" "$BASE/tp1/livres/"
done
hdfs dfs -ls -h "$BASE/tp1/livres"
hdfs dfs -mkdir -p "$BASE/tp1/tmp/a/b"
hdfs dfs -ls -R "$BASE/tp1"
hdfs dfs -du -s -h "$BASE/tp1/livres"
hdfs dfs -D dfs.blocksize=1048576 -put -f "$TP_ROOT/donnees/livres/bible-kjv.txt" "$BASE/tp1/"
hdfs fsck "$BASE/tp1/bible-kjv.txt" -files -blocks -locations
hdfs dfs -cp "$BASE/tp1/livres/carroll-alice.txt" "$BASE/tp1/archives/"
hdfs dfs -mv "$BASE/tp1/archives/carroll-alice.txt" "$BASE/tp1/archives/alice_2026.txt"
hdfs dfs -rm -r "$BASE/tp1/tmp"
hdfs dfs -setrep -w 1 "$BASE/tp1/livres/austen-emma.txt"
hdfs dfs -setrep 3 "$BASE/tp1/livres/austen-emma.txt"
hdfs fsck "$BASE/tp1/livres/austen-emma.txt" -files -blocks -locations
hdfs dfs -setrep -w 2 "$BASE/tp1/livres/austen-emma.txt"
hdfs dfs -getmerge "$BASE/tp1/livres" "$RESULT/tous.txt"
wc -c "$RESULT/tous.txt"
hdfs dfs -mkdir -p "$BASE/tp1/quota"
hdfs dfsadmin -setQuota 3 "$BASE/tp1/quota"
hdfs dfs -cp "$BASE/tp1/livres/carroll-alice.txt" "$BASE/tp1/quota/"
hdfs dfs -cp "$BASE/tp1/livres/austen-emma.txt" "$BASE/tp1/quota/"
if hdfs dfs -cp "$BASE/tp1/livres/shakespeare-hamlet.txt" "$BASE/tp1/quota/"; then echo 'ERREUR quota non applique';exit 1;fi
hdfs dfs -count -q "$BASE/tp1/quota"
trap 'hdfs dfsadmin -safemode leave >/dev/null 2>&1 || true' EXIT
hdfs dfsadmin -safemode enter
if hdfs dfs -mkdir "$BASE/tp1/interdit";then echo 'ERREUR safe mode';exit 1;fi
hdfs dfs -head "$BASE/bonjour.txt"
hdfs dfsadmin -safemode leave
hadoop jar "$EX" pi 4 1000
hadoop jar "$EX" pi 4 100000
hadoop jar "$EX" wordcount "$BASE/tp1/livres" "$BASE/tp2/wc"
hdfs dfs -cat "$BASE/tp2/wc/part-r-*" > "$RESULT/wordcount_standard.tsv"
sort -k2,2nr "$RESULT/wordcount_standard.tsv" | head -3 || true
yarn queue -status dev
hadoop jar "$EX" pi -D mapreduce.job.queuename=dev 8 100000
JAR="$TP_ROOT/jobs/tp3.jar"
WC=ma.bigdata.tp3.wordcount.WordCountLivres
AK=ma.bigdata.tp3.amis.AmisCommunsK
hadoop jar "$JAR" "$WC" "$BASE/tp1/livres" "$BASE/tp3/wc"
hadoop jar "$JAR" "$WC" -D wc.combiner=false "$BASE/tp1/livres" "$BASE/tp3/wc_sans_combiner"
hadoop jar "$JAR" "$WC" -D wc.longueur.min=3 -D "wc.mots.vides=$(cat "$TP_ROOT/scripts/mots_vides.txt")" "$BASE/tp1/livres" "$BASE/tp3/wc_filtre"
for name in wc wc_sans_combiner wc_filtre;do hdfs dfs -cat "$BASE/tp3/$name/part-r-*" > "$RESULT/$name.tsv";done
cmp "$RESULT/wc.tsv" "$RESULT/wc_sans_combiner.tsv"
hdfs dfs -put -f "$TP_ROOT/donnees/amis.txt" "$TP_ROOT/donnees/amis_asymetrique.txt" "$TP_ROOT/donnees/amis_1000.txt" "$BASE/tp3/"
hadoop jar "$JAR" ma.bigdata.tp3.amis.AmisCommuns "$BASE/tp3/amis.txt" "$BASE/tp3/m1"
hdfs dfs -cat "$BASE/tp3/m1/part-r-*" > "$RESULT/amis_m1.tsv"
for k in 2 3 4;do
 hadoop jar "$JAR" "$AK" -D amis.k="$k" -D amis.statut=true "$BASE/tp3/amis.txt" "$BASE/tp3/k$k"
 hdfs dfs -cat "$BASE/tp3/k$k/part-r-*" > "$RESULT/amis_k$k.tsv"
done
hadoop jar "$JAR" ma.bigdata.tp3.amis.AmisCommuns "$BASE/tp3/amis_asymetrique.txt" "$BASE/tp3/asym_m1"
hadoop jar "$JAR" "$AK" -D amis.k=2 "$BASE/tp3/amis_asymetrique.txt" "$BASE/tp3/asym_k2"
for k in 2 3 4;do
 hadoop jar "$JAR" "$AK" -D amis.k="$k" -D amis.min=3 -D amis.statut=true "$BASE/tp3/amis_1000.txt" "$BASE/tp3/grand_k$k"
 hdfs dfs -cat "$BASE/tp3/grand_k$k/part-r-*" > "$RESULT/amis_1000_k${k}_min3.tsv"
done
# Faire l'ajout APRES WordCount pour ne pas fausser les resultats de reference.
printf 'THE END\n' > "$RESULT/fin.txt"
hdfs dfs -appendToFile "$RESULT/fin.txt" "$BASE/tp1/livres/carroll-alice.txt"
hdfs dfs -tail "$BASE/tp1/livres/carroll-alice.txt"
yarn application -list -appStates ALL
echo 'TP cluster termine'
