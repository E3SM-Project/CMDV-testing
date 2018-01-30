import time 
import json
from pprint import pprint
from Report.LocalLogging import getLogger

logger = None
logger = getLogger(__name__)


class Report():
  """docstring for ClassName"""
  
  def __init__(self):  
    self.name = None
    self.date = self._date()
    self.host = None
    self.type = "cmdv-tests"
    self.summary = {}
    self.tests = [] # List of TestRun
    
  def _date(self):
    return time.strftime( "%Y-%m-%d-%H:%M:%S",time.localtime() )
  
  def init_tests_run(self , name) :
    
    testRun = TestRun(name) ;
    self.add_test(testRun)
    return testRun
    
  def add_test(self , testRun) :
    self.tests.append(testRun)  
      
  
  
  def toJSON(self) :
    return json.dumps(self.toDict())
  
  def toDict(self) :
    
    logger.debug("Dumping Report " + self.name if self.name else "unknown" )
    # Create dict , remember calls are by reference
    d = self.__dict__
    
    # Array for new dicts
    tests_runs = []
   
      
    for test in self.tests :
      logger.debug("Dumping test " + test.name)
      t = test.__dict__
      # Array for new step dicts
      steps = []
  
      for step in test.steps :
        logger.debug("Dumping step " + step.name)
        steps.append(step.__dict__)
      t['steps'] = steps  
      tests_runs.append(t)    
    d['tests'] = tests_runs
      
    return d
          
      # {
  #       "name" : None ,
  #       "status" : None ,
  #       "type" : "cmdv-tests" ,
  #       "steps" : {
  #         "deploy" : {
  #           "status" : None ,
  #           "run" : {
  #             "total" : None ,
  #             "success" : None ,
  #             "failed" : None ,
  #             }
  #           },
  #           "message" : None ,
  #           "ref" : { "URI" : None }
  #         },
  #         "build" : {
  #           "status" : None ,
  #           "run" : {
  #             "total" : None ,
  #             "success" : None ,
  #             "failed" : None
  #             },
  #           "message" : None ,
  #           "ref" : { "URI" : None }
  #         },
  #         "run" : {
  #           "status" : None ,
  #           "run" : {
  #             "total" : None ,
  #             "success" : None ,
  #             "failed" : None ,
  #             },
  #           "message" : None ,
  #           "ref" : { "URI" : None }
  #         },
  #         "postproc" : {
  #           "status" : None ,
  #           "run" : {
  #             "total" : None ,
  #             "success" : None ,
  #             "failed" : None ,
  #             },
  #           "message" : None ,
  #           "ref" : { "URI" : None }
  #         }
  #
  #       }
  #   ]
        
        
class TestRun():
  
  def __init__(self, name):  
    
    self.name = name
    self.status = None
    self.type = "cmdv-tests"
    self.steps = [ ] # list of TestStep
       
       
  def init_step(self , name) :
    
    testStep = TestStep(name) ;
    self.add_step(testStep)
    
    return testStep
    
  def add_step(self , testStep) :
    self.steps.append(testStep)     

       
class TestStep(): 
  
   def __init__(self , name ):
     
      self.name = name
      self.status = None
      self.tests = {
            "total" : None ,
            "success" : None ,
            "failed" : None ,
          }
      self.message = None
      self.location = { 'URI' : None }    
      self.reports = [] 
      self.dir = None
                     
       
          