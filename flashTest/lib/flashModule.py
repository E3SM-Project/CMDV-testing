import os, re, time
import secondsToHuman
from getProcessResults import getProcessResults
from strategyTemplates import *

######################################
##  PRE-PROCESS, SETUP, COMPILE, &  ##
##  EXECUTE FOR ALL FLASH PROBLEMS  ##
######################################

class FlashEntryPoint(EntryPointTemplate):
  def entryPoint1(self):
    log           = self.masterDict["log"]            # guaranteed to exist by flashTest.py
    flashTestOpts = self.masterDict["flashTestOpts"]  # guaranteed to exist by flashTest.py

    ##############################
    ##  CHECK FOR FLASH SOURCE  ##
    ##############################

    pathToFlash = flashTestOpts.get("-z","")
    if not pathToFlash:
      # check if we got a path to FLASH from the config file
      pathToFlash = self.masterDict.get("pathToFlash","")
      # make sure we have an absolute path
      if pathToFlash and not os.path.isabs(pathToFlash):
        pathToFlash = os.path.join(pathToFlashTest, pathToFlash)
    else:
      # make sure we have an absolute path
      if not os.path.isabs(pathToFlash):
        pathToFlash = os.path.join(os.getcwd(), pathToFlash)

    if not pathToFlash:
      log.err("You must provide a path to a copy of the FLASH source\n" +
              "either in a \"config\" file or with the \"-z\" option.")
      return False
    elif not os.path.isdir(pathToFlash):
      log.err("\"%s\" does not exist or is not a directory." % pathToFlash)

    self.masterDict["pathToFlash"] = pathToFlash

    ####################################
    ##  UPDATE FLASH SOURCE IF ASKED  ##
    ####################################

    pathToInvocationDir = self.masterDict["pathToInvocationDir"]  # guaranteed to exist by flashTest.py

    if flashTestOpts.has_key("-u"):
      updateScript = self.masterDict.get("updateScript","").strip()
      if updateScript:
        log.stp("Attempting to update FLASH source at \"%s\" with \"%s\"" % (pathToFlash, updateScript))

        cwd = os.getcwd()
        os.chdir(pathToFlash)

        updateOutput = ""
        out, err, duration, exitStatus = getProcessResults(updateScript)
        if err:
          log.err("Unable to update FLASH source.\n" + err)
          return False
        elif exitStatus != 0:
          log.err("Exit status %s indicates error updating FLASH source" % exitStatus)
          return False
        else:
          log.info("FLASH source was successfully updated")
          open(os.path.join(pathToInvocationDir, "update_output"),"w").write(out)
  
        os.chdir(cwd)
      else:
        log.err("\"-u\" passed to command line but no key \"updateScript\"\n" +
                "found in \"config\". Unable to update FLASH source")
        return False
    else:
      log.warn("FLASH source at \"%s\" was not updated" % pathToFlash)
    
    return True


  def entryPoint2(self):
    testPath = self.masterDict["testPath"]  # guaranteed to exist by flashTest.py
    firstElement = testPath.split("/",1)[0]

    # If this is a Default test, give it a special setupper component
    # (will be be automatically installed based on value in 'masterDict')
    if firstElement == "Default":
      self.masterDict["setupper"] = "DefaultSetupper"

    # Write some info into "linkAttributes" for use by FlashTestView
    if firstElement == "Comparison":
      pathToBuildDir = self.masterDict["pathToBuildDir"]  # guaranteed to exist by flashTest.py
      tester = self.masterDict.get("tester", "SfocuTester")
      text = "testerClass: %s" % tester
      open(os.path.join(pathToBuildDir, "linkAttributes"),"w").write(text)


  def entryPoint3(self):
    testPath = self.masterDict["testPath"]  # guaranteed to exist by flashTest.py
    firstElement = testPath.split("/",1)[0]

    # give this test an appropriate executer component (will be
    # be automatically installed based on value in 'masterDict')
    if firstElement == "Comparison":
      self.masterDict["executer"] = "ComparisonExecuter"
    elif firstElement == "Restart":
      self.masterDict["executer"] = "RestartExecuter"

    # give this test an appropriate tester component (will be
    # be automatically installed based on value in 'masterDict')
    if firstElement == "Comparison":
      tester = self.masterDict.get("tester")
      if tester == "GridDumpTester":
        self.masterDict["tester"] = "GridDumpTester"
      else:
        self.masterDict["tester"] = "SfocuTester"
    elif firstElement == "Restart":
      self.masterDict["tester"] = "RestartTester"
    elif firstElement == "UnitTest":
      self.masterDict["tester"] = "UnitTester"


