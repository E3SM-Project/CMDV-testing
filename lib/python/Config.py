import os
import sys
import logging
import json
from pprint import pprint
from Report.TestRunnerLogging import getLogger

logger = None
logger = getLogger(__name__)


class TestConfig(object):
  """Config Class"""
  
  
  def __init__(self, master_config=None , local_config=None , working_dir = "." ):
    
    # super(TestConfig, self).__init__()
    
    if not os.path.exists( working_dir ) :
      logger.debug('Working dir does not exists, creating ' + working_dir )
      os.makedirs(working_dir)
    
    session_name = 'test-runner'
    
    "/".join( [working_dir , session_name , "deploy"])
    
    self.defaults = {
      "directories" : {
        "deploy" : "/".join( [working_dir , session_name , "deploy"]) , # working_dir + "/deploy/" ,
        "build"  : "/".join( [working_dir , session_name , "deploy"]) , # working_dir + "/deploy/" ,
        "run"    : "/".join( [working_dir , session_name , "run"]) , # working_dir + "/run/" ,
        "postproc" : "/".join( [working_dir , session_name , "postproc"]) , # working_dir + "/run/"  ,
        "data"   : "/".join( [working_dir , session_name , "data"]) , # working_dir + "/data/" ,
        "archive" : "/".join( [working_dir , session_name , "archive "]) , # working_dir + "/archive/",
        },
      "archive" : {
        "module" : "Archive" ,
        "archive_test_results" : False ,
        "destination" : None
      },  
    }
    
    self.global_config = self.load(master_config) if master_config else None
    self.local_config = self.load(local_config) if local_config else None
    self.working_dir = working_dir
    self.tests = []
    
    if self.global_config :
      self.tests.append(self.global_config)
    if self.local_config :   
      self.tests.append(self.local_config)
    
    if working_dir :
      self.find_global_config( working_dir=working_dir , git = True ) 
    if working_dir :
      self.find_config( working_dir=working_dir , git = False )

 
    if self.global_config :
      logger.debug("Found global config , setting new defaults")
      if 'hints' in self.global_config :
        if 'directories' in self.global_config['hints'] :
          for d in self.global_config['hints']['directories'] :
            logger.info('Mapping ' + d)
            if self.global_config['hints']['directories'][d] :
              self.defaults['directories'][d] = self.global_config['hints']['directories'][d]
            else :
              logger.debug('No value for ' + d + " keeping default"  )
        if "archive" in  self.global_config['hints'] :
          for k in self.global_config['hints']['archive'] :
            self.defaults['archive'][k] = self.global_config['hints']['archive'][k]
            
             
            
    logger.info("Creating default directories")
    for d in self.defaults['directories'] :
 
     if not os.path.exists(self.defaults['directories'][d]):
       os.makedirs(self.defaults['directories'][d])
       

       
    
      
 

  def load(self, config_file) :

    config = None
    # load config file
    if (config_file and os.path.exists(config_file)):
      with open(config_file, 'r') as f:
           config = json.load(f)
    else:
      logger.error("Not a valid path to config: " + config_file if config_file else "unknown")
      
    config['self'] = config_file      
    return config
    
  def setup(self, config):
    # setup environment 
    if isinstance(config,dict):
      if "hints" in config:
        hints = config['hints']
        # Setting up directories
        if "directories" in hints:
          logger.info("Creating global dirs")    
          for d in hints['directories'] :  
            logger.debug("Checking " + d)   
            # Create dir if not exists 
            if hints['directories'][d] and not os.path.exists(hints['directories'][d]):
                logger.debug("Creating " + hints['directories'][d])  
                os.makedirs(hints['directories'][d])
        else: 
          hints['directories'] = None
      else:
        config['hints'] = None            

  def find_config(self, working_dir=None , git = False , config_name = "tests_config.json"):
    
    current_dir = working_dir if working_dir else os.getdir()
    
    for root, dirs, files in os.walk(current_dir):
        for file in files:
            if file.endswith(config_name):
                 logger.debug(os.path.join(root, file))
                 self.tests.append(self.load( os.path.join(root, file) ))
    
    
  def find_global_config(self, working_dir=None , git = False , config_name = "global_test_config.json") :  
    
    current_dir = working_dir if working_dir else os.getdir()
    config_file = None
    parent_dir  = None
    
    if git :
       while ( not (config_file or  parent_dir) ):
         
         config_file = current_dir + "/" + config_name  if os.path.isfile(current_dir + "/" + config_name ) else None 
         
         if os.path.isdir( current_dir + "/.git") :
           parent_dir = current_dir
         
         if len(current_dir) <= 1 :
           parent_dir = current_dir
         
         (current_dir,tail)=os.path.split(current_dir)
         print("DIR=" + current_dir + " PARENT=" + str(parent_dir))
         print(len(current_dir))

    else:
      for root, dirs, files in os.walk(current_dir):
          for file in files:
              if file.endswith(config_name):
                   print(os.path.join(root, file))
                   config_file = os.path.join(root, file)
                   
                    
    if not config_file :
      logger.debug("No global config file found")
    else:
      logger.debug("Loading global config file " + config_file)
      self.tests.append(self.load( config_file )) 
      if not self.global_config:
        self.global_config = self.load(config_file)
      


      
   


if __name__ == "__main__":
    import sys
    check_config(int(sys.argv[1]))