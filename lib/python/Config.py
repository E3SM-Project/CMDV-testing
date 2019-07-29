import os
import sys
import logging
import json
import yaml
import re
from pprint import pprint
from time import gmtime, strftime
from Report.TestRunnerLogging import getLogger


logger = None
logger = getLogger(__name__)


class Session(object):

    def __init__(self, id=None, name=None, prefix=None, path=None):

        if prefix:
            self.prefix = prefix
        else:
            self.prefix = ''

        if not id:
            id = strftime("%Y-%m-%d-%H%M%S", gmtime())
            logger.debug("Missing session id, setting id to " + id)
        if not name:
            name = id
            logger.debug("Missing session name, setting to session id")
        self.name = self.prefix + name if self.prefix else name
        self.id = id
        self.path = path
        # TODO set location for later use - assuming local file system for now
        self.location = Location({'path': path})


class Defaults(object):

    def __init__(self):

        self.directories = {}
        self.archive = {}


class Directories(object):
    """Test directories"""

    def __init__(self, base_dir=None, session=None, test=None):

        # base/session/test/[setup,build,run,postprocess,archive]

        if not session:
            session = strftime("%Y-%m-%d-%H%M%S", gmtime())
            logger.debug(
                "Missing session name, setting session dir to " + session)
        if not test:
            test = 'test-' + strftime("%Y-%m-%d-%H%M%S", gmtime())
            logger.warning("No test name - setting test name to " + test)

        if not base_dir:
            base_dir = os.getcwd()
            logger.debug("Setting base_dir to current working dir")

        self.repo = None     # source dir containing tests
        self.base = base_dir  # base dir containig setup,build,run and postprocess directories
        self.session = "/".join([self.base, session])
        self.tmp = None

        if test:
            self.test = "/".join([self.session, test])
            self.setup = "/".join([self.test, "setup"])
            self.build = "/".join([self.test, "build"])
            self.run = "/".join([self.test, "run"])
            self.postprocess = "/".join([self.test, "postprocess"])
            self.data = "/".join([self.test, "data"])
            self.archive = "/".join([self.test, "archive"])
        else:
            self.test = None
            self.setup = None
            self.build = None
            self.run = None
            self.postprocess = None
            self.data = None
            self.archive = None

    def clone(self):

        obj = Directories()
        obj.repo = self.repo
        obj.base = self.base
        obj.session = self.session
        obj.test = self.test
        obj.setup = self.setup
        obj.build = self.build
        obj.run = self.run
        obj.postprocess = self.postprocess
        obj.data = self.data
        obj.archive = self.archive

        return obj


class Location(object):
    """Location class"""

    def __init__(self, loc=None, dir=None):

        self.name = None
        self.type = None
        self.path = None
        self.Class = None
        self.location = None

        if loc:
            for k in loc:
                # loop over keys and add values to objetc
                setattr(self, k, loc[k])


