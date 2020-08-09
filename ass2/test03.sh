#!/bin/dash

# print a contiguous integer sequence

s=$1
f=$2

number=$start
while test $number -le $f
do
    echo $number # print number
    number=`expr $number + 1`  # increment number
done
