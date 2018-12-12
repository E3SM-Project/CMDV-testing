#!/bin/bash
# Script to test run_acme.template.csh
#   Absolute path to RUN_ACME_DIR is supplied by CMake configuration
#   Includes Batch-system specific method for checking queue
#      Supports:  pbs, slurm, none
#

#Case directories  are in HOME unless SCRATCH is specified
if [ -z "$SCRATCH" ]; then
  SCRATCH=${HOME}
fi

if [ ! -d "${SCRATCH}/ACME_simulations" ]; then
  mkdir ${SCRATCH}/ACME_simulations
fi

case_name="default.default.A_WCYCL1850_template.ne4np4_oQU240"
case_scratch="${SCRATCH}/ACME_simulations/${case_name}"
case_dir="${case_scratch}/case_scripts"
public_scratch="${SCRATCH}"
run_acme_log="${public_scratch}/run_acme.log"

#Verify the case is already deleted
rm -rf ${case_scratch}

# Change to ACME dir, where script must be run, using CMake for absolute path
echo "CTEST_FULL_OUTPUT" #This magic string stops CDash from truncating output
echo "**********************************************"
echo "Configure"

cd /CMDV/CMDV-testing/


# Run run_acme
# echo "CTEST_FULL_OUTPUT" #This magic string stops CDash from truncating output
echo
echo "**********************************************"
echo "Running UnitTest/Verification suite :"
echo

# echo `python ./cmdv-test-runner.py --config /CMDV/CMDV-testing/Config/test_config.json --archive True`
echo `python ./scripts/cmdv-test-runner --help`
# cat CaseStatus so it is seen on CDash
echo
echo "**********************************************"
echo "Deploy"
echo
ls tmp
date 
# We want to wait for the last job to have been submitted to be complete
# Note that this assumes that only one job is submitted per case.submit;
# any more would require us to loop and wait for each of them
echo
echo "**********************************************"
echo "Build"
echo

echo
echo "**********************************************"
echo "Test"
# echo `python ./cmdv-test-runner.py --config /CMDV/CMDV-testing/Config/test_config.json --archive True`
echo `python ./scripts/cmdv-test-runner --test Tests/unittest-discovery.test.yaml`

# echo "CTEST_FULL_OUTPUT" #This magic string stops CDash from truncating output
# echo
# echo
# echo "**********************************************"
# echo "Deploy"
# echo
# ls tmp


