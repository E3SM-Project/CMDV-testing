#! /usr/bin/env sh

self=$0
source=$1
destination=$2

echo $self $source $destination

# test if $1 and $2 are directories

if [ ! -d $source ] ; then
    echo "No source directory $source"
    exit 2
fi

if [ ! -d $destination ] ; then
    echo "No source directory $destination"
    exit 2
fi

# make sure we have absolute path
current=`pwd`
cd $source
absolute_source_path=`pwd`

# duplicate directory structure
find . -type d -exec mkdir -p -- ${destination}/{} \;

# create symlinks in dirs
find . -type f -exec ln  -s ${absolute_source_path}/{} ${destination}/{} \; 


cd ${current}   