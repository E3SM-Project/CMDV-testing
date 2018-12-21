#!/bin/bash

PY_DIR=$1
echo "PY_DIR ="$PY_DIR

CLONE_DIR_PATH=$2
echo "CLONE_DIR_PATH ="$CLONE_DIR_PATH

sed -i -e "s,'clone-dir.sh',aaaaaa,g" $PY_DIR/Workflows/CMDV.py
sed -i -e "s,aaaaaa,'$CLONE_DIR_PATH/clone-dir.sh',g" $PY_DIR/Workflows/CMDV.py
sed -i -e "s,../lib/python/,bbbbbb,g" unittest-discovery.test.yaml
sed -i -e "s,bbbbbb,$PY_DIR,g" unittest-discovery.test.yaml
