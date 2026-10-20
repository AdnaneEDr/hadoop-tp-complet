#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env_wsl.sh"
mkdir -p "$TP_ROOT/tp3/target/classes"
find "$TP_ROOT/tp3/src/main/java" -name '*.java' > "$TP_ROOT/tp3/target/sources.txt"
javac --release 8 -encoding UTF-8 -cp "$(hadoop classpath --glob)" -d "$TP_ROOT/tp3/target/classes" @"$TP_ROOT/tp3/target/sources.txt"
jar cf "$TP_ROOT/jobs/tp3.jar" -C "$TP_ROOT/tp3/target/classes" .
echo 'Compilation terminee : jobs/tp3.jar'
