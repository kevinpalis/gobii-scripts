#!/bin/bash

#####
# Importer for Intertek files
# by Josh - jdl232@cornell.edu
#
# See: https://github.com/SouthGreenPlatform/Mgdb2/blob/master/src/fr/cirad/mgdb/importing/IntertekImport.java
# 's 'main' method for explanation
#####

PATH=/usr/local/tomcat/webapps/gigwa

if [ -z $5 ]
   then
   echo "Args: [Database] [Project] [Run] [Technology Name] [File Path]"
   exit
fi
   java -cp "$PATH/WEB-INF/lib/*:$PATH/WEB-INF/classes/.:$PATH/." fr.cirad.mgdb.importing.IntertekImport $1 $2 $3 $4 $5 1
