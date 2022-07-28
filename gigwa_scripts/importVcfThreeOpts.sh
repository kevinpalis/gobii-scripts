#!/bin/bash

#####
# Importer for VCFs
# by Josh - jdl232@cornell.edu
#####

DATABASE="VCF_Auto"
TECHNOLOGY="N/A"

if [ -z $3 ]
   then
   echo "Args: [Project] [Run] [File Path]"
   exit
fi

bash importVcfAllOpts.sh $DATABASE $1 $2 $TECHNOLOGY $3
