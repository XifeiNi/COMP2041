rm -r .shrug/
sh shrug-init
touch a b
sh shrug-add a b
sh shrug-commit -m "first commit"
rm a
sh shrug-commit -m "second commit"

sh shrug-add a
sh shrug-commit -m "second commit"
sh shrug-rm --cached b
sh shrug-commit -m "second commit"
sh shrug-rm b
sh shrug-add b
#sh shrug-rm b
#sh shrug-commit -m "third commit"
#sh shrug-rm b
#sh shrug-commit -m "fourth commit"


