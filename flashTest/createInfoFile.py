#!/usr/bin/env python
import sys, os, socket
sys.path.insert(0, "lib")
import flashTestParser as parser

# Creates a file "test.info" at the top level of the FlashTest
# directory whose contents are sufficient to run a single UnitTest
# problem. Doing this necessitates knowing the name of the user's
# platform, which is deduced by socket.gethostbyaddr().
# The script will not overwrite an existing "test.info"
pathToFlashTest = os.path.dirname(os.path.abspath(sys.argv[0]))
pathToConfig    = os.path.join(pathToFlashTest, "config")
configDict = parser.parseFile(pathToConfig)
if configDict.has_key("site"):
  site = configDict["site"]
else:
  FQHostname = socket.gethostbyaddr(socket.gethostname())[0]
  site       = FQHostname.split(".",1)[0]

pathToInfoFile  = os.path.join(pathToFlashTest, "test.info")

template = (
"""
<%s>
  <UnitTest>
    setupName: unitTest/Grid/UG
    setupOptions: -1d -auto +noio
    numProcs: 1
    parfiles: <defaultParfile>
  </UnitTest>
</%s>
""")

if os.path.exists(pathToInfoFile):
  print ("This script is only meant to create a brand-new \"test.info\" file,\n" +
         "but the file \"%s\" already exists. Exiting." % pathToInfoFile)
  sys.exit(1)

# else
text = (template % (site, site)).strip()
open(pathToInfoFile, "w").write(text)
print "Created \"%s\"" % pathToInfoFile
