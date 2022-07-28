#!/bin/bash

#####
# Importer for files by filetype
# by Josh - jdl232@cornell.edu
#####

FILE=$(basename -- $1)
EXTENSION="${FILE##*.}"

if [ -z $1 ]
   then
   echo "Args: [File Path]"
   exit
fi

if [ $EXTENSION = "vcf" ]
then
    bash importVcf.sh $1
elif [ $EXTENSION = "intertek" ]
then
    bash importIntertek.sh $1
else
    echo "Unknown Extension: " $EXTENSION
fi
    
