#!/usr/bin/env bash

repo_dir=`dirname "$0"`
current_dir=`pwd`

export JENKINS_HOME=${current_dir}/${repo_dir}/Jenkins
# Setting up persistant Jenkins dir
mkdir -p $JENKINS_HOME

echo "Jenkins home:" $JENKINS_HOME


