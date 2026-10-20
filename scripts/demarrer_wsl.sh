#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env_wsl.sh"
python3 "$TP_ROOT/scripts/configurer_wsl.py"
if [ ! -d "$HOME/tp-hadoop-runtime/etat/name/current" ]; then hdfs namenode -format -nonInteractive; fi
HADOOP_IDENT_STRING=tp-main hdfs --daemon start namenode
HADOOP_IDENT_STRING=tp-dn1 hdfs --daemon start datanode
HADOOP_CONF_DIR="$HOME/tp-hadoop-runtime/conf-dn2" HADOOP_IDENT_STRING=tp-dn2 hdfs --daemon start datanode
HADOOP_IDENT_STRING=tp-rm yarn --daemon start resourcemanager
HADOOP_IDENT_STRING=tp-nm1 yarn --daemon start nodemanager
HADOOP_CONF_DIR="$HOME/tp-hadoop-runtime/conf-nm2" HADOOP_IDENT_STRING=tp-nm2 yarn --daemon start nodemanager
echo 'HDFS : http://localhost:19870 ; YARN : http://localhost:18088'
