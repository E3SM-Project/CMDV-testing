#!/bin/sh

cd /home/ikalash/CMDV/cdashIKT

rm -rf /home/ikalash/CMDV/cdashIKT/repos
rm -rf /home/ikalash/CMDV/cdashIKT/build
rm -rf /home/ikalash/CMDV/cdashIKT/ctest_nightly.cmake.work
rm -rf /home/ikalash/CMDV/cdashIKT/nightly_log*
rm -rf /home/ikalash/CMDV/cdashIKT/results*

export PYTHONPATH=$PYTHONPATH:/home/ikalash/CMDV/lib/python
echo $PYTHONPATH


now=$(date +"%m_%d_%Y-%H_%M")
LOG_FILE=/home/ikalash/CMDV/cdashIKT/nightly_log.txt

eval "env  TEST_DIRECTORY=/home/ikalash/CMDV/cdashIKT SCRIPT_DIRECTORY=/home/ikalash/CMDV/cdashIKT ctest -VV -S /home/ikalash/CMDV/cdashIKT/ctest_nightly.cmake" > $LOG_FILE 2>&1

# Copy a basic installation to /projects/albany for those who like a nightly
# build.
#cp -r build/TrilinosInstall/* /projects/albany/trilinos/nightly/;
#chmod -R a+X /projects/albany/trilinos/nightly;
#chmod -R a+r /projects/albany/trilinos/nightly;
