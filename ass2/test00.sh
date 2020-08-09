#!/bin/dash

if test Cecilia = wow
then
	echo "wow"
fi

if test Cecilia = meow
then
	echo -n correct\n
elif test Cecilia = cat
then
	echo "Right!"
else
	echo "Wrong...."
fi

