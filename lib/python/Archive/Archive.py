import time
import logging
import sys


# create logger with 'spam_application'
logger = None
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class Archive:
    """docstring for ClassName"""

    def __init__(self, logger_name=None, report=None):

        if logger_name:
            logger = logging.getLogger(logger_name)

        logger.debug("Initialzing Archive instance")

        #super(ClassName, self).__init__()
        self.name = "ArchiveBase"
        self.url = None
        self.token = None
        self.bearer = None
        self.path = None
        self.user = None
        self.password = None
        self.source = None
        self.logfile = None

    def name(self,  name=None):

        if name:
            self['name'] = name

        return self['name']

    def date(self):
        return time.strftime("%Y-%m-%d-%H:%M:%S", time.localtime())

    def push(self):
        logger.error("Method not implemented")
        pass
