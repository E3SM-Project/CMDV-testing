@echo off

echo.
echo Setting PATH and PYTHONPATH
echo.

set current_dir=%cd%

REM export JENKINS_HOME=${current_dir}/${repo_dir}/Jenkins
echo PYTHONPATH=%PYTHONPATH%%current_dir%\lib\python;
set  PYTHONPATH=%PYTHONPATH%%current_dir%\lib\python;
echo.

echo PATH=%PATH%%current_dir%\scripts;
set  PATH=%PATH%%current_dir%\scripts;
echo.

REM Setting up persistant Jenkins dir
REM mkdir -p $JENKINS_HOME

REM echo "Jenkins home:" $JENKINS_HOME


