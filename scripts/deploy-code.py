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


import xml.etree.ElementTree as xmlet



def deploy(repo , branch=None , base_dir=None , command="git clone" ):
  """docstring for fname"""
  logger.info("Deploying source code from: " + repo )
  
  # repository = git.Repo(path=repo)
  # repository = repository.clone(path=repo)

  
    
  if repo.find('https') > -1 :
    logger.info("Cloning from URL: " + repo )
    pass
  elif repo.find('git@') > -1 :  
    logger.info("Cloning using ssh: " + repo )
    process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
    output = process.communicate()[0]
  else:
    
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
  
  command = config['build']['run'] 
  path    = "./Build/"
  if config['build']['relative_path_to_run_command'] :
    path = path + config['build']['relative_path_to_run_command']
  
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
  pass    

def run(self):
  """docstring for fname"""
  
  command = config['execution']['run'] 
  path    = "./Build/"
  if config['build']['relative_path_to_run_command'] :
    path = path + config['build']['relative_path_to_run_command']
  
  current_dir = os.getcwd()
  
  logger.debug("current path " + current_dir)
  logger.debug("changing to " + path )
  
  os.chdir(path)
  
  
  
  logger.info("Executing:\t" + command)
  process = subprocess.Popen([command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
  output , errs = process.communicate()
  if output :
    logger.info("Output:" + output.decode())
  if errs :
    logger.error( output.decode() )
    logger.error( errs.decode() )
  pass
  
  pass  

def compare(self):
  """docstring for fname"""
  pass  


def load_config(config_file):
  config = None
  
  if (os.path.exists(config_file)):
    
    with open(config_file, 'r') as f:
         config = json.load(f)
    
  else:
    logger.error("Not a valid path to config: " + config)    
  
  return config

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
  
  if (step == 'all' or step == 'deploy') :
    deploy(branch=args.branch , repo=args.clone , base_dir=current_dir)
  if (step == 'all' or step == 'build') :
    build(config)   
  if (step == 'all' or step == 'run') :
      run(config)   

      


  os.chdir(current_dir)    
  pass  




###############################
# Setup
###############################

# Logging

# create logger with 'spam_application'
logger = logging.getLogger('DeployCode')
logger.setLevel(logging.DEBUG)
# create file handler which logs even debug messages
fh = logging.FileHandler('error.log')
fh.setLevel(logging.DEBUG)
# create console handler with a higher log level
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
ch.setFormatter(formatter)
# add the handlers to the logger
logger.addHandler(fh)
logger.addHandler(ch)

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
parser.add_argument("-s", "--step" , 
                    type=str, 
                    choices=['all', 'deploy', 'build','run','post'] , 
                    help="config file (json)",
                    
                    default="all")
parser.add_argument("-d", "--dir" , 
                    type=str, 
                    help="working directory",
                    default="./tmp")     
parser.add_argument("--clean" , 
                    help="start with fresh working directory",
                    action="store_true")                                           
args = parser.parse_args()

if __name__ == "__main__":

  config = None
  if args.config :
    logger.info("Reading config:\t" + args.config)
    config = load_config(args.config)
    print(config)

  main(config)







