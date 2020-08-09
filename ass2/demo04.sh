#!/bin/dash
start=13
if test $# -gt 0
then
    start=$1
fi

i=0
number=$start
file=./tmp.numbers
rm -f $file
while true
do
	if test -r $file
    	then
		echo Terminating because series is repeating
	fi
	echo $i $number
    	k=`expr $number % 2`
    	if test $k -eq 1
    	then
        	number=`expr 7 '*' $number + 3`
    	else
        	number=`expr $number / 2`
    	fi
	i=`expr $i + 1`
done
