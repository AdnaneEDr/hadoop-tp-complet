@echo off
REM H. BADIR AI - TP Hadoop : chargement des données dans HDFS (Windows natif)
REM Usage : double-clic, ou "charger_hdfs.cmd" depuis le dossier donnees
set D=%~dp0
set U=/user/etudiant
call hdfs dfs -mkdir -p %U%/tp1/livres %U%/tp1/archives %U%/tp3
call hdfs dfs -put -f "%D%livres\carroll-alice.txt" "%D%livres\shakespeare-hamlet.txt" "%D%livres\melville-moby_dick.txt" "%D%livres\austen-emma.txt" "%D%livres\chesterton-brown.txt" %U%/tp1/livres/
call hdfs dfs -D dfs.blocksize=1048576 -put -f "%D%livres\bible-kjv.txt" %U%/tp1/
call hdfs dfs -put -f "%D%amis.txt" "%D%amis_asymetrique.txt" "%D%amis_1000.txt" "%D%amis_10000.txt" %U%/tp3/
call hdfs dfs -ls -R %U%
echo OK : donnees chargees dans HDFS sous %U%
pause
