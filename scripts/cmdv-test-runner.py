#!/usr/bin/env python

import argparse
import git
import glob
import importlib
import json
import logging
import os
from pprint import pprint
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as xmlet
import yaml

# Custom modules
import Archive
import Report
from Deploy import Deploy
from Config import Config as Config
from Report.TestRunnerLogging import TestRunnerLogging as ll
from Report.TestRunnerLogging import getLogger
from Report import Tests
from Workflows.CMDV import Workflow


###############################
# Setup
###############################

# Logging
logger = getLogger("cmdv-test-runner")
logger.info("Setup")


##############################
# Command line input
#############################

# New config


parser = argparse.ArgumentParser()

parser.add_argument("--cmdv", "--config",
                    type=str, dest="config",
                    help="config file (json)")
parser.add_argument("--test",
                    type=str, action='append',
                    help="test config(json)")
parser.add_argument("--format",
                    type=str,
                    help="yaml | json")
parser.add_argument("--ignore-python-version",
                    type=bool,
                    help="ignore python version and don't exit" ,
                    default=False )                     


# OLD

parser.add_argument("-c", "--clone",
                    type=str,
                    help="git clone path")
# parser.add_argument("-v" , "--verbose",
#                     action="store_true",
#                     help="increase output verbosity")
parser.add_argument("-b", "--branch",
                    type=str,
                    help="increase output verbosity")
# parser.add_argument("--config",
#                     type=str ,
#                     help="config file (json)")
parser.add_argument("-global-config", "--defaults",
                    type=str,
                    help="global config file (json)")
parser.add_argument("--archive",
                    type=bool,
                    default=False,
                    help="enable archiving")
parser.add_argument("-s", "--step",
                    type=str,
                    choices=['all', 'deploy', 'build', 'run', 'post'],
                    help="config file (json)",

                    default="all")
parser.add_argument("-d", "--dir",
                    type=str,
                    help="base directory for session and test directories, default is current working directoy",
                    default=os.getcwd())
parser.add_argument("--deploy",
                    type=str,
                    help="deploy directory , if -d is provided copies data from working dir into deploy dir. Overwrites deployment path in config",
                    default=None)
parser.add_argument("--project", "--repo",
                    type=str, dest="repo",
                    help="project/repo/test directory, contains test code; used to discover tests. Default current directory",
                    default=None)
parser.add_argument("--clean",
                    help="start with fresh working directory",
                    action="store_true")
parser.add_argument("--print-config",
                    help="print config and exit",
                    action="store_true")
parser.add_argument("--debug",
                    action="count", default=0,
                    help="debug level, multiple calls increase the level")
parser.add_argument("-v", "--verbosity", action="count", default=0)

args = parser.parse_args()


if __name__ == "__main__":
    
    if (sys.version_info < (3, 0)):
        # Python 2 code in this block
        print('Not python 3, please switch to python3')
        if args.ignore_python_version :
            print('Ignoring version')
        else :
            sys.exit(-1)



    report = Tests.Report()

    logger.info("Initializing config")

    # Get/set global config
    config = Config(file=args.config, dir=args.repo, base_dir=args.dir)

    if args.print_config:
        pprint(config.__dict__)
        sys.exit()

    # Find tests
    if not args.test:
        test_files = config.find_tests(
            dir=config.repo.path, suffix=config.tests['suffix'])
    else:
        test_files = args.test

    for f in test_files:
        logger.debug("Initializing test from " + f)

        global_directories = {
            "input": None,
            "output": None,
            "tmp": config.directories.tmp,
            "working": None,
            "base": config.directories.session,
        }

        workflow = Workflow(file=f, config=config, dirs=global_directories)

        # remember path to test config relative to repo dir
        if os.path.isabs(f):
            m = re.search(config.repo.path + '\/*(.+)', f)
            workflow.relative_test_path = os.path.dirname(m.group(1))
        else:
            workflow.relative_test_path = os.path.dirname(f)

        logger.info("Executing workflow")
        workflow.execute()
        logger.info("Workflow done")

        # module_name="Archive.CDash"
        #
        #   # Standard import
        #   import importlib
        #   # Load "module.submodule.MyClass"
        #   MyClass = getattr(importlib.import_module(module_name), "CDash")
        #   # Instantiate the class (pass arguments to the constructor, if needed)
        #   archive = MyClass(logger_name="test-runner")