class FlashSetupper(SetupperTemplate):
  def setup(self):
    """
    run the FLASH setup script

                log: pointer to FlashTest logfile object
        pathToFlash: abs path to top-level FLASH directory
                     containing all code pertaining to FLASH setups
     pathToBuildDir: abs path to the output dir for this build
    pathToFlashTest: abs path to the top-level FlashTest directory
          setupName: name of this Flash setup (Sod, Sedov, etc.)
       setupOptions: options passed to Flash setup script
    """
    log             = self.masterDict["log"]              # guaranteed to exist by flashTest.py
    pathToFlash     = self.masterDict["pathToFlash"]      # guaranteed to exist by flashTest.py
    pathToBuildDir  = self.masterDict["pathToBuildDir"]   # guaranteed to exist by flashTest.py
    pathToFlashTest = self.masterDict["pathToFlashTest"]  # guaranteed to exist by flashTest.py

    setupName      = self.masterDict.get("setupName","")
    setupOptions   = self.masterDict.get("setupOptions","")

    if len(setupName) == 0:
      log.err("No setup name provided.\n" +
              "Skipping this build.")
      return False

    pathToDotSuccess = os.path.join(pathToFlash, "object", ".success")
    if os.path.isfile(pathToDotSuccess):
      os.remove(pathToDotSuccess)

    # setup script
    pathToFlashSetupScript = os.path.join(pathToFlash, "setup")
    script = "%s %s %s" % (pathToFlashSetupScript, setupName, setupOptions)

    # record setup invocation
    open(os.path.join(pathToBuildDir, "setup_call"),"w").write(script)

    # log timestamp of command
    log.stp(script)

    # cd to FLASH source
    os.chdir(pathToFlash)

    # get stdout/stderr and duration of setup and write to file
    out, err, duration, exitStatus = getProcessResults(script)
    open(os.path.join(pathToBuildDir, "setup_output"),"w").write(out)
    if len(err) > 0:
      open(os.path.join(pathToBuildDir, "setup_error"),"w").write(err)

    # cd back to flashTest
    os.chdir(pathToFlashTest)

    # return the success or failure of the setup
    if os.path.isfile(pathToDotSuccess):
      log.stp("setup was successful")
      os.remove(pathToDotSuccess)
      return True
    else:
      log.stp("setup was not successful")
      return False


class FlashCompiler(CompilerTemplate):
  def compile(self):
    """
    compile FLASH

       pathToFlash: abs path up to the top-level FLASH directory
    pathToBuildDir: abs path up to the output dir for this build
       pathToGmake: abs path to the gmake utility
           exeName: name to be given to the FLASH executable
    """
    log             = self.masterDict["log"]              # guaranteed to exist by flashTest.py
    pathToFlash     = self.masterDict["pathToFlash"]      # guaranteed to exist by flashTest.py
    pathToBuildDir  = self.masterDict["pathToBuildDir"]   # guaranteed to exist by flashTest.py
    pathToFlashTest = self.masterDict["pathToFlashTest"]  # guaranteed to exist by flashTest.py

    pathToGmake    = self.masterDict.get("pathToGmake", "gmake")
    exeName        = self.masterDict.get("exeName", "flash-exe")

    pathToDotSuccess = os.path.join(pathToFlash, "object", ".success")
    if os.path.isfile(pathToDotSuccess):
      os.remove(pathToDotSuccess)

    # determine gmake invocation and record it in "gmake_call" file and in log
    script = "%s EXE=%s" % (pathToGmake, os.path.join(pathToBuildDir, exeName))
    open(os.path.join(pathToBuildDir, "gmake_call"),"w").write(script)
    log.stp(script)

    # we'll try to compile multiple times if the compilation fails
    # because of a problem with the license manager
    numTries = 0

    while numTries < 3:

      # cd to FLASH source object directory for compilation
      os.chdir(os.path.join(pathToFlash, "object"))

      # get stdout/stderr and duration of compilation and write to file
      out, err, duration, exitStatus = getProcessResults(script)
      open(os.path.join(pathToBuildDir, "gmake_output"),"w").write(out)
      if len(err) > 0:
        open(os.path.join(pathToBuildDir, "gmake_error"),"w").write(err)

      # cd back to flashTest
      os.chdir(pathToFlashTest)

      # return the success or failure of the compilation

      if os.path.isfile(pathToDotSuccess):
        log.stp("compilation was successful")
        # record compilation time in "compilation_time" file and in log
        duration = secondsToHuman.convert(duration)
        open(os.path.join(pathToBuildDir, "compilation_time"),"w").write(duration)
        log.info("duration of compilation: %s" % duration)
        self.masterDict["pathToFlashExe"] = os.path.join(pathToBuildDir, exeName)  # for exeScript
        os.remove(pathToDotSuccess)
        return True
      elif out.find("www.macrovision.com") > 0:
        log.stp("compilation failed due to licensing problem. Trying again...")
        numTries += 1
      else:
        break

    log.stp("compilation was not successful")
    return False

  def getDeletePatterns(self):
    return [self.masterDict.get("exeName", "flash-exe")]


