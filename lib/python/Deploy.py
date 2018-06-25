import os
import sys
import logging
import json
from pprint import pprint
from Report.TestRunnerLogging import getLogger

logger = None
logger = getLogger(__name__)

class Deploy(object):
  """Deployment Class"""

  def __init__(self, config=None):

    #super(Step, self).__init__()

    logger.debug('Initializing deployment object')

    self.source = None
    self.branch = None
    self.destination = None
    self.baseCommand = None


    # test if source is git repo

    # test if source is path

    if config and isinstance(config, dict) and "hints" in config :
      logger.info("Checking hints")
      hints = config['hints']
    if "git" in hints :
      logger.debug("Checking git section")
    if not repo and "clone" in hints['git'] :
      self.repo = hints['git']['clone']
    else:
      logger.debug("No git repo to clone")
      self.repo = None
    if "branch" in hints['git'] :
      self.branch = hints['git']['branch']

    if self.repo() and self.repo.find('https') > -1 :
      logger.info("Cloning from URL: " + repo )
      process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
      output = process.communicate()[0]
    elif self.repo() and self.repo.find('git@') > -1 :
      logger.info("Cloning using ssh: " + repo )

      # Check if ssh config in path?

      process = subprocess.Popen(["git", "clone" , repo], stdout=subprocess.PIPE)
      output = process.communicate()[0]

    # Checking steps in config - if deployment step build command line argument and execute
    if config['path_to_config'] and os.path.isdir(config['path_to_config']) :
      self.source = config['path_to_config']
    if config['path'] :
      self.source = self.source + "/" + config['path']
    if not os.path.isdir(self.source) :
      logger.error("Invalide path: " + self.source )
      self.source = None

    return self





