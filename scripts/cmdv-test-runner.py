#!/usr/bin/env python

import argparse
import git
import json
import logging
import os
import re
import shutil
import subprocess
import sys
from pprint import pprint
import Archive
import Report
from Config import TestConfig as Config
from Report.LocalLogging import LocalLogging as ll 
from Report.LocalLogging import getLogger
from Report import Tests
# from Report import LocalLogging as ll

import xml.etree.ElementTree as xmlet


# def eval(x):
#   if not x:
#     return "undefined"
#   return x
# print("Hello: "+eval(x))
# x = "world"
# print("Hello: "+eval(x))



def deploy(current_config , repo=None , branch=None , base_dir=None , command="git clone" ):
  """docstring for fname"""
  
  
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
  elif "steps" in current_config:
    logger.debug("Checking steps in config")
    
    
    if "deploy" in current_config["steps"] :

      logger.info("Executing deployment config")
      deploy = current_config["steps"] ["deploy"]
      
      if  "run" in deploy and deploy["run"] is not None :
        # Build command
        command = deploy["run"]
        logger.info("Running " + deploy["run"] )
        process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
        output , errs = process.communicate()
        if output :
          logger.info("Output:" + output.decode())
        if errs :
          logger.error( output.decode() )
          logger.error( errs.decode() )
        
     
          
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
  pass  
  
def build(config):
  """docstring for fname"""
  
  build_dir = None
  deploy_dir = None
  
  if global_config and \
    "hints" in  global_config and \
    "directories" in global_config["hints"] and \
    "build" in global_config["hints"]["directories"] :
    build_dir = global_config["hints"]["directories"]["build"]
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "build" in config["hints"]["directories"] :
    build_dir = config["hints"]["directories"]["build"]  
    
  if global_config and \
    "hints" in  global_config and \
    "directories" in global_config["hints"] and \
    "deploy" in global_config["hints"]["directories"] :
    deploy_dir = global_config["hints"]["directories"]["deploy"]
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "deploy" in config["hints"]["directories"] :
    deploy_dir = config["hints"]["directories"]["deploy"]  
  
  if deploy_dir != build_dir :
    logger.info("Creating build dir and copying code")
  else: 
    logger.info("Same deploy and build directory: " + build_dir ) 
  
  build = None
  
  if config and "steps" in config and "build" in config["steps"] :
    build = config["steps"]["build"]
  
  command = build['run'] 
  path    = build_dir
  if 'relative_path_to_run_command' in build and build['relative_path_to_run_command'] :
    path = path + build["relative_path_to_run_command"]
  else:
    logger.error( "Missing path to build command" )  
  
  logger.debug( "Switching into " + path )  
  current_dir = os.getcwd()
  os.chdir(path)

  logger.info("Executing:\t" + command)
  process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
  output , errs = process.communicate()
  if output :
    logger.info("Output:" + output.decode())
  if errs :
    logger.error( output.decode() )
    logger.error( errs.decode() )

  # Go back to top level dir
  os.chdir(current_dir)
  

def run(config):
  """docstring for fname"""
  
  
  build_dir = None
  deploy_dir = None
  run = None
  
  if config and "steps" in config and "run" in config["steps"] :
    run = config["steps"]["run"]
  
  if global_config and \
    "hints" in  global_config and \
    "directories" in global_config["hints"] and \
    "build" in global_config["hints"]["directories"] :
    build_dir = global_config["hints"]["directories"]["build"]
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "build" in config["hints"]["directories"] :
    build_dir = config["hints"]["directories"]["build"]  
    
  if global_config and \
    "hints" in  global_config and \
    "directories" in global_config["hints"] and \
    "run" in global_config["hints"]["directories"] :
    run_dir = global_config["hints"]["directories"]["run"]
  if config and \
    "hints" in config and \
    "directories" in config["hints"] and \
    "run" in config["hints"]["directories"] :
    run_dir = config["hints"]["directories"]["run"]
  
  if not run_dir:
    run_dir = build_dir
  
  
  command = run['run'] 
  path    = None
  
  if run['relative_path_to_run_command'] :
    bin_path = build_dir + run['relative_path_to_run_command']
  
  current_dir = os.getcwd()
  
  logger.debug("current path " + current_dir)
  logger.debug("changing to " + run_dir )
  
  os.chdir(run_dir)
  
  command = bin_path + "/" + run['run'] 
  
  logger.info("Executing:\t" + command)
  process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=False)
  output , errs = process.communicate()
  if output :
    logger.info("Output:" + output.decode())
  if errs :
    logger.error( output.decode() )
    logger.error( errs.decode() )
  pass
  
  pass  

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
  logger.info('Starting process')
  
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
    logger.debug('Working directory already exists.')
  
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
    
    # Setup one run per config file  
    report_for_current_test_run = report.init_tests_run(test_name)
      
    counter = counter + 1    
    logger.info('Executing Test:\t' + test_name + " (" + test['self'] + ")") 
    
    
    for step in ['deploy' , 'build' , 'run' , 'postproc'] :
    
      logger.debug('Executing step:\t' + step) 
    
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
            deploy(test , branch=args.branch , repo=args.clone , base_dir=current_dir)
          if (step == 'build') :
            logger.info('Build step')
            build(test)
          if (step == 'run') :
            logger.info('Run step')
            run(test)
          if (step == 'postproc') :
            logger.info('Postprocessing step')
            postproc(test)



  logger.info("Checking archiving settings")
  if (args.archive or  "archive" in global_config) :
    
    
    module_name="Archive." + global_config['archive']['module']
  
    # Standard import
    import importlib
    logger.debug("Loading module " + module_name )
    MyClass = getattr(importlib.import_module(module_name), global_config['archive']['module'])
    # Instantiate the class (pass arguments to the constructor, if needed)
    archive = MyClass(logger_name="test-runner" , config = config)
    
    
    logger.info('Archiving test run')
    archive.source = "/tmp/testing/run/"
    archive.logfile = "coag_rate.out"
    logger.info("Pushing")  
    pprint(report.toDict())
    pprint(report.tests)
    archive.push(report = report) 
  else:
    pprint(global_config)
    logger.info("Not archiving session")  

  os.chdir(current_dir)    
  pass  




###############################
# Setup
###############################

# Logging

logger = getLogger(__name__)
logger.info("Setup")


# Command line input
parser = argparse.ArgumentParser()
parser.add_argument("-c", "--clone" , 
                    type=str , 
                    help="git clone path")
parser.add_argument("-v" , "--verbose", 
                    action="store_true", 
                    help="increase output verbosity")
parser.add_argument("-b" , "--branch", 
                    type=str , 
                    help="increase output verbosity")
parser.add_argument("--config", 
                    type=str , 
                    help="config file (json)")
parser.add_argument("--global-config", 
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
                    help="working directory",
                    default=None)     
parser.add_argument("--clean" , 
                    help="start with fresh working directory",
                    action="store_true")                                           
args = parser.parse_args()

if __name__ == "__main__":


  report = Tests.Report()

  config=Config( master_config=args.global_config , local_config=args.config , working_dir = args.dir )   
  global_config = config.defaults
  
  if not config.defaults :
    logger.error("No default settings, aborting")
    sys.exit()
  if not config.global_config :
    logger.error("Could not find global config")  

  
  module_name="Archive.CDash"
  
  # Standard import
  import importlib
  # Load "module.submodule.MyClass"
  MyClass = getattr(importlib.import_module(module_name), "CDash")
  # Instantiate the class (pass arguments to the constructor, if needed)
  archive = MyClass(logger_name="test-runner")
  
 

  main(config)







