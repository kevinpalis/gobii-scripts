#!/bin/bash

#####
# Importer for Intertek files
# by Josh - jdl232@cornell.edu
#####

PROJECT="Intertek_Auto"
FILE=$(basename -- $1)
FILENAME="${FILE%%.*}"

if [ -z $1 ]
   then
   echo "Args: [File Path]"
   exit
fi

bash importIntertekThreeOpts.sh $PROJECT $FILENAME $1
