from Archive.Archive import Archive
import os
import logging
import sys
from pprint import pprint
from Report.LocalLogging import getLogger



# # init local logger
# logger = None
# logger = logging.getLogger('test-runner')
# logger.setLevel(logging.DEBUG)

logger = None
logger = getLogger(__name__)

class Shock(Archive):  
  """Connector to Shock for reports"""
  
  def __init__(self, config = None , logger_name = None , report=None):
    #super(Archive, self).__init__()
    Archive.__init__(self, logger_name = __name__ )
    
    if not config  :
      logger.error("Missing config")
      sys.exit(1)
       
    self.name = "Shock"
    self.url = "http://localhost:8001/shock/api/"
    
    
    
  
  def push(self, directory = '', report=None) :
    
    # Read dir
    
    
    directory = directory if directory else self.source
    
    if not ( directory and os.path.isdir(directory) ) :
      logger.error("Can't archive, no directory " + directory if directory  else 'not defined' )
      
    else:
      logger.info("Archiving " + directory)  
      
      if self.logfile and os.path.isfile(self.logfile) :
        logger.info("Pushing " + self.logfile)
        
    if report :
      pass
    else:
      logger.debug("No Report provided")  
    
    # Collect files for deploy - build - test - compare
    # Create CMAKE file
    # Create CTEST file
    # Execute ctest -D Experimental in test/run dir
    # Upload to cdash  


class Report():
  """docstring for ClassName"""
  
  def __init__(self, dir):  
    self.name = None
    self.date = None
    self.host = None
    self.summary = {}
    self.tests = [
      
      { 
        "name" : None ,
        "status" : None ,
        "type" : "cmdv-tests" ,
        "steps" : {
          "deploy" : {
            "status" : None ,
            "run" : {
              "total" : None ,
              "success" : None ,
              "failed" : None ,
              }
            },
            "message" : None ,
            "ref" : { "URI" : None }
          },
          "build" : {
            "status" : None ,
            "run" : {
              "total" : None ,
              "success" : None ,
              "failed" : None 
              },
            "message" : None ,
            "ref" : { "URI" : None }
          },
          "run" : {
            "status" : None ,
            "run" : {
              "total" : None ,
              "success" : None ,
              "failed" : None ,
              },
            "message" : None ,
            "ref" : { "URI" : None }
          },
          "postproc" : {
            "status" : None ,
            "run" : {
              "total" : None ,
              "success" : None ,
              "failed" : None ,
              },
            "message" : None ,
            "ref" : { "URI" : None } 
          }
          
        }  
    ]
        