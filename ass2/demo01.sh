#!/bin/bash
start="$1"
end="$2"
filename="$3"

while test $start -le $end
do
        echo "$start"
        start=`expr $start + 1`
done

ls
pwd
chmod 755 $filename
rm $filename

