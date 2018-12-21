#!/bin/bash

CMDV_PY_PATH=$1
echo "CMDV_PY_PATH ="$CMDV_PY_PATH

CLONE_DIR_PATH=$2
echo "CLONE_DIR_PATH ="$CLONE_DIR_PATH

PY_DIR=$3
echo "PY_DIR ="$PY_DIR

sed -i -e "s,'clone-dir.sh',aaaaaa,g" $CMDV_PY_PATH/CMDV.py
sed -i -e "s,aaaaaa,'$CLONE_DIR_PATH/clone-dir.sh',g" $CMDV_PY_PATH/CMDV.py
sed -i -e "s,../lib/python/,bbbbbb,g" unittest-discovery.test.yaml
sed -i -e "s,bbbbbb,$PY_DIR,g" unittest-discovery.test.yaml
