#!/bin/dash

for c_file in *.txt
do
    echo gcc -c $c_file
done

for n in one two three
do
    read line
    echo Line $n $line
done

for word in Houston 1202 alarm
do
    echo $word
done