class FlashExecuter(ExecuterTemplate):
  def execute(self, timeout=None):
    """
    run the FLASH executable piping output and other data into 'runDir'

    pathToRunDir: abs path to output dir for this unique executable/parfile combination
        numProcs: number of processors used for this run
         parfile: name of the parfile to be used in this run
    """
    log             = self.masterDict["log"]              # guaranteed to exist by flashTest.py
    pathToFlash     = self.masterDict["pathToFlash"]      # guaranteed to exist by flashTest.py
    pathToRunDir    = self.masterDict["pathToRunDir"]     # guaranteed to exist by flashTest.py
    pathToFlashTest = self.masterDict["pathToFlashTest"]  # guaranteed to exist by flashTest.py

    # read the execution script from "exeScript"
    exeScriptFile = os.path.join(pathToFlashTest, "exeScript")
    if not os.path.isfile(exeScriptFile):
      log.err("File \"exeScript\" not found. Unable to run executable.\n" +
              "Skipping all runs.")
      return False

    lines = open(exeScriptFile).read().split("\n")
    lines = [line.strip() for line in lines
             if len(line.strip()) > 0 and not line.strip().startswith("#")]
    script = "\n".join(lines)
    self.masterDict["script"] = script
    print("Debug " + script)
    script = self.masterDict["script"]  # do it this way so that any angle-bracket variables
    print("Debug (dict): " + script)                                    # in "exeScript" will be filled in by self.masterDict
    # determine 'pathToRunSummary'
    pathToRunSummary = os.path.join(pathToRunDir, "run_summary")

    # cd to output directory to run executable
    os.chdir(pathToRunDir)

    # obtain and record number of processors
    if not self.masterDict.has_key("numProcs"):
      self.masterDict["numProcs"] = 1
    open(pathToRunSummary,"a").write("numProcs: %s\n" % self.masterDict["numProcs"])

    # record mpirun invocation in "flash_call" file and in log
    open(os.path.join(pathToRunDir, "flash_call"), "w").write(script)
    log.stp(script)

    # get stdout/stderr and duration of execution and write to file
    print("Debug execution call: " + script)
    print("Debug execution call: " + os.getcwd())
    out, err, duration, exitStatus = getProcessResults(script, timeout)
    print("Debug (done execution): " + err + " " + str(exitStatus) )

    open(os.path.join(pathToRunDir, "flash_output"),"a").write(out)
    if len(err) > 0:
      open(os.path.join(pathToRunDir, "flash_error"),"a").write(err)

    # record execution time in the run summary and logfile in human-readable form
    duration = secondsToHuman.convert(duration)
    open(pathToRunSummary,"a").write("wallClockTime: %s\n" % duration)
    log.info("duration of execution: %s" % duration)

    # search the parfile output directory for checkpoint files
    checkFiles = []
    items = os.listdir(pathToRunDir)
    for item in items:
      if re.match(".*?_chk_\d+$", item):
        checkFiles.append(item)

    # record number and names of checkpoint files in the run summary
    open(pathToRunSummary,"a").write("numCheckfiles: %s\n" % len(checkFiles))
    for checkFile in checkFiles:
      open(pathToRunSummary,"a").write("checkFile: %s\n" % checkFile)

    # An exit status of 0 means a normal termination without errors.
    if exitStatus == 0:
      log.stp("Process exit-status reports execution successful")
      runSucceeded = True
    else:
      log.stp("Process exit-status reports execution failed" , exitStatus)
      runSucceeded = False

    # cd back to flashTest
    os.chdir(pathToFlashTest)

    return runSucceeded

  def getDeletePatterns(self):
    return [".*_chk_\d+$", ".*_plt_cnt_\d+$"]


class ComparisonExecuter(FlashExecuter):

  def adjustFilesToDelete(self, filesToDelete):
    """
    Determine the highest-numbered checkpoint file and create an
    entry "chkMax" in masterDict whose value is the name of this
    file. We'll use this value later to do our sfocu comparison.

    Then remove this file's name from 'filesToDelete', which will
    later be used to determine which files will be deleted before
    creation of the slim copy of the invocation's output.
    """
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py
    chkFiles = []

    # Search 'runDir' for checkpoint files. This method will also
    # be called for GridDumpComparison problems that do not generate
    # checkpoint files, but nothing will happen in that case.
    items = os.listdir(pathToRunDir)
    for item in items:
      if re.match(".*?_chk_\d+$", item):
        chkFiles.append(item)

    # sorting and reversing will put the highest-numbered
    # checkpoint file at index 0
    chkFiles.sort()
    chkFiles.reverse()

    if len(chkFiles) > 0:
      chkMax = chkFiles[0]
      self.masterDict["chkMax"] = chkMax
      for fileToDelete in filesToDelete[:]:
        if fileToDelete == chkMax:
          filesToDelete.remove(fileToDelete)


