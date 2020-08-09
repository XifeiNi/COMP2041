#!/bin/bash

if [ -d /dev/null ]; 
then
        echo "Usage: $0 <number of lines> <string>"
        exit 1
fi

i=1
while test $i -le $1
do
        echo $2
        i=`expr $i + 1`
done
