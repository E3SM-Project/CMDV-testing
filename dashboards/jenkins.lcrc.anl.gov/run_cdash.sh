#!/bin/bash
. ./init.sh #add to pythonpath and path
cd dashboards/jenkins.lcrc.anl.gov
LOG_FILE=nightly_log.txt
eval "bash do_cmake" > $LOG_FILE 2>&1
eval "env TEST_DIRECTORY=$PWD SCRIPT_DIRECTORY=$PWD ctest -VV -s $PWD/ctest_jenkins.cmake" >> $LOG_FILE 2>&1
bash process_results.sh
