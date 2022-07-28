#!/bin/bash

#####
# Importer for VCFs
# by Josh - jdl232@cornell.edu
#####

PROJECT="VCF_Auto"
FILE=$(basename -- $1)
FILENAME="${FILE%%.*}"

if [ -z $1 ]
   then
   echo "Args: [File Path]"
   exit
fi

bash importVcfThreeOpts.sh $PROJECT $FILENAME $1
