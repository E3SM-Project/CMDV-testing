#!/bin/bash
. ./init.sh #add to pythonpath and path
cd dashboards/jenkins.lcrc.anl.gov/run_cdash.sh
LOG_FILE=nightly_log.txt
eval "env TEST_DIRECTORY=$PWD SCRIPT_DIRECTORY=$PWD ctest -VV -s $PWD/ctest_jenkins.cmake" > $LOG_FILE 2>&1
bash process_results.sh
