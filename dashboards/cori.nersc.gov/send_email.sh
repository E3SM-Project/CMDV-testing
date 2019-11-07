#!/bin/bash

#source $1 

TTT=`grep "(Failed)" nightly_log.txt -c`
TTTT=`grep "(Not Run)" nightly_log.txt -c`
TTTTT=`grep "(Timeout)" nightly_log.txt -c`
TT=`grep "...   Passed" nightly_log.txt -c`

/bin/mail -s "cmdv-test-runner, cori.nersc.gov: $TT tests passed, $TTT tests failed, $TTTT tests not run, $TTTTT timeouts" "ikalash@sandia.gov" -F "Irina Tezaur" < results
