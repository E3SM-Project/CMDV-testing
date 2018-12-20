#!/bin/sh

rm -rf repos
rm -rf build
rm -rf ctest_nightly.cmake.work
rm -rf nightly_log*
rm -rf results*

now=$(date +"%m_%d_%Y-%H_%M")
LOG_FILE=nightly_log.txt

#eval "env  TEST_DIRECTORY=/home/ikalash/CMDV/cdashIKT SCRIPT_DIRECTORY=/home/ikalash/CMDV/cdashIKT ctest -VV -S /home/ikalash/CMDV/cdashIKT/ctest_nightly.cmake" > $LOG_FILE 2>&1
eval "env  TEST_DIRECTORY=$PWD SCRIPT_DIRECTORY=$PWD ctest -VV -S $PWD/ctest_nightly.cmake" > $LOG_FILE 2>&1

