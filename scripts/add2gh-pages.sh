#!/bin/sh
# if [ -z "$1" ]


WORKDIR=/tmp/`date "+%Y-%m-%d-%H%M%S"`
PROTOCOL=https
GIT=github.com/E3SM-Project
REPOSITORY=CMDV-testing
PROJECT=nightly


# if [ "${GITHUB_USER}"x != "x" -o "${GITHUB_TOKEN}"x != "x"  ] 
if [ "${GITHUB_USER}" == '' -o "${GITHUB_USER}" == '' ]
then
    echo Missing user name, please set GITHUB_USER and GITHUB_TOKEN
    exit 1
else
    echo USER: \"$GITHUB_USER\"
    echo TOKEN: \"$GITHUB_TOKEN\"
    mkdir -p $WORKDIR
    current_dir=`pwd`
    # Checkout github pages
    cd $WORKDIR 
    git clone ${PROTOCOL}://${GIT}/${REPOSITORY}.git
    cd ${WORKDIR}/${REPOSITORY}
    # Set credentials for updating repo
    git remote set-url origin "${PROTOCOL}://$GITHUB_USER:$GITHUB_TOKEN@${GIT}/${REPOSITORY}.git"
    git checkout gh-pages
    # Create destination directory for pages
    mkdir -p ${PROJECT}
    cd ${current_dir}
fi


for i in $* 
    do  
        if [ -f $i ] 
            then
                echo Copying $i
                cp $i $WORKDIR/${REPOSITORY}/$PROJECT
            else
                echo Not a file $i
            fi            
    done    

# Add, commit and push new and updated pages
cd  ${WORKDIR}/${REPOSITORY}
git add ${PROJECT}/*
git commit -m 'Updated notebooks' ${PROJECT}/*
git push

# Cleanup
cd $current_dir
rm -rf $WORKDIR