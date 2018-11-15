from Archive.Archive import Archive
import os
import logging
import sys
from pprint import pprint
import subprocess

from Report.LocalLogging import getLogger

logger = None
logger = getLogger(__name__)


class CDash(Archive):
    # class CDash:

    """docstring for ClassName"""

    def __init__(self, config=None, logger_name=None, report=None):
        #super(Archive, self).__init__()
        Archive.__init__(self, logger_name=logger_name)

        if not config:
            logger.error("Missing config")
            sys.exit(1)

        self.name = "cdash"
        self.url = "localhost"

    def push(self, directory=None, report=None):

        directory = directory if directory else self.source

        if not (directory and os.path.isdir(directory)):
            logger.error("Can't archive, no directory " +
                         directory if directory else 'not defined')

        else:
            logger.info("Archiving " + directory)

        if self.logfile and os.path.isfile(self.logfile):
            pass

        report_file = report.write(directory)
        f = open(report_file, "w")
        f.write("Test session: " + (report.name if report.name else "default") +
                " (" + report.date + ")\n")
        f.write("Number test runs: " + str(len(report.tests)) + "\n")
        f.write("Report: \n")
        for test in report.tests:
            f.write(test.name + ":\t" +
                    test.status if test.status else "unknown \n")
            for step in test.steps:
                f.write(
                    ":".join([step.name, (step.status if step.status else "success")]) + "\t")
            f.write("\n")
        f.close()

        os.environ["CMDV_TEST_RUNNER_RUN_DIR"] = directory if directory else "./"
        os.environ["CMDV_TEST_RUNNER_LOG"] = report_file

        current_dir = os.getcwd()
        os.chdir("/CMDV/CMDV-testing/tmp")

        command = "ctest -D Experimental"

        process = subprocess.Popen(
            [command],  stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output, errs = process.communicate()
        if output:
            logger.info("Output:" + output.decode())
        if errs:
            logger.error(output.decode())
            logger.error(errs.decode())

        os.chdir(current_dir)

        # Collect files for deploy - build - test - compare
        # Create CMAKE file
        # Create CTEST file
        # Execute ctest -D Experimental in test/run dir
        # Upload to cdash
