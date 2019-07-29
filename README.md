
Quick start:

1. [Testing instructions for the cmdv-test-runner](Tests/SOP-Create-test-environment-for-self-tests.md)

[Documentation](https://github.com/E3SM-Project/CMDV-testing/wiki) 

# Release

Preparing 0.9 beta

# Jenkins

Start Jenkins server and slave, server UI at localhost:8080:

- docker-compose -f Docker/jenkins-compose.yaml up

User name and password for Jenkins admin:
- cmdv:cmdv


Singularity images:
{"status":200,"data":{"id":"6e555a28-b1a1-4323-9864-a42c27634e9d","version":"4d96bd8e87e95217f57bb190994ba7fe","file":{"name":"cmdv-gcc-6.sif","size":392876032,"checksum":{"md5":"7b61d2554b4dcb3dc71fb3705f7bcd9d"},"format":"","virtual":false,"virtual_parts":null,"created_on":"2019-05-13T21:16:27.267018478-05:00","locked":null},"attributes":{"application":"singularity","format":"sif","type":"image"},"indexes":{"size":{"total_units":375,"average_unit_size":1048576,"created_on":"2019-05-13T21:16:27.350682312-05:00","locked":null}},"version_parts":{"acl_ver":"f10d0ddce2696f1533dd6f3d551a27b1","attributes_ver":"ca2719b99071301341b94fa74da255c8","file_ver":"557a20d5e4acf66f4bb503caac2c9e4a","indexes_ver":"8938b7b98d6a5e2e57b68359f42cfa8f"},"tags":null,"linkage":null,"priority":0,"created_on":"2019-05-13T21:16:27.350914472-05:00","last_modified":"0001-01-01T00:00:00Z","expiration":"0001-01-01T00:00:00Z","type":"basic","parts":null},"error":null}