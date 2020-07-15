rm -r .shrug
if [ -f a.txt ] 
then
	rm a.txt
fi
sh shrug-init
touch a.txt
sh shrug-add a.txt
sh shrug-commit -am "hi"
if [ ! -f .shrug/commit/0/a.txt ]
then
	echo "a.txt not found"
fi