class Config(object):
    """Global config for session and test workflows"""

    def __init__(self, file=None, dir=None, base_dir=None):
        """
        file      = path to config file
        dir       = path for repository
        base_dir  = top level path (working directory) for session directories 
        """

        # if no file and dir search for config return config
        if not file:
            # no dir set to current working directory
            if dir:
                cfg = self._find_config(repo_dir=dir)
            else:
                cfg = self._find_config(repo_dir=os.getcwd())
        else:
            cfg = self._load(file)

        # load config
        for k in cfg:
            if os.environ.get('DEBUG' , False ) : 
                print(k + "\t" + str(cfg[k]))
            setattr(self, k, cfg[k])

        if dir:
            logger.debug("Repo dir provided")
        elif file:
            logger.debug("Project dir provided - should search for config")
        else:
            logger.debug(
                "Missing config file or directory - setting dir to current working dir")
            dir = os.getcwd()

        # Set attributes
        # v1.0
        self.cmdvVersion = cfg['cmdvVersion'] if "cmdvVersion" in cfg else None
        # CMDVGlobalConfig
        self.Class = cfg['class'] if "class" in cfg else None
        # Global-Config
        self.label = cfg['label'] if "label" in cfg else "Global-Config"
        # Template for global config
        self.doc = cfg['doc'] if "doc" in cfg else None
        self.custom = cfg['custom'] if "custom" in cfg else None
        self.hints = None         # hints object { cime , git , docker }

        # Set repo location - move to Location class
        loc = {"name": None,
               "path": None,
               "location": None,
               "type": None,
               }
        if dir and os.path.exists(dir):
            loc = {"path": dir,
                   "location": "file://" + os.path.abspath(dir),
                   "name": os.path.dirname(os.path.abspath(dir)),
                   "type": "local"
                   }
        elif "repo" in cfg:
            # set type to default
            if not "type" in cfg['repo']:
                logger.warning(
                    "Missing type field for repo - assuming local directory")

            # check types
            if cfg['repo']['type'] == "local":
                loc['type'] = cfg['repo']['type']
                if "path" in cfg['repo'] and "type" in cfg['repo']:
                    if os.path.isabs(cfg['repo']['path']):
                        logger.warning(
                            "Repo path is absolute can make problems.")
                        loc['path'] = cfg['repo']['path']
                    else:
                        # make aboslute for current machine and in relation to config file
                        loc['path'] = cfg['self']['path'] + \
                            "/" + cfg['repo']['path']
                    if "location" in cfg and cfg['location']:
                        if not location.endswith(cfg['path']):
                            logger.error("Path and location differ. " +
                                         "\n".join([cfg['path'], cfg['location']]))
                            sys.exit(1)
                        else:
                            loc["location"] = cfg['location']
                    else:
                        loc["location"] = "file://" + loc['path']
            elif cfg['repo']['type'] == "git":
                logger.error("Type is git - Not implemented")
                sys.exit(1)
            elif cfg['repo']['type'] == "http":
                logger.error("Type is http - Not implemented")
                sys.exit(1)
            elif cfg['repo']['type'] == "ftp":
                logger.error("Type is ftp - Not implemented")
                sys.exit(1)
            else:
                logger.error("Unknown type " +
                             cfg['repo']['type'] + " - Not implemented")
                sys.exit(1)
        else:
            # no cli option nor configured - defaulting to current working dir
            logger.warning("No path specified - using config dir")
            loc["path"] = cfg['self']['path']
            loc["location"] = "file://" + cfg['self']['path']
            loc["type"] = "local"

        self.repo = Location(loc)

        if "session" in cfg:
            s = cfg['session']
            self.session = Session(id=s['id'] if "id" in s else None,
                                   name=s['name'] if "name" in s else None,
                                   prefix=s['prefix'] if "prefix" in s else None,
                                   path=s['path'] if "path" in s else None,
                                   )
        else:
            self.session = Session(
                id=None,
                name=None,
                prefix=None,
                path=base_dir if base_dir and os.path.exists(
                    base_dir) else os.getcwd(),
            )

        # directories:
        #   working: string           # parent directory for session directories
        #   session: null             # ${directories.working}/session.name/
        #   test: null                # ${directories.session}/test.name/
        #   setup: ./setup          # ${directories.test}/./setup/
        #   build: ./build            # ${directories.test}/./build/
        #   run: ./run                # ${directories.test}/./run/
        #   postprocessing: ./run     # ${directories.test}/./run/

        self.directories = Directories(
            base_dir=self.session.path,
            session=self.session.name,
            test=None,
        )
        self.directories.repo = self.repo.path

        self.tests = {
            # suffix for test config file, default test.json
            "suffix": cfg['tests']['suffix'] if 'tests' in cfg
            and 'suffix' in cfg['tests'] else "test.json",
            "files": cfg['tests']['files'] if 'tests' in cfg
            and 'files' in cfg['tests'] else [],

        }

        if "dashboard" in cfg:
            self.dashboard = Location(
                {
                    "path": cfg['dashboard']['path'] if "path" in cfg['dashboard'] else None,
                    # e.g cdash| cmdv-testing |...  , default local
                    "type": cfg['dashboard']['type'] if "type" in cfg['dashboard'] else "local",
                    "name": cfg['dashboard']['name'] if "name" in cfg['dashboard'] else None,
                    "location": cfg['dashboard']['location'] if "location" in cfg['dashboard'] else None,
                    "Class": "Dashboard"
                }
            )
        else:
            self.dashboard = None

        if "archive" in cfg:
            self.archive = Location(
                {
                    "path": cfg['archive']['path'] if "path" in cfg['archive'] else None,
                    "type": cfg['archive']['type'] if "type" in cfg['archive'] else "local",
                    "name": cfg['archive']['name'] if "name" in cfg['archive'] else None,
                    "location": cfg['archive']['location'] if "location" in cfg['archive'] else None,
                    "Class": "Archive"
                }
            )
        else:
            self.archive = None

        if "workflow" in cfg:
            self.workflow = cfg['workflow']
        else:
            self.workflow = {
                "steps":  ["setup", "build", "run" "postprocessing"],
            }

    def _find_config(self, repo_dir=None,  config_name="cmdv-testing.config.yaml", repo_type=None):
        """Find config file in   """
        if not repo_dir:
            logger.error("Can't search for config, missing directory")
            sys.exit(1)

        config_file = None
        parent_dir = None
        cfg = None

        if repo_type:
            logger.debug("Local git repo")
            while (not (config_file or parent_dir)):

                config_file = current_dir + "/" + \
                    config_name if os.path.isfile(
                        current_dir + "/" + config_name) else None

                if os.path.isdir(current_dir + "/.git"):
                    parent_dir = current_dir

                if len(current_dir) <= 1:
                    parent_dir = current_dir

                (current_dir, tail) = os.path.split(current_dir)
                # Debug
                # print("DIR=" + current_dir + " PARENT=" + str(parent_dir))
                # print(len(current_dir))

        if not config_file:
            logger.debug(
                "Searching for config - following directory structure down - starting at " + str(repo_dir))
            for root, dirs, files in os.walk(repo_dir):
                for file in files:
                    if not config_file and file.endswith(config_name):
                        logger.info("Found config " + os.path.join(root, file))
                        config_file = os.path.join(root, file)

        if not config_file:
            logger.error("No global config file found")
            sys.exit(1)
        else:
            cfg = self._load(config_file)

        # Return dict
        return cfg

    def _load(self, config_file, format=None):

        logger.debug("Loading config " + config_file)
        cfg = None
        # load config file

        if config_file.endswith(".yaml"):
            format = "yaml"
        elif config_file.endswith(".json"):
            format = "json"

        if (config_file and os.path.exists(config_file)):
            with open(config_file, 'r') as f:

                try:
                    if format == "yaml":
                        cfg = yaml.load(f , Loader=yaml.FullLoader)
                    elif format == "json":
                        cfg = json.load(f)
                except:
                    logger.error("Can't load config  " + config_file)
                    raise
                    sys.exit(1)
        else:
            logger.error("Not a valid path to config: " +
                         config_file if config_file else "unknown")
            sys.exit(1)

        cfg['self'] = {
            "name": config_file,
            "path": os.path.dirname(os.path.abspath(config_file))
        }

        if not 'class' in cfg and not cfg['class'] == 'CMDVGlobalConfig':
            logger.error("Missing class key or wrong class in config")
            sys.exit(1)

        if not 'cmdvVersion' in cfg and not cfg['cmdvVersion'] == 'v1.0':
            logger.error(
                "Missing cmdvVersion key or wrong version in config. Expecting v1.0")
            sys.exit(1)

        return cfg

    def find_tests(self, dir=None, git=False, suffix=None):
        """Search for test files"""

        if not dir:
            dir = self.repo.path
        if not suffix:
            suffix = self.tests['suffix']

        current_dir = dir if dir else os.getdir()

        for root, dirs, files in os.walk(current_dir):
            for file in files:
                if file.endswith(suffix):
                    logger.debug(current_dir + " :: " + root + " :: " + file)
                    logger.debug(os.path.join(root, file))
                    logger.debug(root.find(current_dir))
                    logger.debug(root.rfind(current_dir))
                    m = re.search(current_dir + '(.+)', root)
                    logger.debug(m)
                    logger.debug(m.group(1))
                    pprint(m.groups())
                    self.tests['files'].append(os.path.join(root, file))
                    # cls.tests.append(self.load( os.path.join(root, file) ))

        return self.tests['files']


