from Report.TestRunnerLogging import getLogger
from Workflow import Workflow as Parent
from Workflow import Step as Step
from Workflow import Tool as Tool
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


  
class Deploy(Step):
  """docstring for ClassName"""

  def __init__(self, cfg):
    super(Deploy, self).__init__()

    logger.debug('Initializing deployment object')  

    self.name = "deploy"
    self._set_dirs( base = os.getcwd() )
 

    self.source = None
    self.branch = None
    self.destination = None
    self.baseCommand = None

    if cfg :
          if not 'run' in cfg :
                logger.debug("Missing deploy command")
          logger.warning("Not implemented - Step Config")   


    # Create symlink farm tool
    if not self.baseCommand :

      repo = "./"   
      self.run =  " ".join( [ 'find' ,  repo ,  '-type d' , '-exec' , 'mkdir' ,  '-p' , '--' , self.directories.working + '/{}' , '\;' ])
      self.run +=  " ".join( [ 'find' ,  repo ,  '-type f' , '-exec' , 'ln' ,  '-s' , '{}' , self.directories.working + '/{}' , '\;' ])
          

    pprint(self.__dict__)
  
    # test if source is git repo

    # test if source is path

    # if config and isinstance(config, dict) and "hints" in config :
    #   logger.info("Checking hints")
    #   hints = config['hints']
    # if "git" in hints :
    #   logger.debug("Checking git section")
    # if not repo and "clone" in hints['git'] :
    #   self.repo = hints['git']['clone']
    # else:
    #   logger.debug("No git repo to clone")
    #   self.repo = None
    # if "branch" in hints['git'] :
    #   self.branch = hints['git']['branch']

    # if self.repo() and self.repo.find('https') > -1 :
    #   logger.info("Cloning from URL: " + repo )
    #   process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
    #   output = process.communicate()[0]
    # elif self.repo() and self.repo.find('git@') > -1 :
    #   logger.info("Cloning using ssh: " + repo )

    #   # Check if ssh config in path?

    #   process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
    #   output = process.communicate()[0]

    # # Checking steps in config - if deployment step build command line argument and execute
    # if config['path_to_config'] and os.path.isdir(config['path_to_config']) :
    #   self.source = config['path_to_config']
    # if config['path'] :
    #   self.source = self.source + "/" + config['path']
    # if not os.path.isdir(self.source) :
    #   logger.error("Invalide path: " + self.source )
    #   self.source = None

  def _init_tool(self, cfg) :
        
        repo = "./"   
        logger.warning("Not implemented - Tool Config")  
        if cfg :
              if not 'run' in cfg :
                logger.debug("Missing deploy command")
        


        # Create symlink farm tool
        if True :
              # copy_dirs = [ "cd" , repo , ";" , 'find' ,  "." ,  '-type d' , '-exec' , 'mkdir' ,  '-p' , '--' , self.directories.working + '/{}' , '\;' ]
              # create_symlinks = [ 'find' ,  "." ,  '-type f' , '-exec' , 'ln' ,  '-s' , '-v' , repo + '/{}' , self.directories.working + '/{}' , '\;' ]
              # cmd = copy_dirs  + [";"] + create_symlinks
              cfg = {
                'baseCommand' : ['clone-dir.sh']  ,
                'arguments' : [] ,
                'inputs' : {
                  "source" : {
                    "type" : "Directory" ,
                    "inputBinding" : {
                      "position" : 1
                    },
                  },
                  "destination" : {
                    "type" : "Directory" ,
                    "inputBinding" : {
                      "position" : 2
                    }
                  }
                }
              }
              pprint(cfg)
          
        tool = Tool(cfg)
        self.run = tool
      
      
            

  def clone(self, source=None , destination=None):
        # check source and destination dir
        if not source or not os.path.exists(source):
              logger.error("Missing or invalid path " + str(source))
              sys.exit(1)
        if not destination or not os.path.exists(desination):
          logger.error("Missing or invalid path " + str(source))
          sys.exit(1)      
              
        # copy directory structure
        self._clone_directory_structure(source=source , destination=destination)
        # create links  

  def _clone_directory_structure(self, parameter_list):
        # find ${source} -type d -exec mkdir -p -- ${destination}{} \;
        pass      

  def _create_symlinks(self, source=None, destination=None):

    # find $SOURCE -type f -exec ln {} $DESTINATION/{} \;    
    pass  


  def execute(self , source=None , destination=None):
        
    logger.info("Executing deploy")

    if self.run :
          if isinstance(self.run, basestring) :
                logger.warning("Not implemenetd - run command is string")
          elif isinstance(self.run, Workflow) :
                logger.warning("Not implemenetd - run command is workflow object")
          elif isinstance(self.run, Tool) :
                logger.warning("Not implemenetd - run command is tool object")   
                # Init tool - check for input directory,output directory etc.
                self.run.execute({"source" : source , "destination" : destination})   
                  

    sys.exit(1)          




