#!/bin/bash

LOGFILE=$1


declare regex="Ran 4 tests"

declare file_content=$( cat "${LOGFILE}" )
if [[ " $file_content " =~ $regex ]] # please note the space before and after the file content
    then
        echo "Test passed!"
    else
        echo "Test failed!"
        exit 1
fi