class ComparisonTester(TesterTemplate):

  def compare(self, pathToFileA, pathToFileB, cmd):
    log                = self.masterDict["log"]                # guaranteed to exist by flashTest.py
    arch               = self.masterDict["arch"]               # guaranteed to exist by flashTest.py
    outfile            = self.masterDict["outfile"]            # guaranteed to exist by flashTest.py
    pathToRunDir       = self.masterDict["pathToRunDir"]       # guaranteed to exist by flashTest.py
    pathToLocalArchive = self.masterDict["pathToLocalArchive"] # guaranteed to exist by flashTest.py

    pathToFileA = os.path.normpath(pathToFileA)
    pathToFileB = os.path.normpath(pathToFileB)

    if not os.path.isabs(pathToFileA):
      pathToFileA = os.path.join(pathToRunDir, pathToFileA)
    if not os.path.isabs(pathToFileB):
      pathToFileA = os.path.join(pathToRunDir, pathToFileB)

    if pathToFileA.startswith(pathToLocalArchive):
      try:
        arch.confirmInLocalArchive(pathToFileA)
      except Exception, e:
        log.err("%s\n" % e +
                "Aborting this test.")
        outfile.write(str(e))
        return False
    elif not os.path.isfile(pathToFileA):
      log.stp("\"%s\" does not exist." % pathToFileA)
      outfile("\"%s\" does not exist.\n" % pathToFileA)
      return False

    if pathToFileB.startswith(pathToLocalArchive):
      try:
        arch.confirmInLocalArchive(pathToFileB)
      except Exception, e:
        log.err("%s\n" % e +
                "Aborting this test.")
        outfile.write(str(e))
        return False
    elif not os.path.isfile(pathToFileB):
      log.stp("\"%s\" does not exist." % pathToFileB)
      outfile.write("\"%s\" does not exist.\n" % pathToFileB)
      return False

    log.stp("FileA: \"%s\"\n" % pathToFileA +
            "FileB: \"%s\""   % pathToFileB)
    outfile.write("FileA: \"%s\"\n" % pathToFileA +
                  "FileB: \"%s\"\n\n" % pathToFileB)

    outfile.write("script: %s\n" % cmd)
    return getProcessResults(cmd)


  def compareToYesterday(self, pathToFile, pathToCompareExecutable):
    yesterDate = time.strftime("%Y-%m-%d", time.localtime(time.time()-24*60*60))

    pat1 = re.compile("\/\d\d\d\d-\d\d-\d\d.*?\/")
    pathToYesterFile = pat1.sub("/%s/" % yesterDate, pathToFile)

    cmd = "%s %s %s" % (pathToCompareExecutable, pathToFile, pathToYesterFile)
    return self.compare(pathToFile, pathToYesterFile, cmd)