class Workflow(Parent):
  
  def __init__( 
                self , 
                file  = None , 
                dirs = { 
                          "input"   : None ,
                          "output"  : None ,
                          "tmp"     : None ,
                          "working" : None ,
                          "base"    : None ,
                        } ,
                name = None ,         
                config = None ,
              ):
    
    # file = test config/workflow file
    # config = Config object
    
    super(Workflow, self).__init__()

    self.cmdvVersion = None
    self.name        = None 
    self.custom      = None
    self.config      = config
    
    # From super:
    #  self.version          = None
    #   self.label            = None
    #   self.doc              = None
    #   self.inputs           = None # {}
    #   self.outputs          = None # {}
    #   self.steps            = None # [Step()]
    #   self.requirements     = None # [Requirement()]
    #   self.hints            = None # [Hint()]
    #   self.self             =  {
    #     "name" : None ,
    #     "file" : None ,
    #     "path" : None ,  
    #   }

    # Set
    #   self.directories = { 
    #     "input"   : None ,
    #     "output"  : None ,
    #     "tmp"     : None ,
    #     "working" : None ,
    #     "base"    : None ,
    #   }
    
    # Set dirs , set working direcory to session dir + test name
    self.directories = dirs



    # base_dirs = self.config.directories

    # self.directories['base'] = base_dirs.session 
    # self.directories['working'] = "/".join([base_dirs.session , self.self['name']])    

    # if base_dirs.tmp :
    #         self.directories['tmp'] = "/".join( [base_dirs.tmp , self.config.session.name , self.self['name']] )
    # elif 'TMPDIR' in os.environ :
    #         self.directories['tmp'] = os.environ['TMPDIR']
    # else:
    #       logger.info("Can't find any config for tmp - setting to current working dir")
    #       self.directories['tmp'] = "/".join( [os.getcwd() , "tmp" , self.config.session.name , self.self['name'] ])
                  
    # # check config for dirs
    # if self.inputs and 'directories' in self.inputs:
    #       logger.warning("Not implemented - directories from config are ignored"

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

     # From super:
    #  self.version          = None
    #   self.label            = None
    #   self.doc              = None
    #   self.inputs           = None # {}
    #   self.outputs          = None # {}
    #   self.steps            = None # [Step()]
    #   self.requirements     = None # [Requirement()]
    #   self.hints            = None # [Hint()]
    #   self.self             =  {
    #     "name" : None ,
    #     "file" : None ,
    #     "path" : None ,  
    #   }
    #   self.directories = { 
    #     "input"   : None ,
    #     "output"  : None ,
    #     "tmp"     : None ,
    #     "working" : None ,
    #     "base"    : None ,
    #   }

    # set self and directoris
    self.self = cfg['self']
    if "name" in cfg :
          self.self['file'] = self.self['path'] + "/" + self.self['name']
          self.self['name'] = cfg['name']

    if not self.name :
          self.name = self.self['name']

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
    
    self._set_directories() 
    if 'inputs' in cfg and 'directories' in cfg['inputs'] :
          logger.warning("Ignoring directories in inputs section")

    self._set_steps(self.steps)

    
  
    pprint(self.__dict__)
    print("DOME")
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

  # set workflow directories - steps will be executed in working dir or tmp
  def _set_directories(self):
        
        # Set
        #   self.directories = { 
        #     "input"   : None ,
        #     "output"  : None ,
        #     "tmp"     : None ,
        #     "working" : None ,
        #     "base"    : None ,
        #   }
        logger.info("Setting Workflow directories")

        if not self.directories['tmp'] :
              logger.info("Missing tmp dir for workflow")

              if 'TMPDIR' in os.environ :
                   self.directories['tmp'] = os.environ['TMPDIR']
              else:
                  logger.warning("Can't find any env for tmp - setting to current working dir")
                  self.directories['tmp'] = "/".join( [os.getcwd() , "tmp" ])

              logger.info("Set tmp dir to " + self.directories['tmp'])    


        if not self.directories['base'] :
              logger.info("Missing base dir for workflow - setting to tmp")
              self.directories['base'] = self.directories['tmp']
        
        # Set working direcory to session dir + test name    
        if not self.directories['working'] :
              logger.info("Missing working directory - setting to base + test name")
              self.directories['working'] = "/".join( 
                                                      [ 
                                                        self.directories['base'] , 
                                                        self.name
                                                      ]
                                                    )
                     
        # check config for dirs
        if self.inputs and 'directories' in self.inputs:
              logger.warning("Not implemented - directories from config are ignored")
    

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
            cfg =  steps_dict['deploy']  if "deploy" in steps_dict else None
            deploy = Deploy(cfg)
            logger.debug("Setting step dirs - calling method")
            deploy._set_dirs( base = os.path.join( self.directories['working'] , deploy.name ))
            deploy._init_tool(None)
            # EXECUTE from WORKFLOW
            deploy.execute(source="./" , destination=deploy.directories.working )
            logger.debug(deploy.directories.__dict__)
            steps.append(deploy)
            print("Stopped - deploy - @1752")
            sys.exit(1)
          if s == "run" :
            run = self.init_step()
            steps.append(run)
          if s == "postprocessing" :
            pp = self.init_step()
            steps.append(pp)
          if s == "archive" :
            archive = self.init_step()
            steps.append(archive)      
    
    self.steps = steps
    