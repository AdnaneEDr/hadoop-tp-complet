#!/usr/bin/env bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME="$HOME/tp-hadoop-runtime/hadoop-3.4.3"
export HADOOP_CONF_DIR="$HOME/tp-hadoop-runtime/conf-main"
export HADOOP_LOG_DIR="$HOME/tp-hadoop-runtime/logs"
export HADOOP_PID_DIR="$HOME/tp-hadoop-runtime/pids"
export HADOOP_HEAPSIZE_MAX=256
export PATH="$JAVA_HOME/bin:$HADOOP_HOME/bin:$PATH"
export LC_ALL=C.UTF-8
export TP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export EX="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.3.jar"
mkdir -p "$HADOOP_LOG_DIR" "$HADOOP_PID_DIR" "$TP_ROOT/jobs" "$TP_ROOT/resultats/cluster" "$TP_ROOT/captures"