class SfocuTester(ComparisonTester):

  def test(self):
    log          = self.masterDict["log"]           # guaranteed to exist by flashTest.py
    pathToFlash  = self.masterDict["pathToFlash"]   # guaranteed to exist by flashTest.py
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py
    outfile      = self.masterDict["outfile"]       # guaranteed to exist by flashTest.py

    if not self.masterDict.has_key("chkMax"):
      log.stp("No checkpoint files were produced, so no comparisons can be made.")
      outfile.write("No checkpoint files were produced, so no comparisons can be made.\n")
      return False

    # else
    pathToChkMax = os.path.join(pathToRunDir, self.masterDict["chkMax"])
    pathToSfocu = self.masterDict.get("pathToSfocu", os.path.join(pathToFlash, "tools", "sfocu", "sfocu"))
    sfocuScript = self.masterDict.get("sfocuScript", pathToSfocu)

    # before comparing to the benchmark, compare to yesterday's result
    # this portion assumes that copies of the highest-numbered checkfile
    # are being retained locally in FlashTest's "output" directory
    log.stp("Part 1: Compare this invocation's result to yesterday's")
    outfile.write("Part 1: Compare this invocation's result to yesterday's\n")

    retval = self.compareToYesterday(pathToChkMax, sfocuScript)

    if retval:
      # unpack the tuple
      out, err, duration, exitStatus = retval

      # An exit status of 0 means a normal termination without errors.
      if exitStatus == 0:
        log.stp("Process exit-status reports sfocu ran successfully")
        outfile.write("<b>sfocu output:</b>\n"
                      + out.strip() + "\n\n")

        # Even if sfocu ran fine, the test might still have failed
        # if the two checkpoint files were not equivalent      
        if out.strip().endswith("SUCCESS"):
          log.stp("comparison of benchmark files yielded: SUCCESS")
        else:
          log.stp("comparison of benchmark files yielded: FAILURE")
          # The results of this test differed from the results of the
          # same test done during the previous invocation. We set the
          # key "changedFromPrevious" in masterDict (the value doesn't
          # matter) which is recognized by flashTest.py as a signal to
          # add a "!" to the ends of the "errors" files at the run,
          # build, and invocation levels.
          self.masterDict["changedFromPrevious"] = True
      else:
        log.stp("Process exit-status reports sfocu encountered an error")

        # record whatever we got anyway
        outfile.write("Process exit-status reports sfocu encountered an error\n" +
                      "<b>sfocu output:</b>\n" +
                      out.strip() + "\n\n")

    log.stp("Part 2: Compare this invocation's result to approved benchmark.")
    outfile.write("Part 2: Compare this invocation's result to approved benchmark.\n")

    if not self.masterDict.has_key("shortPathToBenchmark"):
      log.err("A key \"shortPathToBenchmark\", whose value is a relative path from\n" +
              "the local archive to a benchmark file against which the results of\n" +
              "this run can be compared, should be provided in your \"test.info\" file.")
      return False

    # else
    shortPathToBenchmark = self.masterDict["shortPathToBenchmark"]
    pathToLocalArchive = self.masterDict["pathToLocalArchive"]  # guaranteed to exist by flashTest.py
    pathToBenchmark = os.path.join(pathToLocalArchive, shortPathToBenchmark)

    cmdAndTols = [sfocuScript]
    if self.masterDict.has_key("errTol"):
      cmdAndTols.append("-e %s" % self.masterDict["errTol"])
    if self.masterDict.has_key("partErrTol"):
      cmdAndTols.append("-p %s" % self.masterDict["partErrTol"])

    cmd = "%s %s %s" % (" ".join(cmdAndTols), pathToChkMax, pathToBenchmark)
    retval = self.compare(pathToChkMax, pathToBenchmark, cmd)

    if not retval:
      return False

    # else unpack the tuple
    out, err, duration, exitStatus = retval

    # An exit status of 0 means a normal termination without errors.
    if exitStatus == 0:
      log.stp("Process exit-status reports sfocu ran successfully.")
      outfile.write("<b>sfocu output:</b>\n"
                    + out.strip() + "\n\n")

      # Even if sfocu ran fine, the test might still have failed
      # if the two checkpoint files were not equivalent      
      if out.strip().endswith("SUCCESS"):
        log.stp("comparison of benchmark files yielded: SUCCESS")
        return True
      else:
        log.stp("comparison of benchmark files yielded: FAILURE")
        return False
    else:
      log.stp("Process exit-status reports sfocu encountered an error")

      # record whatever we got anyway
      outfile.write("Process exit-status reports sfocu encountered an error\n" +
                    "<b>sfocu output:</b>\n" +
                    out.strip() + "\n\n")
      # sfocu had an error, so we return false:
      return False

    return True


