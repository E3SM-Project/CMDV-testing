#!/usr/bin/env bash


echo Setting PATH and PYTHONPATH



current_dir=`pwd`

# export JENKINS_HOME=${current_dir}/${repo_dir}/Jenkins
echo  PYTHONPATH=$PYTHONPATH:${current_dir}/lib/python
export PYTHONPATH=$PYTHONPATH:${current_dir}/lib/python

echo PATH=$PATH:${current_dir}/scripts
export PATH=$PATH:${current_dir}/scripts

# Setting up persistant Jenkins dir
# mkdir -p $JENKINS_HOME

# echo "Jenkins home:" $JENKINS_HOME


