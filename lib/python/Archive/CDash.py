from Archive.Archive import Archive
import os
import logging
from pprint import pprint
from Report.LocalLogging import getLogger

logger = None
logger = getLogger(__name__)

class CDash(Archive):
# class CDash:
  
  """docstring for ClassName"""
  def __init__(self, logger_name = None ):
    #super(Archive, self).__init__()
    Archive.__init__(self, logger_name = logger_name)
    
    if logger_name :
      logger = logging.getLogger(logger_name)
    else:
      logger = logging.getLogger(__name__)
       
    self.name = "cdash"
    self.url = "localhost"


    
  def push(self, directory = '' ) :
    
    # Read dir
    pprint(self.__dict__)
    
    directory = directory if directory else self.source
    
    if not ( directory and os.path.isdir(directory) ) :
      logger.error("Can't archive, no directory " + directory if directory  else 'not defined' )
      
    else:
      logger.info("Archiving " + directory)
      
    if self.logfile and os.path.isfile(self.logfile) :
      pass
    
    # Collect files for deploy - build - test - compare
    # Create CMAKE file
    # Create CTEST file
    # Execute ctest -D Experimental in test/run dir
    # Upload to cdash  