class GridDumpTester(ComparisonTester):
  def findDumpFiles(self):
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py

    dumpFiles = []
    items = os.listdir(pathToRunDir)
    for item in items:
      if re.match("^FL\d+$", item):
        dumpFiles.append(item)

    return dumpFiles

  def test(self):
    log          = self.masterDict["log"]           # guaranteed to exist by flashTest.py
    pathToFlash  = self.masterDict["pathToFlash"]   # guaranteed to exist by flashTest.py
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py
    outfile      = self.masterDict["outfile"]       # guaranteed to exist by flashTest.py
  
    pathToGridDumpCompare = self.masterDict.get("pathToGridDumpCompare",
                                                os.path.join(pathToFlash, "tools", "GridDumpCompare.py"))
    if not os.path.isfile(pathToGridDumpCompare):
      log.err("\"%s\" does not exist or is not a file.\n" % pathToGridDumpCompare +
              "Result of test: FAILURE")
      outfile.write("\"%s\" does not exist or is not a file.\n" % pathToGridDumpCompare +
                    "Result of test: FAILURE\n")
      return False

    # else
    dumpFiles = self.findDumpFiles()

    if len(dumpFiles) == 0:
      log.err("No GridDump files were found, so no comparison can be made." +
              "Result of test: FAILURE")
      outfile.write("No GridDump files were found, so no comparison can be made.\n" +
                    "Result of test: FAILURE\n")
      return False

    # else
    log.stp("Part 1: Compare this invocation's results to yesterday's")
    outfile.write("Part 1: Compare this invocation's results to yesterday's\n")

    for dumpFile in dumpFiles:
      pathToDumpFile = os.path.join(pathToRunDir, dumpFile)

      retval = self.compareToYesterday(pathToDumpFile, pathToGridDumpCompare)

      if retval:
        # unpack the tuple
        out, err, duration, exitStatus = retval

        # An exit status of 0 means a normal termination without errors.
        if exitStatus == 0:
          log.stp("Process exit-status reports GridDumpCompare.py ran successfully.")
          outfile.write("<b>GridDumpCompare.py output:</b>\n"
                        + out.strip() + "\n\n")

          # Even if GridDumpCompare ran fine, the test might still
          # have failed if the two dump files were not equivalent      
          if out.strip() == "The two files are identical":
            log.stp("comparison of dump-files yielded: SUCCESS")
          else:
            log.stp("comparison of dump-files yielded: FAILURE")
            # The results of this test differed from the results of the
            # same test done during the previous invocation. We set the
            # key "changedFromPrevious" in masterDict (the value doesn't
            # matter) which is recognized by flashTest.py as a signal to
            # add a "!" to the ends of the "errors" files at the run,
            # build, and invocation levels.
            self.masterDict["changedFromPrevious"] = True
        else:
          log.stp("Process exit-status reports GridDumpCompare.py encountered an error")

          # record whatever we got anyway
          outfile.write("Process exit-status reports GridDumpCompare.py encountered an error\n" +
                        "<b>GridDumpCompare.py output:</b>\n" +
                        out.strip() + "\n\n")

    log.stp("Part 2: Compare this invocation's result to approved benchmark.")
    outfile.write("Part 2: Compare this invocation's result to approved benchmark.\n")

    if not self.masterDict.has_key("shortPathToBenchmarkDir"):
      log.err("A key \"shortPathToBenchmarkDir\", whose value is a relative path from the\n" +
              "local archive to the directory containing the files against which the results\n" +
              "of this run can be compared, should be provided in your \"test.info\" file.")
      return False

    # else
    # For GridDump comparisons we bring over a whole directory from the archive
    # which contains all dumps made for a single run (each dump encapsulates the
    # values of a single variable at different points on the grid).
    # This is different from sfocu comparisons, where we only bring over a single
    # file, the highest-numbered checkpoint file.
    shortPathToBenchmarkDir = self.masterDict["shortPathToBenchmarkDir"]

    arch = self.masterDict["arch"]  # guaranteed to exist by flashTest.py
    try:
      arch.confirmInLocalArchive(shortPathToBenchmarkDir)
    except Exception, e:
      log.err("%s\n" % e +
              "Aborting this test.")
      outfile.write(str(e))
      return False

    # else all files have been successfully brought over from
    # the remote archive into the local archive
    pathToLocalArchive = self.masterDict["pathToLocalArchive"]  # guaranteed to exist by flashTest.py

    allPassed = True

    for dumpFile in dumpFiles:
      pathToDumpFile = os.path.join(pathToRunDir, dumpFile)
      pathToBenchmark = os.path.join(pathToLocalArchive, shortPathToBenchmarkDir, dumpFile)

      cmd = "%s %s %s" % (pathToGridDumpCompare, pathToDumpFile, pathToBenchmark)
      retval = self.compare(pathToDumpFile, pathToBenchmark, cmd)

      if not retval:
        allPassed = False
        continue

      # else unpack the tuple
      out, err, duration, exitStatus = retval

      # An exit status of 0 means a normal termination without errors.
      if exitStatus == 0:
        log.stp("Process exit-status reports GridDumpCompare.py ran successfully")
        outfile.write("<b>GridDumpCompare.py output:</b>\n"
                      + out.strip() + "\n\n")

        # Even if GridDumpCompare ran fine, the test might still
        # have failed if the two dump files were not equivalent      
        if out.strip() == "The two files are identical":
          log.stp("comparison of dump-files yielded: SUCCESS")
        else:
          log.stp("comparison of dump-files yielded: FAILURE")
          allPassed = False
      else:
        log.stp("Process exit-status reports GridDumpCompare.py encountered an error")

        # record whatever we got anyway
        outfile.write("Process exit-status reports GridDumpCompare.py encountered an error\n" +
                      "<b>GridDumpCompare.py output:</b>\n" +
                      out.strip() + "\n\n")

        allPassed = False
        continue

    return allPassed

    
