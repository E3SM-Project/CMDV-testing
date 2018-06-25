import Workflow

class Test(object):
  """Test Class"""
  
  tests = []
  files = []
  
  @classmethod
  def find_tests(cls, dir=None , git = False , suffix = "tests_config.json"):
    """Search for test files"""
    current_dir = dir if dir else os.getdir()
    
    for root, dirs, files in os.walk(current_dir):
        for file in files:
            if file.endswith(suffix):
                 logger.debug(os.path.join(root, file))
                 cls.files.append(os.path.join(root, file) )
                 # cls.tests.append(self.load( os.path.join(root, file) ))
    return cls.files             
     
  
  def __init__(self, file = None):
    
    if not file and not os.path.exists(f) :
      logger.error("Missing config file")
      sys.exit(1)
    
    
    pass
    # # super(TestConfig, self).__init__()
#     pprint(base_dir)
#     logger.debug('Source code in ' + repo_dir)
#     logger.debug('Base dir ' + base_dir)
#     if base_dir and not os.path.exists( base_dir ) :
#       logger.debug('Working dir does not exists, creating ' + base_dir )
#       os.makedirs(base_dir)
#
#     # Init data structure
#
#     self.repo         = None
#     self.repo_type    = None
#     self.session      = Session(name=None , id=None)
#     self.directories  = Directories(base_dir=None , session=self.session.name , test=None)
#
#     # pprint(self.directories.__dict__)
#
#     self.config_dir           = None
#     self.defaults             = Defaults()
#     self.defaults.directories = self.directories.clone()
#     self.global_config        = self.load(master_config) if master_config else None
#     self.local_config         = self.load(local_config) if local_config else None
#     self.working_dir          = repo_dir
#     self.base_dir             = base_dir
#     self.tests                = []
#
#     # Add test configs to tests lists
#     if self.global_config :
#       self.tests.append(self.global_config)
#     if self.local_config :
#       self.tests.append(self.local_config)
#
#     # Search for configs
#     if repo_dir :
#       self.find_global_config( repo_dir=repo_dir , git = True )
#       self.find_config( repo_dir=repo_dir , git = False )
#
#
#     # Set defaults from global config
#     if self.global_config :
#       logger.debug("Found global config , setting new defaults")
#       if 'hints' in self.global_config :
#         if 'directories' in self.global_config['hints'] :
#           for d in self.global_config['hints']['directories'] :
#             logger.info('Mapping ' + d)
#             if self.global_config['hints']['directories'][d] :
#               self.defaults.directories.__dict__[d] = self.global_config['hints']['directories'][d]
#             else :
#               logger.debug('No value for ' + d + " keeping default"  )
#         if "archive" in  self.global_config['hints'] :
#           for k in self.global_config['hints']['archive'] :
#             self.defaults.archive[k] = self.global_config['hints']['archive'][k]
#
#     # Creating Directories
#     logger.info("Creating default directories")
#
#     for step in self.defaults.directories.__dict__ :
#       path = self.defaults.directories.__dict__[step]
#       logger.debug("Step: " + step)
#       logger.debug(path)
#       if path :
#         if not os.path.exists(path):
#           logger.debug("Creating " + step + ":\t" + path )
#           os.makedirs( path )
#         else:
#           logger.debug("Path already exists")
#       else:
#         logger.debug("Missing path for " + step)
       
    
      
 

  def load(self, config_file) :

    logger.debug("Loading config " + config_file)
    config = None
    # load config file
    if (config_file and os.path.exists(config_file)):
      with open(config_file, 'r') as f:
           config = json.load(f)
    else:
      logger.error("Not a valid path to config: " + config_file if config_file else "unknown")
      
    config['self'] = config_file  
    # Absolute path to test/config
    # all path in test must be relative to path_to_config
    config['path_to_config'] = os.path.dirname(os.path.abspath(config_file))
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

  
    
    
  def find_global_config(self, repo_dir=None , git = False , config_name = "global_test_config.json") :  
    
    current_dir = repo_dir if repo_dir else os.getdir()
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
         # Debug
         # print("DIR=" + current_dir + " PARENT=" + str(parent_dir))
         # print(len(current_dir))

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
      
  # def directories(self) :
  #   return self.defaults["directories"]
    
  def deploy_dir(self) :
    return self.defaults.directories.deploy  
    