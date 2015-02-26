#!/bin/bash

foreachd(){
file=$1
echo $file
for file in $file/*
do
    if [ -d $file ]
    then
            echo $file
            foreachd $file
    else
            echo $file
#            cat $file
    fi
done
}

if [ $# -ge 1 ]
then
    foreachd "$1"
else
    foreachd "."
fi