class UnitTester(TesterTemplate):
  """
  Implements a test method for all Flash unit-tests that follow the accepted
  unit-test standard. This standard prescribes that a unit-test will produce
  files named:

    unitTest_0, unitTest_1, ..., unitTest_n

  where 'n' is the number of processors on which the test ran. If the unit-
  test was completely successful, each of these files will contain the text:

    "all results conformed with expected values."

  Otherwise they will contain information describing why the test failed.

  This test method reads files whose names match those described above and
  determines success or failure based on the presence or absence therein of
  the aforementioned success string.
  """
  
  def test(self):
    log          = self.masterDict["log"]           # guaranteed to exist by flashTest.py
    pathToFlash  = self.masterDict["pathToFlash"]   # guaranteed to exist by flashTest.py
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py
    outfile      = self.masterDict["outfile"]       # guaranteed to exist by flashTest.py

    print("Debug (testing)")

    UGPat = re.compile("^unitTest_\d+$")

    files = os.listdir(pathToRunDir)
    log.stp("Searching in " + pathToRunDir + " for test results")
    files = [f for f in files if UGPat.search(f)]  # only want files
                                                   # matching 'UGPat'

    if len(files) > 0:
      success = True
      successStr = "all results conformed with expected values"
      # put in alphabetical order
      files.sort()
      for f in files:
        text =  "<i>reading file %s:</i>" % f
        text += "<div style='margin-left:10px;'>"
        fileText = open(os.path.join(pathToRunDir, f), "r").read()
        if fileText.count(successStr) == 0:
          success = False
        text += fileText
        text += "</div>"
        outfile.write(text)
    else:
      success = False

    if success:
      log.stp("result of test: SUCCESS")
    else:
      log.stp("result of test: FAILURE")

    return success


class DefaultSetupper(FlashSetupper):
  def setup(self):
    """
    The Default test by definition sets up the problem called "Default"
    This test doesn't use a "test.info" file, so we override the setup
    method long enough to set some key values in 'masterDict', then
    revert back to the setup method of UniversalTemplate.
    """
    self.masterDict["setupName"] = "Default"
    self.masterDict["setupOptions"] = "-site=%s -auto" % self.masterDict["flashSite"]

    return FlashSetupper.setup(self)


class RestartExecuter(ComparisonExecuter):
  """
  This class subclasses ComparisonExecuter instead of FlashExecuter
  so that the former's "adjustFilesToDelete()" method, which sets a
  value for "checkMax" will be called.
  """
  def execute(self):
    """
    The Restart test first runs a simulation in the normal way, generating
    a few checkpoint files. It then takes a checkpoint file from the middle
    of the run (as specified in the "test.info" data) and runs the problem
    again, this time restarting from the checkpoint. If the end-checkpoint
    file from the restart-run matches the end-checkpoint file from the first
    run, the test is considered a success
    """
    log          = self.masterDict["log"]           # guaranteed to exist by flashTest.py
    pathToRunDir = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py

    pathToPart1Parfile  = self.masterDict["part1Parfile"]   # supposed to exist in "test.info"
    part1NumProcs       = self.masterDict["part1NumProcs"]  # supposed to exist in "test.info"
    benchmark1          = self.masterDict["benchmark1"]     # supposed to exist in "test.info"
    benchmark2          = self.masterDict["benchmark2"]     # supposed to exist in "test.info"

    # First run the simulation through to generate
    # benchmarks 1 and 2 in the normal way
    pathToFlashTest = self.masterDict["pathToFlashTest"]  # guaranteed to exist by flashTest.py

    # read the execution script from "exeScript"
    exeScriptFile = os.path.join(pathToFlashTest, "exeScript")
    if not os.path.isfile(exeScriptFile):
      log.err("File \"exeScript\" not found. Unable to run executable.\n" +
              "Skipping all runs.")
      return False

    # else

    # hackily substitute into masterDict's "parfile" keyword the
    # name of the parfile we need to run this whole simulation
    # *without* a restart so it will in turn be substituted into
    # masterDict["script"] below.
    part1Parfile                = os.path.basename(pathToPart1Parfile)
    part2Parfile                = self.masterDict["parfile"]
    part2NumProcs               = self.masterDict["numProcs"]
    self.masterDict["parfile"]  = part1Parfile
    self.masterDict["numProcs"] = part1NumProcs

    lines = open(exeScriptFile).read().split("\n")
    lines = [line.strip() for line in lines
             if len(line.strip()) > 0 and not line.strip().startswith("#")]
    script = "\n".join(lines)
    self.masterDict["script"] = script
    script = self.masterDict["script"]  # do it this way so that any angle-bracket variables
                                        # in "exeScript" will be filled in by self.masterDict

    log.stp("Generating seed-benchmark \"%s\"\n" % benchmark1 +
            "and comparison-benchmark \"%s\"\n" % benchmark2 +
            "with parfile \"%s\" and numProcs=%s" % (part1Parfile, part1NumProcs))

    # write part1 parfile into 'runDir'
    parfileText = open(pathToPart1Parfile).read()
    open(os.path.join(pathToRunDir, part1Parfile), "w").write(parfileText)

    # cd to output directory to run executable
    os.chdir(pathToRunDir)

    # get stdout/stderr and duration of execution
    out, err, duration, exitStatus = getProcessResults(script)

    flashOutput = "Results of generation of seed and comparison checkpoint files:\n"
    flashOutput += (out + "\n")
    flashOutput += (("*" * 80) + "\n")
    open(os.path.join(pathToRunDir, "flash_output"),"w").write(flashOutput)

    if len(err) > 0:
      flashError = "Error in generation of seed and comparison checkpoint files:\n"
      flashError += (err + "\n")
      flashError += (("*" * 80) + "\n")
      open(os.path.join(pathToRunDir, "flash_error"),"w").write(flashError)

    # An exit status of 0 means a normal termination without errors.
    if exitStatus == 0:
      log.stp("Process exit-status reports execution successful")
    else:
      log.stp("Process exit-status reports execution failed.")
      return False

    # search the parfile output directory for the
    # seed-checkpoint and comparison-checkpoint files
    items = os.listdir(pathToRunDir)
    for item in items:
      if item == benchmark1:
        # this will be the seed-checkpoint file
        break  # skip "else" clause below
    else:
      log.stp("Expected seed-checkpoint file \"%s\" was not generated.\n" % benchmark1 +
              "Skipping all runs.")
      return False

    # search the parfile output directory for the comparison checkpoint file
    for item in items:
      if item == benchmark2:
        # This will be the comparison-checkpoint file.
        # Rename it so it won't get overwritten in part2.
        os.rename(item, item + "_orig")
        break  # skip "else" clause below
    else:
      log.stp("Expected comparison checkpoint file \"%s\" was not generated.\n" % benchmark2 +
              "Skipping all runs.")
      return False

    # cd back to flashTest
    os.chdir(pathToFlashTest)

    # We've now guaranteed that the "seed" checkpoint file is in
    # place in 'runDir', so reset the parfile and numProcs values
    # and call the parent class's executer
    self.masterDict["parfile"]  = part2Parfile
    self.masterDict["numProcs"] = part2NumProcs
    return ComparisonExecuter.execute(self)


