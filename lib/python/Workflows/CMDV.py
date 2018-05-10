from Report.TestRunnerLogging import getLogger
from Workflow import Workflow as Parent
import Config

from pprint import pprint
import json
import yaml
#import logging
import os
import glob
import re
import shutil
import subprocess
import sys

# Setup logging
logger = None
logger = getLogger(__name__)


class Workflow(Parent):
  
  def __init__(self , file = None , config = None):
    
    # file = test config/workflow file
    # config = Config object
    
    super(Workflow, self).__init__()
    self.cmdvVersion = None
    self.custom      = None
    
    # dictionary created from json or yaml file
    cfg = None

    if file :
      if os.path.isfile(file) :
        cfg = self.load(file)
      else:
        logger.error("Not a valid file: " + file)
        sys.exit(1)
    
   
      
    pprint(self.__dict__)
    sys.exit(1)
    

  def load(self, config_file , format=None ) :  
    
    cfg = self._load_from_file(config_file)
    pprint(cfg)
    cfg = self._resolve_references(cfg)
    cfg = self._init_from_cfg(cfg)
    
    return cfg
    
  
  def _resolve_references(self, cfg ) :
    return cfg
    
  def _init_from_cfg(self, cfg ) :
    
    
    # cmdvVersion: v1.0
    # class: TestConfig | Workflow
    # label: Test-Config
    # doc:
    # inputs:
    #   repo:
    #     location: none
    #   directories :
    #     deploy : null
    #     build  : null
    #     run    : null
    #     postprocessing : null
    #     data   : null
    # outputs:
    # steps:
    # requirements:
      
    # dict for custom keys not defined in object    
    custom_cfg = {}    
        
    for k in vars(self) :   
      if k in cfg :
        logger.info("Setting " + k  )  
        setattr(self, k , cfg.pop(k) )
      else:
        logger.warning("Missing key " + k + " in config file")

    self.custom = cfg
    
    # set [label , doc, inputs , outputs , steps , hints , requirements]
   
    self._set_steps(self.steps)
 #    self._set_
    
  
    pprint(self.__dict__)
    sys.exit(1)
    
    return cfg
   
        
  def _load_from_file(self, config_file , format=None ) :

    logger.info("Loading Test Workflow")
    logger.debug("Loading config " + config_file)
    cfg = None
    # load config file
    
    if config_file.endswith(".yaml") :
      format = "yaml"
    elif config_file.endswith(".json") :
      format = "json"  
    
    
    
    if (config_file and os.path.exists(config_file)):
      with open(config_file, 'r') as f:
      
        try:
          if format == "yaml" :
            cfg = yaml.load(f)
          elif format == "json" :
            cfg = json.load(f)
        except:
          logger.error("Can't load config  " + config_file )
          raise
          sys.exit(1)    
    else:
      logger.error("Not a valid path to config: " + config_file if config_file else "unknown")
      sys.exit(1)
      
    cfg['self'] = { 
      "name" : os.path.basename(config_file) ,
      "path" : os.path.dirname(os.path.abspath(config_file))
      }
      
    if not 'class' in cfg and not cfg['class'] == 'CMDVGlobalConfig' :
      logger.error("Missing class key or wrong class in config")
      sys.exit(1)
    
    if not 'cmdvVersion' in cfg and not cfg['cmdvVersion'] == 'v1.0' :
      logger.error("Missing cmdvVersion key or wrong version in config. Expecting v1.0")
      sys.exit(1)     
    
    return cfg  

  
  def _set_steps(self , steps_dict ):
    
    logger.info("Setting steps")
    # empty list of steps 
    steps = []
    
    if steps_dict :  
      for s in [ "deploy" , "build" , "run" , "postprocessing" , "archive"] :
        if not s in steps_dict :
          logger.warning("Missing " + s + " step")
        else:
          logger.info("Creating step " + s )  
          if s == "deploy" :
            deploy = self.init_step()
            steps.append(deploy)
            pass
          if s == "run" :
            pass
          if s == "postprocessing" :
            pass
          if s == "archive" :
            pass      
    
    self.steps = steps
    
  


  
 

  #
  # def setup(self, config):
  #   # setup environment
  #   if isinstance(config,dict):
  #     if "hints" in config:
  #       hints = config['hints']
  #       # Setting up directories
  #       if "directories" in hints:
  #         logger.info("Creating global dirs")
  #         for d in hints['directories'] :
  #           logger.debug("Checking " + d)
  #           # Create dir if not exists
  #           if hints['directories'][d] and not os.path.exists(hints['directories'][d]):
  #               logger.debug("Creating " + hints['directories'][d])
  #               os.makedirs(hints['directories'][d])
  #       else:
  #         hints['directories'] = None
  #     else:
  #       config['hints'] = None
  #
  #
