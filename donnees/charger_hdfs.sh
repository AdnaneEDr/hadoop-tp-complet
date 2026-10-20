#!/bin/bash
# H. BADIR AI - TP Hadoop : charge (ou recharge) toutes les données des TP dans HDFS.
# Docker : docker compose exec namenode bash /opt/donnees/charger_hdfs.sh
set -e
export LC_ALL=C.UTF-8
D=${1:-/opt/donnees}
U=/user/etudiant
hdfs dfs -mkdir -p $U/tp1/livres $U/tp1/archives $U/tp3
# TP-1 / TP-2 / TP-3 (cas 1) : les 5 livres
hdfs dfs -put -f $D/livres/carroll-alice.txt $D/livres/shakespeare-hamlet.txt \
  $D/livres/melville-moby_dick.txt $D/livres/austen-emma.txt $D/livres/chesterton-brown.txt $U/tp1/livres/
# TP-1 (pas à pas, étape 3) : la Bible, en blocs de 1 Mo
hdfs dfs -D dfs.blocksize=1048576 -put -f $D/livres/bible-kjv.txt $U/tp1/
# TP-3 (cas 2) : les réseaux d'amis
hdfs dfs -put -f $D/amis.txt $D/amis_asymetrique.txt $D/amis_1000.txt $D/amis_10000.txt $U/tp3/
hdfs dfs -ls -R $U | grep -v "^d"
echo "OK : données chargées dans HDFS sous $U"
