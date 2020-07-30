#!/bin/dash

rm -r .shrug/
sh shrug-init
sh shrug-branch
touch a.txt
sh shrug-add a.txt
sh shrug-commit -m "first commit"
sh shrug-branch master #error message
sh shrug-branch branch1
