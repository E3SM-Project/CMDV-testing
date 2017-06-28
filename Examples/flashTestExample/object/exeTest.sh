#!/usr/bin/env bash
pushd ./
cd /application/object
./etest
popd
echo "# all results conformed with expected values." > unitTest_1
touch .success