class TestWorkflow(object):
    """Test Class"""

    tests = []
    files = []

    @classmethod
    def find_tests(cls, dir=None, git=False, suffix="tests_config.json"):
        """Search for test files"""
        current_dir = dir if dir else os.getdir()

        for root, dirs, files in os.walk(current_dir):
            for file in files:
                if file.endswith(suffix):
                    logger.debug(os.path.join(root, file))
                    cls.files.append(os.path.join(root, file))
                    # cls.tests.append(self.load( os.path.join(root, file) ))
        return cls.files

    def __init__(self, file=None):

        if not file and not os.path.exists(f):
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

    def load(self, config_file):

        logger.debug("Loading config " + config_file)
        config = None
        # load config file
        if (config_file and os.path.exists(config_file)):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            logger.error("Not a valid path to config: " +
                         config_file if config_file else "unknown")

        config['self'] = config_file
        # Absolute path to test/config
        # all path in test must be relative to path_to_config
        config['path_to_config'] = os.path.dirname(
            os.path.abspath(config_file))
        return config

    def setup(self, config):
        # setup environment
        if isinstance(config, dict):
            if "hints" in config:
                hints = config['hints']
                # Setting up directories
                if "directories" in hints:
                    logger.info("Creating global dirs")
                    for d in hints['directories']:
                        logger.debug("Checking " + d)
                        # Create dir if not exists
                        if hints['directories'][d] and not os.path.exists(hints['directories'][d]):
                            logger.debug("Creating " + hints['directories'][d])
                            os.makedirs(hints['directories'][d])
                else:
                    hints['directories'] = None
            else:
                config['hints'] = None

    def find_global_config(self, repo_dir=None, git=False, config_name="global_test_config.json"):

        current_dir = repo_dir if repo_dir else os.getdir()
        config_file = None
        parent_dir = None

        if git:
            while (not (config_file or parent_dir)):

                config_file = current_dir + "/" + \
                    config_name if os.path.isfile(
                        current_dir + "/" + config_name) else None

                if os.path.isdir(current_dir + "/.git"):
                    parent_dir = current_dir

                if len(current_dir) <= 1:
                    parent_dir = current_dir

                (current_dir, tail) = os.path.split(current_dir)
                # Debug
                # print("DIR=" + current_dir + " PARENT=" + str(parent_dir))
                # print(len(current_dir))

        else:
            for root, dirs, files in os.walk(current_dir):
                for file in files:
                    if file.endswith(config_name):
                        print(os.path.join(root, file))
                        config_file = os.path.join(root, file)

        if not config_file:
            logger.debug("No global config file found")
        else:
            logger.debug("Loading global config file " + config_file)
            self.tests.append(self.load(config_file))
            if not self.global_config:
                self.global_config = self.load(config_file)

    # def directories(self) :
    #   return self.defaults["directories"]

    def setup_dir(self):
        return self.defaults.directories.setup


if __name__ == "__main__":
    import sys
    check_config(int(sys.argv[1]))
