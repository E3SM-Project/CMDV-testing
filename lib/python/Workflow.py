import os
import sys
import logging
import json
import yaml
from pprint import pprint
from time import gmtime, strftime



class Hint(object):
  
  def __init__(self):
    pass

class Requirement(object):
  
  def __init__(self):
    pass

class Tool(object):
  
  def __init__(self) :
    
    self.type     = None
    self.command  = None
    self.inputs   = None
    self.outputs  = None
    
  def map(self) :
    pass  


class Step(object):
  """Workflow step"""
  
  def __init__(self) :
    
    self.name     = None
    self.id       = None
    self.inputs   = None
    self.parents  = [None]
    self.children = [None]
    self.run      = Tool()
    self.status   = None
    self.error    = None
    
    
  def init(self, dict) :
    
    pprint(vars(self))
     
      
  def map(self) :
    pass  
    

    

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