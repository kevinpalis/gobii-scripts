#!/bin/bash

#####
# Importer for Intertek files
# by Josh - jdl232@cornell.edu
#####

DATABASE="Intertek_Auto"
TECHNOLOGY="N/A"

if [ -z $3 ]
   then
   echo "Args: [Project] [Run] [File Path]"
   exit
fi

bash importIntertekAllOpts.sh $DATABASE $1 $2 $TECHNOLOGY $3