class RestartTester(ComparisonTester):
  def test(self):
    log                = self.masterDict["log"]           # guaranteed to exist by flashTest.py
    pathToFlash        = self.masterDict["pathToFlash"]   # guaranteed to exist by flashTest.py
    pathToRunDir       = self.masterDict["pathToRunDir"]  # guaranteed to exist by flashTest.py
    outfile            = self.masterDict["outfile"]       # guaranteed to exist by flashTest.py

    benchmark1 = self.masterDict["benchmark1"]  # supposed to exist in "test.info"
    benchmark2 = self.masterDict["benchmark2"]  # supposed to exist in "test.info"

    pathToSfocu = self.masterDict.get("pathToSfocu", os.path.join(pathToFlash, "tools", "sfocu", "sfocu"))
    sfocuScript = self.masterDict.get("sfocuScript", pathToSfocu)

    chkMax = self.masterDict["chkMax"]  # should always have a value because even if execution produced
                                        # no checkpoint files, the seed-checkpoint copied into 'runDir'
                                        # should have been tagged as "chkMax" in ComparisonExecuter's
                                        # "adjustFilesToDelete" method.

    if chkMax == benchmark1:
      log.stp("No additional checkpoint files were produced after the restart.\n" +
              "No comparison can be made.")
      return False

    # else
    pathToChkMax = os.path.join(pathToRunDir, chkMax)
    pathToBenchmark2 = os.path.join(pathToRunDir, (benchmark2 + "_orig"))

    cmdAndTols = [sfocuScript]
    if self.masterDict.has_key("errTol"):
      cmdAndTols.append("-e %s" % self.masterDict["errTol"])
    if self.masterDict.has_key("partErrTol"):
      cmdAndTols.append("-p %s" % self.masterDict["partErrTol"])

    cmd = "%s %s %s" % (" ".join(cmdAndTols), pathToChkMax, pathToBenchmark2)
    retval = self.compare(pathToChkMax, pathToBenchmark2, cmd)

    if not retval:
      log.stp("Error processing command \"%s\"\n" % cmd)
      return False

    # else unpack the tuple
    out, err, duration, exitStatus = retval

    # An exit status of 0 means a normal termination without errors.
    if exitStatus == 0:
      log.stp("Process exit-status reports sfocu ran successfully.")
      outfile.write("<b>sfocu output:</b>\n"
                    + out.strip() + "\n\n")

      # Even if sfocu ran fine, the test might still have failed
      # if the two checkpoint files were not equivalent      
      if out.strip().endswith("SUCCESS"):
        log.stp("comparison of benchmark files yielded: SUCCESS")
        return True
      else:
        log.stp("comparison of benchmark files yielded: FAILURE")
        return False
    else:
      log.stp("Process exit-status reports sfocu encountered an error")

      # record whatever we got anyway
      outfile.write("Process exit-status reports sfocu encountered an error\n" +
                    "<b>sfocu output:</b>\n" +
                    out.strip() + "\n\n")
      # sfocu had an error, so we return false:
      return False

    return True
