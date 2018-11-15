#! /usr/bin/env python

import unittest
import os
"""
ResultReporter module:

    Provide two simple classes, ResultWriter and ResultReader, that respectively
    write and read a file with simple pass/fail results, in the results-file
    convention, of a series of one or more tests. Sample usage within a script:

        from ResultReporter import ResultWriter, ResultReader
        writer = ResultWriter('results.log')
        # Perform a test, putting the results in boolean variable 'result'...
        name = 'Test 1'
        if result:
            writer.report_test_passed(name)
        else:
            writer.report_test_failed(name)
        # Perform a second test, putting the results in 'result' again...
        # This time, use a different reporting method
        name = 'Test 2'
        writer.report_test(name, result)
        # ...
        writer.finished()

        reader = ResultReader('results.log')
        assert reader.num_tests == 2
        assert reader.all_passed
"""

################################################################################

from __future__ import print_function
import sys

################################################################################


class ResultWriter(object):
    """
    A simple class that writes a file with simple pass/fail results of a series
    of one or more tests. The constructor takes a filename to write to
    """

    ############################################################################

    def __init__(self, filename):
        """
        Construct ResultWriter object and intialize the results output file

        Arguments:
            filename  -      Name of the results file to be written
        """
        self.__filename = filename
        self.__file = None
        self.reopen()

    ############################################################################

    def reopen(self):
        """
        If the file is not open, open it. If the file is open, close it and then
        reopen it
        """
        if self.__file is None:
            self.__file = open(self.__filename, "w")
        else:
            self.finished()
            self.reopen()

    ############################################################################

    def finished(self):
        """
        If the file is open, close it, and set the ResultWriter object status
        to closed
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

        Arguments:
            filename  -      Name of the results fiel to be written
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

        Arguments:
            name  -      Name of the test to be reported
        """
        if self.__file:
            self.__file.write("%s: Test PASSED\n" % name)
        else:
            raise IOError("ResultWriter file '%s' is not open")

    ############################################################################

    def report_test_failed(self, name):
        """
        Write a line to the results file, in the results-file convention,
        indicating that the named test failed

        Arguments:
            name  -      Name of the test to be reported
        """
        if self.__file:
            self.__file.write("%s: Test FAILED\n" % name)
        else:
            raise IOError("ResultWriter file '%s' is not open")

    ############################################################################

    def report_test(self, name, result):
        """
        Write a line to the results file, in the results-file convention,
        indicating that the named test passed if result == True, or failed if
        result == False

        Arguments:
            name    -    Name of the test to be reported
            result  -    Boolean result of the test
        """
        if result:
            self.report_test_passed(name)
        else:
            self.report_test_failed(name)

################################################################################


class ResultReader(object):
    """
    A simple class that reads a file written by a ResultsWriter object and
    provides various attributes about statistics of the results file. The
    constructor takes a filename to read from.

    Attributes:
        text_data     -  A string with the results file contents
        test_names    -  A list of strings of the valid test names
        test_results  -  A list of strings of the valid test results
        num_tests     -  The number of valid test results reported
        num_passed    -  The number of tests reported to pass
        num_failed    -  The number of tests reported to fail
        all_passed    -  True if all reported tests passed. If num_tests == 0,
                         this will be False
    """

    ############################################################################

    def __init__(self, filename, handle_errors_as="exceptions"):
        """
        Construct a ResultsReader object, read the contents of the given
        filename, parse it and store the statistics

        Arguments:
            filename          -  Name of the results file to be read
            handle_errors_as  -  Error handling method.  Valid values are
                                 "exceptions" and "warnings". Defaults to
                                 "exceptions"
        """
        if handle_errors_as not in ["exceptions", "warnings"]:
            raise ValueError(("'ResultReader' constructor argument " +
                              "'handle_errors_as' must be either\n" +
                              "'exceptions' or 'warnings'. Got value '%s'") %
                             handle_errors_as)
        self.__error_handler = handle_errors_as
        self.text_data = open(filename, "r").read()
        self._parse_data()

    ############################################################################

    def _parse_data(self):
        """
        Parse the text data read at construction and populate the ResultReader
        attributes
        """
        self.test_names = []
        self.test_results = []
        self.num_tests = 0
        self.num_passed = 0
        self.num_failed = 0
        lines = self.text_data.split('\n')
        for line in lines:
            if line == "":
                break
            try:
                name, result = line.split(':')
                name = name.strip()
                result = result.strip()
                if result not in ["Test PASSED", "Test FAILED"]:
                    raise ValueError(("Test result '%s' is neither 'Test " +
                                      "PASSED' nor 'Test FAILED'") % result)
                self.test_names.append(name)
                self.test_results.append(result)
                self.num_tests += 1
                if result == "Test PASSED":
                    self.num_passed += 1
                else:
                    self.num_failed += 1
            except ValueError as e:
                if self.__error_handler == "warnings":
                    print("Warning:", file=sys.stderr)
                    print("    Line    = '%s'" % line, file=sys.stderr)
                    print("    Message = '%s'" % e, file=sys.stderr)
                else:
                    raise e
        self.all_passed = (self.num_tests > 0 and
                           self.num_passed == self.num_tests)

