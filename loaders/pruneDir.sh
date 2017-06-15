#!/bin/bash
#Test if required argument exists
if [ -z "$1" ] || [ -z "$2" ]
  then
    echo "Usage:pruneDir.sh <dirname> <time> [delete]"
    echo "Prunes directory of all files and folders that have not been modified in at leas\
t n minutes"
    echo "dirname: directory name to look in for folders containing files. Prepended with"
    echo "root directory of GOBII install"
    echo "time: maximum number of minutes before now to consider 'recently modified'"
    echo "delete: if 'delete' is the third argument, deletes files, otherwise runs in 'deb\
ug' mode"
    echo "in folder modification times . Example:"
    echo "  > ./pruneDir.sh logs 60 delete"
    echo "    removes files and folders older than one hour in the logs directory"
    echo "  > ./pruneDir.sh crops/test/files 1440"
    echo "    declares files and folders older than one hour in the test crops files direc\
tory that will be removed if command is rerun with 'delete'"
    exit
fi

relativeroot=`dirname $0`"/.."
root=`realpath $relativeroot`"/"

#Find directories under this directory
find $root$1 -mindepth 1 -type d |
while read DIR
do #Find first sub-entry with a modification time in minutes less (-) than second arg
    LINES=$(find "$DIR" -mmin -$2 -print -quit)
    if test -z "$LINES" #If We didn't find any files or subfolders
    then
        if [ "$3" = "delete" ] #If parameter three is the word 'delete'
        then
            rm -rf $DIR
        else #Run in 'what if' mode
            echo "$DIR HAS NO MODIFIED FILES IN THE LAST" $2 "MINUTES"
        fi
    fi
done

#Find files in this directory
find $root$1 -mindepth 1 -maxdepth 1 -type f -mmin +$2 |
while read FILE
do #File in top directory with a mmin of at least (+) second argument
    if [ "$3" = "delete" ] #If parameter three is the word 'delete'
    then
        rm -f $FILE
    else #Run in 'what if' mode
        echo "$FILE WAS NOT MODIFIED IN THE LAST" $2 "MINUTES"
    fi
done
