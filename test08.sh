#!/bin/dash

rm -r .shrug/
sh shrug-init
touch z
sh shrug-add z
sh shrug-commit -am "commit"
sh shrug-commit -a "nothing to commit"

sh shrug-branch b1
sh shrug-branch -d b1