################################################################################


try:
    import StringIO  # Python 2
except ImportError:
    from io import StringIO  # Python 3

################################################################################


class ResultWriterTestCase(unittest.TestCase):
    """
    TestCase for ResultWriter class
    """

    ############################################################################

    def setUp(self):
        self.name = 'test.log'
        self.rr = ResultWriter(self.name)

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
        self.assertEqual(open(self.name, "r").read(),
                         "Convergence test: Test PASSED\n")

    ############################################################################

    def testReportTestFailed(self):
        self.rr.report_test_failed('Convergence test')
        self.rr.finished()
        self.assertEqual(open(self.name, "r").read(),
                         "Convergence test: Test FAILED\n")

    ############################################################################

    def testReportTest(self):
        self.rr.report_test('Convergence test 1', True)
        self.rr.report_test('Convergence test 2', False)
        self.rr.finished()
        self.assertEqual(open(self.name, "r").read(),
                         "Convergence test 1: Test PASSED\n" +
                         "Convergence test 2: Test FAILED\n")

################################################################################


class ResultReaderTestCase(unittest.TestCase):
    """
    TestCase for ResultReader class
    """

    ############################################################################

    def setUp(self):
        self.name = 'test.log'
        self.stderr = sys.stderr
        sys.stderr = StringIO.StringIO()

    ############################################################################

    def tearDown(self):
        if os.path.isfile(self.name):
            os.remove(self.name)
        sys.stderr.close()
        sys.stderr = self.stderr

    ############################################################################

    def file_all_pass(self):
        rw = ResultWriter(self.name)
        rw.report_test("Test 1", True)
        rw.report_test("Test 2", True)
        rw.report_test("Test 3", True)

    ############################################################################

    def file_some_fail(self):
        rw = ResultWriter(self.name)
        rw.report_test("Test 1", False)
        rw.report_test("Test 2", True)
        rw.report_test("Test 3", False)

    ############################################################################

    def file_no_colon(self):
        f = open(self.name, "w")
        f.write("This line has no colon\n")
        f.write("Neither does this one\n")
        f.close()

    ############################################################################

    def file_bad_result(self):
        f = open(self.name, "w")
        f.write("Test 1: Test PAST\n")
        f.close()

    ############################################################################

    def testAllPass(self):
        self.file_all_pass()
        rr = ResultReader(self.name)
        self.assertEqual(rr.num_tests, 3)
        self.assertTrue(rr.all_passed)

    ############################################################################

    def testSomeFailed(self):
        self.file_some_fail()
        rr = ResultReader(self.name)
        self.assertEqual(rr.num_tests, 3)
        self.assertFalse(rr.all_passed)

    ############################################################################

    def testNoColonException(self):
        self.file_no_colon()
        self.assertRaises(ValueError, ResultReader, self.name)

    ############################################################################

    def testNoColonWarning(self):
        self.file_no_colon()
        rr = ResultReader(self.name, "warnings")
        self.assertEqual(rr.num_tests, 0)
        warning = "Warning:\n" + \
                  "    Line    = 'This line has no colon'\n" + \
                  "    Message = 'need more than 1 value to unpack'\n" + \
                  "Warning:\n" + \
                  "    Line    = 'Neither does this one'\n" + \
                  "    Message = 'need more than 1 value to unpack'\n"
        self.assertEqual(sys.stderr.getvalue(), warning)

    ############################################################################

    def testBadResultException(self):
        self.file_bad_result()
        self.assertRaises(ValueError, ResultReader, self.name)

    ############################################################################

    def testBadResultWarning(self):
        self.file_bad_result()
        rr = ResultReader(self.name, "warnings")
        self.assertEqual(rr.num_tests, 0)
        warning = "Warning:\n" + \
                  "    Line    = 'Test 1: Test PAST'\n" + \
                  "    Message = 'Test result 'Test PAST' is neither 'Test " + \
                  "PASSED' nor 'Test FAILED''\n"
        self.assertEqual(sys.stderr.getvalue(), warning)

    ############################################################################

    def testNoValidResults(self):
        self.file_bad_result()
        rr = ResultReader(self.name, "warnings")
        self.assertEqual(rr.num_tests, 0)
        self.assertFalse(rr.all_passed)

################################################################################


if __name__ == "__main__":
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(ResultWriterTestCase))
    suite.addTest(unittest.makeSuite(ResultReaderTestCase))
    print("*****************************")
    print("Testing ResultReporter module")
    print("*****************************")
    verbosity = 2
    result = unittest.TextTestRunner(verbosity=verbosity).run(suite)
