#!/usr/bin/env python

import argparse
import git
import json
import logging
import os
import glob
import re
import shutil
import subprocess
import sys
import importlib
from pprint import pprint
import Archive
import Report
from Deploy import Deploy
# from Config import TestConfig as Config
#from Config import TestWorkflow as Workflow 
from Config import Config as Config
from Report.TestRunnerLogging import TestRunnerLogging as ll 
from Report.TestRunnerLogging import getLogger
from Report import Tests
from Workflows.CMDV import Workflow 
#from Workflows.Test import Test as Workflow
# from Report import LocalLogging as ll

import xml.etree.ElementTree as xmlet


import yaml






def execute_command(cmd , config=None , step_report=None) :
  """cmd is an array"""
  
  if not step_report :
    logger.error("No report object")
    sys.exit(1)
  
  if not cmd :
    logger.error("No command to execute")
  else:  
    command = " ".join(cmd)
    logger.info("Executing: " + command )
    
    process = subprocess.Popen( cmd ,  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
    output , errs = process.communicate()
    
    if output :
      logger.info("Output:" + output.decode())
      step_report.message = output.decode()
    if errs :
      logger.error( output.decode() )
      logger.error( errs.decode() )
      step_report.error = errs.decode()
    
    step_report.status = "success"
      
    if process.returncode :
      step_report.status = "failed"
    if step_report.error :
      step_report.status = "failed"
    if step_report.message and re.search("test_failed" , step.message) :
      step_report.status = "failed" 
    
      
def execute_step(step , environment=None) :
  """ Execute script defined in step

        "baseCommand" : ["ls"] ,
        "arguments" : ["-l" , ">" , "listing.txt"] ,
        "inputs" : null ,
        "outputs" : {
          "summary" : {
            "type" : "File" ,
            "outputBinding" : {
              "glob" : "listing.txt"
            }
          }
        }  
  """
  
  current_env = os.environ
  if environment and isinstance(environment , dict) :
    for k in environment:
      if k == "PATH" :
        paths = ":".join(environment['PATH'])
        current_env['PATH'] = current_env['PATH'] + ":" + paths 
      else :
        current_env['k'] = environment[k]    
    
  receipt = { 
    "stderr" : None ,
    "stdout" : None ,
    "exit_status" : None ,
  }
  
  # build cli
  cmd = []
  if 'baseCommand' in step :    
    for part in step['baseCommand'] :
      cmd.append(part)
  else:
    logger.error("No command to run")
    sys.exit(1)
    
  if 'arguments' in step and isinstance(step['arguments'] , list ):
    for part in step['arguments'] :
      cmd.append(part)
  
  logger.debug("Executing: " + " ".join(cmd) )     
  pprint( subprocess.call( cmd , stdin=None, stdout=None, stderr=None, shell=True) )   

  process = subprocess.Popen(['echo ERROR' ], stdout=subprocess.PIPE , shell=True)
  out, err = process.communicate()
  print(out)
  process = subprocess.Popen( cmd ,  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
  output , errs = process.communicate()
  
  pprint(output)
  if output :
    logger.info("Output:" + output.decode())
    receipt['stdout'] = output.decode()
  if errs :
    logger.error( errs.decode() )
    receipt['stdout'] = errs.decode()
  receipt['exit_status'] = process.returncode 
  
  
  # gather output
  if step['outputs'] and isinstance(step['outputs'], dict) :
      for k in step['outputs'] :
        output = step['outputs'][k]
        if output['type']== "File" :
          if 'outputBinding' in output:
            if "glob" in output['outputBinding']:
              files = glob.glob( output['outputBinding']['glob'] )
              receipt[k] = []
              for f in files :
                receipt[k].append(os.path.abspath(f))
            else:
              logger.debug("No glob in outputBinding for " + k)
          else:  
            logger.debug("No outputBinding for " + k)
            pass
        else:
          logger.debug("Unknown type " + k['type'] + " - not implemented")  
  pprint(receipt)        
  return receipt       
      
def create_test_step_summary(receipt , step_name) :
  
  # call test_checker module here
  # for now go through output and count "ERROR" strings
  
  # "stderr" : None ,
  # "stdout" : None ,
  # "exit_status" : None ,
  
  if not step_name :
    step_name = 'unkown'
    logger.error('No step name provided - setting to "unknown"')
  
  summary = Tests.Step(step_name)
  summary.tests['total']  = 1 # assume at least one test
  summary.tests['failed'] = 0
  
  # setting default to success - change if errors
  if receipt['exit_status'] :
    summary.status = 'failed' 
    summary.error  =  True
    summary.message = 'Script execution failed'
  else:
    summary.status = 'success' 
    summary.error  =  False
    summary.message = None
    
    # summary.name = name
    # summary.status = None
    # summary.tests = {
    #       "total" : None ,
    #       "success" : None ,
    #       "failed" : None ,
    #     }
    # summary.message = None
    # summary.error   = None
    # summary.location = { 'URI' : None }
    # summary.reports = []
    # summary.dir = None
  
  # Count errors in stdout, stderr and test output files
  errors_in_reports = 0

  for k in receipt :
     
    results = None
    logger.debug('Checking ' + k)
    
    # skip if exit_status
    if (k == "exit_status"):
      continue
         
    if receipt[k] :
      logger.debug('Value for ' + k + ": " + receipt[k]) 
      pprint(receipt[k])  
      if isinstance(receipt[k] , list) :
        for entry in receipt[k] :
          # test if file and grep errors in file
          if os.path.isfile(entry) :
            results = parse_test_result_file(entry)
          else:
            results = parse_test_result_text(entry)  
      else:
        if receipt[k] and os.path.isfile(receipt[k]) :
          # test if file and grep errors in file
          logger.debug('Checking file from ' + k) 
          results = parse_test_result_file(file_name)
        else:
          # grep errors in text
          logger.debug('Checking text from ' + k)   
          results = parse_test_result_text(receipt[k])
          
            
      if results and len(results) :
        logger.debug("Found " + str(len(results)) + " errors.")
        summary.tests['failed'] = summary.tests['failed'] + len(results)
        summary.status = 'failed'
        summary.error = True 
        summary.message = 'Found errors in report' 
      else:
        logger.debug("Found no errors.")
        
    else:
      logger.debug('No value for ' + k)   


  return summary
  
def parse_test_result_text(text) :    
  """find error string in text """
  logger.debug('Checking text for  ERROR ') 
  if not text:
    logger.error("No text provided")
    sys.exit(1)
  results = re.findall("ERROR" , str(text) )
  pprint(results)
  return results 
  
def parse_test_result_file(file_name) :
  """find error string in file"""
  textfile = open(file_name, 'r')
  filetext = textfile.read()
  textfile.close()
  matches = parse_test_result_text(filetext) 
  return matches        
      
def deploy(current_config , repo=None , branch=None , base_dir=None , repo_dir=None , command="git clone" ):
  """docstring for fname"""
  
  error = 0
  error_message = ''
  
  logger.info("Deploying source code from: " +  ( repo if repo else "unknown" ) )
  

  logger.info("Setup local config")
  config.setup(current_config)
  # repository = git.Repo(path=repo)
  # repository = repository.clone(path=repo)
  
  if current_config and isinstance(current_config, dict) and "hints" in current_config :
    logger.info("Checking hints")
    hints = current_config['hints']
    if "git" in hints :
      logger.debug("Checking git section")
      if not repo and "clone" in hints['git'] :
        repo = hints['git']['clone']
      else:
        logger.debug("No git repo to clone") 
        repo = None   
      if not branch and "branch" in hints['git'] :
        branch = hints['git']['branch']
    
  if repo and repo.find('https') > -1 :
    logger.info("Cloning from URL: " + repo )
    process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
    output = process.communicate()[0]
  elif repo and repo.find('git@') > -1 :  
    logger.info("Cloning using ssh: " + repo )
    
    # Check if ssh config in path?
    
    process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
    output = process.communicate()[0]
  
  # Checking steps in config - if deployment step build command line argument and execute  
  elif repo_dir and os.path.isdir(repo_dir) and config.deploy_dir() :
    logger.info("Copying repo from " + repo_dir + " to " + config.deploy_dir() ) 
    logger.debug( "Current: " + os.getcwd() + "\tRepo dir: " + repo_dir)
    #logger.debug( current_config )
    command = "cp -R " + repo_dir + " " + config.deploy_dir()


    logger.info("Running " + command )
    process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
    output , errs = process.communicate()
    if output :
      logger.info("Output:" + output.decode())
    if errs :
      logger.error( output.decode() )
      logger.error( errs.decode() )
      error_message = errs.decode()
      exit(1)
   
  elif "steps" in current_config:
    logger.debug("Checking steps in config")
    
    
    if "deploy" in current_config["steps"] :

      logger.info("Executing deployment config")
      deploy = current_config["steps"] ["deploy"]
      logger.debug( os.getcwd() )
      if  "run" in deploy and deploy["run"] is not None :
        # Build command
        command = deploy["run"]
        logger.debug("Dir:" + os.getcwd())
        logger.debug(deploy)
        logger.info("Running " + deploy["run"] )
        process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
        output , errs = process.communicate()
        if output :
          logger.info("Output:" + output.decode())
        if errs :
          logger.error( output.decode() )
          logger.error( errs.decode() )
          error_message = errs.decode()
        
        error = process.returncode
        logger.debug("Return code = " + str(process.returncode) )
                
  else:
    logger.debug("No config found")
    path = None
    
    if ( os.path.isabs(repo) ):
      path = repo
    else:
      # fix path - path was relative to invokation dir
      path = base_dir + "/" + repo  
    
    if not path:
      logger.error("Something seriously wrong!")
      sys.exit('path variable not defined - impossible')
      
    if (os.path.exists(path)):  
      logger.info("Cloning from path: " + path )
    
      if os.path.isdir(path):
        repository = git.Repo(path=path)
        logger.debug( os.getcwd())
        cloned = repository.clone(path= os.getcwd() + "/Build" )
        
        if branch :
          logger.info('Switching to branch: ' + branch)
          cloned.git.checkout(branch)  

        
        print(cloned)
      else:
        logger.info("Executing script: " + path )  
    
    else:
      logger.error('Invalid or unsupported URI:\t' + repo)
  
  return (error, error_message)        
  
    
  
def build(config):
  """docstring for fname"""
  
  build_dir = None
  deploy_dir = None
  
  print("Local")
  pprint(config)
  print("Global")
  pprint(defaults.__dict__)
  pprint("Directories")
  pprint(defaults.directories.__dict__)
  # sys.exit(1)
  
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "build" in config["hints"]["directories"] :
    build_dir = config["hints"]["directories"]["build"]  
  elif defaults and \
    defaults.directories and \
    defaults.directories.build :
    build_dir = defaults.directories.build  
  else:  
    logger.error("No build directory")
    logger.debug(pprint(config))
    logger.debug(pprint(defaults))
    sys.exit("No build directory")
    
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "deploy" in config["hints"]["directories"] :
    deploy_dir = config["hints"]["directories"]["deploy"]  
  elif defaults and \
    defaults.directories and \
    defaults.directories.deploy :
    deploy_dir = defaults.directories.deploy
  else:
    logger.error("No deploy directory")
    logger.debug(pprint(config))
    logger.debug(pprint(defaults))
    sys.exit("No deploy directory") 
      
  
  
  
  logger.debug( " ".join(["Dirs in build:", str(build_dir) , str(deploy_dir)]))
  if not deploy_dir or not build_dir :
    logger.error("No direcories for deploy and build")
    pprint(config)
    pprint(defaults)
    sys.exit("No direcories for deploy and build")
  else:
    pprint(config)
    pprint(defaults)  
  
  # Check for deploy and build dir - build dir should not be same as deploy dir
  logger.debug(deploy_dir)
  logger.debug(build_dir)
  
  if deploy_dir != build_dir :
    logger.info("Creating build dir and copying code")
    logger.info("Copying code from " + deploy_dir + " to " + build_dir)
    
    process = subprocess.Popen(["cp" , "-R" , deploy_dir , build_dir],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=False)
    output , errs = process.communicate()
    if output :
      logger.info("Output:" + output.decode())
    if errs :
      logger.error( output.decode() )
      logger.error( errs.decode() )
    
    # conflict if directory exists
    # shutil.copytree(deploy_dir, build_dir)
    
  else: 
    logger.info("Same deploy and build directory: " + str(build_dir) ) 
  
  build = None
  
  if config and "steps" in config and "build" in config["steps"] :
    build = config["steps"]["build"]
  
  command = None
  if "run" in build :
    command = build['run']
  elif "baseCommand" in build :
    command = build['baseCommand']   
  else:
    logger.error("No execution in build step")
      
  path    = build_dir
  # set path to build command
  if 'relative_path_to_run_command' in build and build['relative_path_to_run_command'] :
    path = path + build["relative_path_to_run_command"]
  elif 'path' in build and build['path']:
    path = path + build["path"]    
  else:
    logger.error( "Missing path to build command" )  
  
  if not path or not os.path.isdir(path):
    logger.error("Missing build dir")
    # update report and exit test - missing
    return (1 , "Missing build dir")
    
  logger.debug( "Switching into " + path )  
  current_dir = os.getcwd()
  os.chdir(path)

  # only execute if command
  if command :
    logger.info("Executing:\t" + str(command))
    if type(command) is str : 
      process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
    elif type(command) is list :
      process = subprocess.Popen(command,  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
    else:
      logger.error("Can not run command neither string nor list of strings")
      sys.exit("Wrong type")    
    output , errs = process.communicate()
    if output :
      logger.info("Output:" + output.decode())
    if errs :
      logger.error( output.decode() )
      logger.error( errs.decode() )

  # Go back to top level dir
  os.chdir(current_dir)
  
def run(config , step_report=None):
  """docstring for fname"""
  
  
  build_dir   = None
  deploy_dir  = None
  run_dir     = None
  run         = None
  
  if config and "steps" in config and "run" in config["steps"] :
    run = config["steps"]["run"]
  else:
    logger.error("No 'run' step") 
  
  if defaults and \
    defaults.directories.build :
    build_dir = defaults.directories.build
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "build" in config["hints"]["directories"] :
    build_dir = config["hints"]["directories"]["build"]  
    
  if defaults and \
    defaults.directories.run :
    run_dir = defaults.directories.run 
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "run" in config["hints"]["directories"] :
    run_dir = config["hints"]["directories"]["run"]
  
  if not run_dir:
    run_dir = build_dir
  
  # Change into run directory  
  
  if not run_dir or not os.path.isdir(run_dir):
    logger.error("Missing run dir")
    # update report and exit test - missing
    return (1 , "Missing run dir")
  
  current_dir = os.getcwd()
  logger.debug("current path " + current_dir)
  logger.debug("changing to " + run_dir )
  os.chdir(run_dir)
  
  
  path    = None
  
  if run['relative_path_to_run_command'] :
    bin_path = build_dir + run['relative_path_to_run_command']
  
  if 'baseCommand' in run :    
    logger.debug("Found baseCommand in run - executing step")
    receipt = execute_step(run , environment={ "PATH" : [bin_path] }) 
    summary = create_test_step_summary(receipt , "run" )
  elif "run" in run:
    # support for older style - deprecated 
    logger.debug("No baseCommand in run - executing run command")
    command = bin_path + "/" + run['run']

    execute_command([command] , config=config , step_report=step_report)

    logger.info("Executing:\t" + command)
    process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=False)
    output , errs = process.communicate()
    if output :
      logger.info("Output:" + output.decode())
      step_report.message = output.decode()
    else:
      step_report.message = "YEAH"
    if errs :
      logger.error( output.decode() )
      logger.error( errs.decode() )
  else:
    logger.warning("No run nor baseCommand in step")  
   
  # Change back into current dir
  os.chdir(current_dir)
  pprint(step_report)
  return step_report
  
  
 
  
def compare(config):
  """docstring for fname"""
  pass  

def postproc(config):
  pass

def create_report(config):
  pass

def main(config=None):
  """docstring for fname"""
  
  # Setup
  logger.info('Starting session')
  
  # Test for working directory
  tmp_dir = args.dir
  logger.debug('Testing for working directory')
  
  if args.clean :
    logger.info('Deleting ' + tmp_dir)
    shutil.rmtree(tmp_dir)
  
  if not os.path.exists(tmp_dir):
    # Creating working dir
    logger.debug('Missing working directory, creating ' + tmp_dir)
    os.makedirs(tmp_dir)
  else:
    logger.debug('Working directory ' + tmp_dir + ' already exists.')
  
  current_dir = os.getcwd()
  os.chdir(tmp_dir)
  
  step = args.step
  logger.debug('Executing step:\t' + step) 
  
  # Count number of tests - use as test name if non provided
  counter = 1

  logger.info("Found " + str(len(config.tests)) + " tests")
  for test in config.tests :
    
    # Get test run name
    if 'name' in test:
      test_name = test['name']
    else:
      test_name = str(counter)
    
    # set to true if a step in the test failed and ignore next depending steps
    test_run_error = 0
    
    # Setup one run per config file  
    report_for_current_test_run = report.init_tests_run(test_name)
      
    counter = counter + 1    
    logger.info('Executing Test:\t' + test_name + " (" + test['self'] + ")") 
    
    
    for step in ['deploy' , 'build' , 'run' , 'postproc'] :
      logger.info('Executing step:\t' + step) 
    
      if (args.step == 'all' or args.step == step ) :      
        if step in test['steps'] : 
          
          # init test report for step
          report_for_current_step = report_for_current_test_run.init_step(step)
          
          # Keep for generic calls
          # if step in test['steps'] :
#             logger.info('Step ' + step + " started")
#             globals()["deploy"](test , branch=args.branch , repo=args.clone , base_dir=current_dir)
#             logger.info('Step ' + step + " finished")

          if (step == 'deploy'): 
            # 1. copy code from project dir into working dir + /deploy
            # 2. clone from repo into working dir + /deploy
            # 3. execute run command in deploy step
            pprint(config.__dict__)
            pprint(test)
            pprint(current_dir)
            pprint(args.project)
            deployment = Deploy(config=test)
            pprint(deployment)
            sys.exit(1)
            (error , message) = deploy(test , branch=args.branch , repo=args.clone , base_dir=current_dir , repo_dir=args.project)
            if ((error != 0)) :
              logger.error('Error in deploy: ' + message)
              logger.error('Error: ' + str(error))
              
              # update test report - missing
              # exit loop - next steps can't succeed
              break
              sys.exit(1)
          if (step == 'build') :
            logger.info('Build step')
            build(test)
          if (step == 'run') :
            logger.info('Run step')
            run(test , step_report=report_for_current_step)
          if (step == 'postproc') :
            logger.info('Postprocessing step')
            postproc(test)



  
  
  if (args.archive or  ( "archive" in defaults and \
                         "execute" in defaults['archive'] and \
                         defaults['archive']['execute'])) :
    logger.info("Archiving session")
    
    module_name="Archive." + defaults['archive']['module']
  
    # Standard import
    import importlib
    logger.debug("Loading module " + module_name )
    MyClass = getattr(importlib.import_module(module_name), defaults['archive']['module'])
    # Instantiate the class (pass arguments to the constructor, if needed)
    archive = MyClass(logger_name="test-runner" , config = config)
    
    
    # archive.source = "/tmp/testing/run/"
    # archive.logfile = "coag_rate.out"

    archive.push(report = report) 
  else:
    logger.info("Not archiving session")  
    pprint(report.toDict())

  os.chdir(current_dir)    
  pass  




###############################
# Setup
###############################

# Logging

# logger = getLogger(__name__)
handler = logging.FileHandler('error.log')

logger = getLogger("cmdv-test-runner")
# logger.addHandler(handler) 
logger.info("Setup")


# Command line input

# New config

parser = argparse.ArgumentParser()

parser.add_argument("--cmdv" ,"--config", 
                    type=str , dest="config" ,
                    help="config file (json)")
parser.add_argument("--test", 
                    type=str , action='append' ,
                    help="test config(json)")
parser.add_argument("--format", 
                    type=str , 
                    help="yaml | json")                    


# OLD

parser.add_argument("-c", "--clone" , 
                    type=str , 
                    help="git clone path")
parser.add_argument("-v" , "--verbose", 
                    action="store_true", 
                    help="increase output verbosity")
parser.add_argument("-b" , "--branch", 
                    type=str , 
                    help="increase output verbosity")
# parser.add_argument("--config",
#                     type=str ,
#                     help="config file (json)")
parser.add_argument("-global-config", "--defaults" , 
                    type=str , 
                    help="global config file (json)")
parser.add_argument("--archive", 
                    type=bool ,
                    default=False, 
                    help="enable archiving")                                                        
parser.add_argument("-s", "--step" , 
                    type=str, 
                    choices=['all', 'deploy', 'build','run','post'] , 
                    help="config file (json)",
                    
                    default="all")
parser.add_argument("-d", "--dir" , 
                    type=str, 
                    help="base directory for session and test directories, default is current working directoy",
                    default= os.getcwd() )  
parser.add_argument("--deploy" , 
                    type=str, 
                    help="deploy directory , if -d is provided copies data from working dir into deploy dir. Overwrites deployment path in config", 
                    default=None)    
parser.add_argument("--project" , "--repo" ,
                    type=str, dest="repo" ,
                    help="project/repo/test directory, contains test code; used to discover tests. Default current directory", 
                    default= None )                                          
parser.add_argument("--clean" , 
                    help="start with fresh working directory",
                    action="store_true")  
parser.add_argument("--print-config" , 
                    help="print config and exit",
                    action="store_true")  
                                                                                 
args = parser.parse_args()

if __name__ == "__main__":


  report = Tests.Report()

  logger.info("Initializing config")
  
  pprint(args)
  # Get/set global config
  config=Config(file=args.config  , dir=args.repo , base_dir=args.dir)
  
  # config=Config( master_config=args.defaults , local_config=args.config , base_dir = args.dir , repo_dir = args.project )
  #defaults = config.defaults
  
  if args.print_config :
    pprint(config.__dict__)
    sys.exit()
  
  # Find tests
  pprint(config.tests['files'])
  test_files = config.find_tests( dir = config.repo.path , suffix = config.tests['suffix'])
  pprint(config.tests['files'])
  
  for f in test_files :
    logger.debug("Initializing test from " + f)

    global_directories = { 
                          "input"   : None ,
                          "output"  : None ,
                          "tmp"     : config.directories.tmp ,
                          "working" : None ,
                          "base"    : config.directories.session ,
                        } 

    workflow = Workflow(file=f , config=config , dirs=global_directories)
    pprint(workflow)
    print("/n/n")
    pprint(vars(workflow))

  
  if not hasattr(config,"defaults")  or not config.defaults :
    logger.error("No default settings, aborting")
    sys.exit()


  # logger.debug("END")
  # pprint(config.__dict__)
  # exit()
  #
  
  # module_name="Archive.CDash"
#
#   # Standard import
#   import importlib
#   # Load "module.submodule.MyClass"
#   MyClass = getattr(importlib.import_module(module_name), "CDash")
#   # Instantiate the class (pass arguments to the constructor, if needed)
#   archive = MyClass(logger_name="test-runner")
  
 
  logger.info("Starting main")
  main(config)







