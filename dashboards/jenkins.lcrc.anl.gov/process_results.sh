echo "processing results"
if [ ! -f test_log.txt ]; then
    echo "process_results.sh: ERROR: file test_log.txt not found"
fi
grep "Test   #" test_log.txt >& results0
grep "Test  #" test_log.txt >& results1 
cat results0 results1 >& results11
grep "Test #" test_log.txt >& results0
cat results11 results0 >& results1
grep " tests failed" test_log.txt >& results2 
cat results1 results2 >& results3
grep "Total Test" test_log.txt >& results4
cat results3 results4 >& results5
grep "(Failed)" test_log.txt >& results6 
cat results5 results6 >& results
echo "" >> results 
echo "The ACME_Climate CDash site can be accessed here: https://my.cdash.org/index.php?project=ACME_Climate" >> results 
echo "" >> results 
rm results0 results1 results11 results2 results3 results4 results5 results6
