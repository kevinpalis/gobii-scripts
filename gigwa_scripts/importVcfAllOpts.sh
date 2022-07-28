#!/bin/bash

#####
# Importer for VCFs
# by Josh - jdl232@cornell.edu
#
# See: https://github.com/SouthGreenPlatform/Mgdb2/blob/master/src/fr/cirad/mgdb/importing/VcfImport.java
# 's 'main' method for explanation
#####

GPATH=/usr/local/tomcat/webapps/gigwa

if [ -z $5 ]
   then
   echo "Args: [Database] [Project] [Run] [Technology Name] [File Path]"
   exit
fi
   java -cp "$GPATH/WEB-INF/lib/*:$GPATH/WEB-INF/classes/.:$GPATH/." fr.cirad.mgdb.importing.VcfImport $1 $2 $3 $4 $5 1
