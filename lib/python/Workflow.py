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
            self.name     = None
            self.command  = None
            self.inputs   = None
            self.outputs  = None
            self.baseCommand = None
            self.arguments = None
            self.stderr = None
            self.stdout = None


            if cfg :
                  
                  if "inputs" in cfg and not isinstance(cfg['inputs'] , dict) :
                        # convert into dict
                        logger.error("Inputs not a dict - need to convert")
                        self._convert_tool_inputs(cfg['inputs'])
                  self.baseCommand    = cfg['baseCommand']
                  self.inputs         = cfg['inputs']      if 'inputs' in cfg else None
                  self.outputs        = cfg['outputs']     if 'outputs' in cfg else None
                  self.arguments      = cfg['arguments']   if 'arguments' in cfg else None
                  self.stderr      = cfg['stderr']   if 'stderr' in cfg else None
                  self.stdout      = cfg['stdout']   if 'stdout' in cfg else None



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
            # pprint(inputs)
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
            
            # pprint(self.__dict__)

            options_positional  = []
            options_named       = []

            if self.inputs and not  isinstance(self.inputs , dict) :
                  logger.error("Tool input not a dict")
                  sys.exit(1)
            

            if not self.inputs is None :
                  for k in self.inputs :
                        # pprint(k)
                        if isinstance(self.inputs[k] , dict) :
                              i = self.inputs[k]
                              if 'inputBinding' in i :
                                    prefix = i['inputBinding']['prefix'] if 'prefix' in i['inputBinding'] else ''
                                    value  = i['value'] if 'value' in i and i['value'] else ''
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
            else :
                  logger.warning("No inputs for step")                    

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
            
            if  inputs is None or not isinstance(inputs,dict):
                  logger.error("Missing input or not a dictionary")
                  # pprint(inputs)
                  sys.exit(1)
            
            if self._map_inputs(inputs) :
                  self._assign_values(inputs)
            else :
                  logger.error("Can not map tool input to task input")
                  sys.exit(1)
                  
            self._build_command()

            current_dir = os.getcwd()
            logger.info("Executing " + self.command)
            logger.debug("Current dir: " + current_dir)
            process = subprocess.Popen([self.command],  stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True)
            output , errs = process.communicate()
            if output :
                  try:
                        out_msg = output.decode()
                  except UnicodeDecodeError, e:
                        logger.warning("Unable to decode output " + str(e))
                        out_msg = output
                                       
                  logger.info("Tool Output: " + out_msg)
                  if self.stdout :
                        file = open(self.stdout , "a")
                        file.write(out_msg)
                        file.close()
            if errs :
                  try:
                        err_msg = errs.decode()
                  except UnicodeDecodeError, e:
                        logger.warning("Unable to decode error message: " + str(e))
                        err_msg = errs
                  logger.error( err_msg )
                  if self.stderr :
                        file = open(self.stderr , "a")
                        file.write(err_msg)
                        file.close()





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
      
      def init(self, cfg) :
            # run:
            #       baseCommand: []
            # in: {}
            # out: 
            #       - report:
            #         type: File
            #         glob: build.log
            #       - dir: 
            #         type: Directory
            #         glob: none
            #       - binary: 
            #         type: File[]
            #         glob: "*local-test"  # name of executable


            tool_cfg = {
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

            if cfg :
                  tool = self.run 
                  if not "run" in cfg :
                        logger.error("Can't initialize step, missing run command")
                        sys.exit(1)
                  if 'baseCommand' in cfg['run'] :
                        if isinstance(cfg['run']['baseCommand'] , list ) :
                              tool.baseCommand = cfg['run']['baseCommand']
                              tool.type = 'Script'
                        elif  isinstance(cfg['run']['baseCommand'] , str ) :
                              tool.baseCommand = [ cfg['run']['baseCommand'] ]
                              tool.type = 'Script'
                        else :
                              logger.error("Unsupported type for run: " + type(cfg['run']['baseCommand']) ) 
                              sys.exit(1)
                  elif  not cfg['run'] or cfg['run'] == 'none' :
                        logger.warning('Run command empty - setting to default')
                        tool.baseCommand = [ 'echo' , 'No run command' ]                      
                  else :
                        logger.error("Can't initialize step, missing baseCommand. Tools or Workflows not implemented")
                        sys.exit(1)

                  if "arguments" in cfg['run'] :
                        tool.arguments = cfg['arguments']
                  if 'in' in cfg :
                        self.inputs = cfg['in']
                  if 'out' in cfg :
                        self.outputs = cfg['out']
                  if 'name' in cfg :
                        self.name = cfg['name']                  
                              
                        
            else :
                  logger.error("Can't initialize step, missing step config")
                  sys.exit(1)




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

            #  pprint(self.directories.__dict__)    

      def _check_dirs(self) :
            
            logger.debug("Checking for step dirs")
            directories_exists = True if ( 
                  os.path.isdir(self.directories.working) and  
                  os.path.isdir(self.directories.input) and  
                  os.path.isdir(self.directories.output) ) else False
            
            return directories_exists

      def _make_dirs(self) :
            
            # create step directories
            for path in [ self.directories.working , self.directories.input , self.directories.output] :
                  logger.debug("Creating directory: " + path)  
                  try:
                        os.makedirs(path)
                  except os.error, e:
                        if e.errno != errno.EEXIST:
                              raise

      def execute(self) :
            
            logger.debug("Executing step " + self.name )
            inputs = {} # Get step inputs
            if not self._check_dirs() :
                  logger.warning("Step directories missing - creating directories")
                  self._make_dirs
            pprint(self.directories.__dict__)
            logger.debug("Step dirs: " + self.directories.working)
            if self.run :
                  if isinstance(self.run, basestring) :
                        logger.warning("Not implemenetd - run command is string")
                  elif isinstance(self.run, Workflow) :
                        logger.warning("Not implemenetd - run command is workflow object")
                  elif isinstance(self.run, Tool) :
                        logger.warning("Run command is tool object - executing")   
                        # Init tool - check for input directory,output directory etc.
                        self.run.execute(inputs)
            else :
                  logger.error("Can not execute step - missing run command or tool")                     
                              
      

    

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
            logger.debug("Executing workflow with " + str(len(self.steps)) )
            for step in self.steps :
                  logger.debug("Executing step " + str(step.name) )
                  step.execute()
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
#     setup : null
#     build  : null
#     run    : null
#     postprocessing : null
#     data   : null
#
#
# outputs:
#   reports:
#     type: File[]
#     outputSource: [setup/report , build/report , run/report , postprocessing/report]
#
#
# steps:
#   setup:
#     label: Default setup step
#     run:
#       baseCommand: []
#     in:
#       repo:
#         type: Directory
#         location: URI #
#       destination:
#         valueFrom: ${inputs.directories.setup}
#         default: ${config.base}
#     out:
#       - report:
#           type: File
#           glob: setup.log
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
