@echo off

set self=%0
set source=%1
set destination=%2

echo.
echo Argument 0 (script):       %self%
echo Argument 1 (source):       %source%
echo Argument 2 (destination):  %destination%
echo.

setlocal enableextensions enabledelayedexpansion

REM test if %1 and %2 are directories:
if not exist %source%\* (
    echo No source directory %source%
    exit /b 2
)
if not exist %destination%\* (
    echo No destination directory %destination%
    exit /b 2
)

REM make sure we have absolute path:
set current=%cd%
cd %source%
set absolute_source_path=%cd%

REM duplicate directory structure:
xcopy %source% %destination% /T /E

REM create symlinks in dirs:
for /R %%f in (*.*) do (
    set B=%%f
    mklink %destination%\!B:%CD%\=! %source%\!B:%CD%\=!
)

endlocal

cd %current%   