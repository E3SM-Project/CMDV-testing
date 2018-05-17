import os
import sys
import logging
import json
import yaml
import subprocess
from pprint import pprint
from time import gmtime, strftime
from Report.TestRunnerLogging import getLogger

# Setup logging
logger = None
logger = getLogger(__name__)

class Directories(object):
      """Directories for Step"""
      
      def __init__(self, input=None , output=None , working=None):
          
          # Input directory for data 
          self.input    = input
          # Output directory for step results if specified
          self.output   = output
          # Working directory for step command
          self.working  = working

          for k in self.__dict__ :
                self._check_dir(getattr(self,k))



      def create(self, parameter_list):
          pass  

      def _check_dir(self, dir):
            if dir and os.path.exists(dir):
                  logger.debug("Directory exists " + dir)
            elif dir and not os.path.exists(dir):
                  logger.debug("Directory path provided but does not exists " + dir)
            else:
              logger.debug("Missing direcrory path")   

      

    


class Hint(object):
  
  def __init__(self):
    pass

class Requirement(object):
  
  def __init__(self):
    pass

class Tool(object):
  
  def __init__(self, cfg) :
    
    self.type     = None
    self.command  = None
    self.inputs   = None
    self.outputs  = None
    self.baseCommand = None
    self.arguments = None


    if cfg :
          
          if "inputs" in cfg and not isinstance(cfg['inputs'] , dict) :
                # convert into dict
                logger.error("Inputs not a dict - need to convert")
                self._convert_tool_inputs(cfg['inputs'])
          self.baseCommand    = cfg['baseCommand']
          self.inputs         = cfg['inputs']      if 'inputs' in cfg else None
          self.outputs        = cfg['outputs']     if 'outputs' in cfg else None
          self.arguments      = cfg['arguments']   if 'arguments' in cfg else None

  def _convert_tool_inputs(self, inputs) :
        
        # Convert into dict
        logger.error("Not implemented - _convert_tool_inputs")
        sys.exit(38)
    
  def _map_inputs(self, inputs) :
        # map step inputs to tool command line inputs/positions
        mapped=True
        if self.inputs :
              # Inputs can be dict or list
              if  isinstance(self.inputs , dict) :
                    logger.debug("Mapping input options to step input")
                    for k in self.inputs :
                          if k not in inputs :
                                mapped=False
                                logger.error("Missing " + k + " in step inputs")
                          
              else:
                    logger.error("Not implemented - inputs is not a dictionary")
                    logger.debug(self.inputs)
                    sys.exit(38)
        else:
          logger.warning("No inputs specified for tool")
        
        return mapped      

  def _assign_values(self, inputs) :
        
        if self.inputs :
              # Inputs can be dict or list
              if  isinstance(self.inputs , dict) :
              
                    for k in self.inputs :
                          # 1. type checking
                          # 2. assign value

                          # Covers one use case
                          self.inputs[k]['value'] = inputs[k]
        else :
              logger.warning("Can't assign values to inputs. No tool inputs specified")
        

  def _build_command(self) :
        
        pprint(self.__dict__)

        options_positional  = []
        options_named       = []

        if self.inputs and not  isinstance(self.inputs , dict) :
              logger.error("Tool input not a dict")
              sys.exit(1)

        for k in self.inputs :
              
              if isinstance(self.inputs[k] , dict) :
                    i = self.inputs[k]
                    if 'inputBinding' in i :
                          prefix = i['inputBinding'] if 'prefix' in i['inputBinding'] else ''
                          value  = i['value'] if 'value' in i else ''
                          option = " ".join([prefix , value])
                          
                          
                          if 'position' in i['inputBinding'] and i['inputBinding']['position'] :
                                options_positional.append( { "value" : option , 'position' : i['inputBinding']['position'] })
                          else : 
                                options_named.append( option )
                      
                    else :
                          logger.error("Missing inputBinding")
                          sys.exit(1)
              
              elif isinstance(self.inputs[k] , str) :
                    logger.error("Input for " + k + " is string not dict")
                    sys.exit(1)  
                    
              else : 
                logger.error("Not Implemented - Argumemt type not determined ")
                sys.exit(1)    

        for o in self.arguments :
              if isinstance(o,str) :
                    logger.debug("Found string")
              else : 
                logger.error("Not Implemented - Argumemt not string ")
                sys.exit(1)    

        cmd = [ " ".join(self.baseCommand )]
        cmd = cmd + options_named
        
        # missing check for duplicate positions
        for o in options_positional :
              cmd.insert( o['position'] , o['value'])

        # set command for run command    
        self.command = " ".join(cmd)
       
      
  def map(self) :
    pass  

  def execute(self , inputs):
        
        if not inputs or not isinstance(inputs,dict):
              logger.error("Missing input or not a dictionary")
              sys.exit(1)
        
        if self._map_inputs(inputs) :
              self._assign_values(inputs)
        else :
              logger.error("Can not map tool input to task input")
              sys.exit(1)
              
        self._build_command()

        current_dir = os.getcwd()
        process = subprocess.Popen([self.command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
        output , errs = process.communicate()
        if output :
          logger.info("Tool Output: " + output.decode())
          logger.error( errs.decode() )
        if errs :
          logger.error( output.decode() )
          logger.error( errs.decode() )





class Step(object):
  """Workflow step"""
  
  def __init__(self) :
        
        logger.debug("Init base class step")
        self.name     = None
        self.id       = None
        self.inputs   = None
        self.outputs  = None
        self.parents  = [None]
        self.children = [None]
        self.run      = Tool(None)
        self.status   = None
        self.error    = None
        self.directories = Directories()
      
  def map(self) :
    pass  

  def _set_dirs(self , base=None , working=None , input=None , output=None):
        # set step dirs
        logger.debug("Setting step directories")
        logger.debug(base)
        
        if not self.name :
              logger.error("Can't set step directories, missing step name")
              sys.exit(1)
        if base :
          self.directories.working = os.path.join( base , "working")  
          self.directories.input = os.path.join( base , "input")  
          self.directories.output = os.path.join( base , "output") 

        if working :
          self.directories.working = working

        if input :
              self.directories.input = input

        if output :
              self.directories.input = output     

        pprint(self.directories.__dict__)            
    

    

class Workflow(object):
  """Test Class"""
  
  def __init__(self) :
    
    self.version          = None
    self.label            = None
    self.doc              = None
    self.inputs           = None # {}
    self.outputs          = None # {}
    self.steps            = None # [Step()]
    self.requirements     = None # [Requirement()]
    self.hints            = None # [Hint()]
    self.self             =  {
      "name" : None ,
      "file" : None ,
      "path" : None ,  
    }
    self.directories = { 
      "input"   : None ,
      "output"  : None ,
      "tmp"     : None ,
      "working" : None ,
      "base"    : None ,
    }
    
    
    
    
  def init_step(self) :
    return Step()
      
  def load(self) :
    pass
  
  
  def execute(self) :
        logger.error("Not implemented: Workflow.execute" )
        sys.exit(1)
  
  

# cmdvVersion: v1.0
# class: TestConfig | Workflow
#
# label: Test-Config
# doc:  |
#     Template for test config
#
#
#
#
#
# inputs:
#   repo:
#     location: none
#   directories :
#     deploy : null
#     build  : null
#     run    : null
#     postprocessing : null
#     data   : null
#
#
# outputs:
#   reports:
#     type: File[]
#     outputSource: [deploy/report , build/report , run/report , postprocessing/report]
#
#
# steps:
#   deploy:
#     label: Default deploy step
#     run:
#       baseCommand: []
#     in:
#       repo:
#         type: Directory
#         location: URI #
#       destination:
#         valueFrom: ${inputs.directories.deploy}
#         default: ${config.base}
#     out:
#       - report:
#           type: File
#           glob: deploy.log
#       - dir:
#           type: Directory
#           glob: none
#
#   build:
#     run:
#       baseCommand: []
#     in: {}
#     out:
#       - report:
#         type: File
#         glob: build.log
#       - dir:
#         type: Directory
#         glob: none
#       - binary:
#         type: File[]
#         glob: "*local-test"  # name of executable
#
#   run:
#     run:
#       baseCommand: []
#     in: {}
#     out:
#       - report:
#         type: File
#         glob: "run.log"
#       - dir:
#         type: Directory?
#         glob: none
#
#   postprocessing:
#     run: # workflow or tool or baseCommand
#       baseCommand: []
#     in: {}
#     out: {}
#
#   archive:
#     run: none
#     in: {}
#     out: {}
#
#
#
#
# requirements:
#   - class: CMDV-Config
#     include:
#       name: config
#       glob: global_test_config.json
#       class: CMDVGlobalConfig
#
#   - class: SchemaDefRequirement
#     types:
#       - type: enum
#         name: repo_types
#         label: Repo types
#         symbols:
#           - git
#           - local
#       - type: record
#         label: Repository type
#         name: Repository
#         fields:
#           - name: location
#             type: URI
#             doc: |
#               This may be a relative reference, in which case it must be resolved using the base IRI
#               of the document.
#           - name: type
#             label: whole numbers
#             doc: Type of repository
#             type: repo_types
#