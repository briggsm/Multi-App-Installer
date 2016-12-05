#!/bin/sh

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  DO NOT DELETE THIS FILE  !
#  IT NEEDS TO BE HERE      !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#####################################################
# Note: this file is meant to be run from
#   AppleScript ('with administrator privileged')
#   within the Swift code.
#####################################################

if [ "$2" == "" ]; then
    echo "Usage: $0 sourceFolder/ file1.sh file2.sh file3.sh ..."
    exit 1
fi

# Iterate through all arguments
for scriptName in "$@"
do
    if [[ $scriptName != "$1" ]]; then  # Skip $1 arg (sourceFolder/)
        #echo "runWs-su: $SUDO_USER"
        echo "[runIs.sh] scriptName: $scriptName"
        /bin/sh $scriptName -i $1
    fi
done
