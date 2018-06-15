#! /usr/bin/env python

"""
ResultReporter module:

    Provide a simple class, ResultReporter, that writes a file with simple
    pass/fail results, in the results-file convention, of a series of one or
    more tests. Sample usage within a script:

        from ResultReporter import ResultReporter
        reporter = ResultReporter('results.log')
        # Perform a test, putting the results in variable 'result'...
        name = 'Test 1'
        if result:
            reporter.report_test_passed(name)
        else:
            reporter.report_test_failed(name)
        # Perform a second test, putting the results in 'result' again...
        name = 'Test 2'
        if result:
            reporter.report_test_passed(name)
        else:
            reporter.report_test_failed(name)
        # ...
        reporter.finished()
"""

################################################################################

class ResultReporter(object):
    """
    A simple class that writes a file with simple pass/fail results of a series
    of one or more tests. The constructor takes a filename to write to.
    """

    ############################################################################

    def __init__(self, filename):
        """
        Construct ResultReporter object and intialize the output file.
        """
        self.__filename = filename
        self.__file = None
        self.reopen()

    ############################################################################

    def reopen(self):
        """
        If the file is not open, open it. If the file is open, close it and then
        reopen it.
        """
        if self.__file is None:
            self.__file = open(self.__filename, "w")
        else:
            self.finished()
            self.reopen()

    ############################################################################

    def finished(self):
        """
        If the file is open, close it, and set the ResultReporter object status
        to closed.
        """
        if self.__file:
            self.__file.close()
            self.__file = None

    ############################################################################

    def bool_status(self):
        """
        Return the status of the output file: True for an open file, False for a
        closed file
        """
        return not self.__file is None

    ############################################################################

    def str_status(self):
        """
        Return the status of the output file: "open" for an open file, "closed"
        for a closed file
        """
        if self.__file is None:
            return "closed"
        else:
            return "open"

    ############################################################################

    def set_filename(self, filename):
        """
        Set the filename for the results file for the next time it is opened
        """
        self.__filename = filename

    ############################################################################

    def get_filename(self):
        """
        Return the filename for the results file for the next time it is opened
        """
        return self.__filename

    ############################################################################

    def report_test_passed(self, name):
        """
        Write a line to the results file, in the results-file convention,
        indicating that the named test passed
        """
        if self.__file:
            self.__file.write("%s: Test PASSED" % name)
        else:
            raise IOError("ResultReporter file '%s' is not open")

    ############################################################################

    def report_test_failed(self, name):
        """
        Write a line to the results file, in the results-file convention,
        indicating that the named test failed
        """
        if self.__file:
            self.__file.write("%s: Test FAILED" % name)
        else:
            raise IOError("ResultReporter file '%s' is not open")

################################################################################

import unittest
import os

class ResultReporterTestCase(unittest.TestCase):
    """
    TestCase for ResultReporter class
    """

    ############################################################################

    def setUp(self):
        self.name = 'test.log'
        self.rr   = ResultReporter(self.name)

    ############################################################################

    def tearDown(self):
        if self.rr.bool_status():
            self.rr.finished()
        if os.path.isfile(self.name):
            os.remove(self.name)
        new_name = self.rr.get_filename()
        if new_name != self.name:
            if os.path.isfile(new_name):
                os.remove(new_name)

    ############################################################################

    def testConstructor(self):
        self.assertTrue(os.path.isfile(self.name))

    ############################################################################

    def testReopen(self):
        self.rr.finished()
        new_name = 'new_test.log'
        self.rr.set_filename(new_name)
        self.rr.reopen()
        self.assertTrue(os.path.isfile(new_name))

    ############################################################################

    def testFinished(self):
        self.assertTrue(self.rr.bool_status())
        self.rr.finished()
        self.assertFalse(self.rr.bool_status())

    ############################################################################

    def testBoolStatus(self):
        self.assertTrue(self.rr.bool_status())
        self.rr.finished()
        self.assertFalse(self.rr.bool_status())

    ############################################################################

    def testStrStatus(self):
        self.assertEqual(self.rr.str_status(), "open")
        self.rr.finished()
        self.assertEqual(self.rr.str_status(), "closed")

    ############################################################################

    def testSetFilename(self):
        self.rr.finished()
        new_name = 'new_test.log'
        self.rr.set_filename(new_name)
        self.assertEqual(self.rr.get_filename(), new_name)

    ############################################################################

    def testGetFilename(self):
        self.assertEqual(self.rr.get_filename(), self.name)

    ############################################################################

    def testReportTestPassed(self):
        self.rr.report_test_passed('Convergence test')
        self.rr.finished()
        self.assertEqual(open(self.name,"r").read(),
                         "Convergence test: Test PASSED")

    ############################################################################

    def testReportTestFailed(self):
        self.rr.report_test_failed('Convergence test')
        self.rr.finished()
        self.assertEqual(open(self.name,"r").read(),
                         "Convergence test: Test FAILED")

################################################################################

if __name__ == "__main__":
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(ResultReporterTestCase))
    print("****************************")
    print("Testing ResultReporter class")
    print("****************************")
    verbosity = 2
    result = unittest.TextTestRunner(verbosity=verbosity).run(suite)
