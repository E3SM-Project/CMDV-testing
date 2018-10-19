# Creating a Docker container for executing and testing the cmdv-test-runner

From the top level directory of this repository:

1. ```docker build -t  test-runner:local -f Docker/Dockerfiles/python2.dockerfile .```
2. ```docker run -ti -v `pwd`:/CMDV-testing test-runner:local bash```
   1. ```cd /CMDV-testing```
   2. ```source init.sh```
   3. ```cmdv-test-runner --test Tests/unittest-discovery.test.yaml``` 