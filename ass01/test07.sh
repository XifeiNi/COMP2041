#!/bin/dash

rm -r .shrug/
sh shrug-init
sh shrug-branch
sh shrug-commit -am "A"

touch q
sh shrug-add q
sh shrug-commit -am "add q"
sh shrug-show 0:q
sh shrug-log

sh shrug-branch b1
sh shrug-branch c
sh shrug-branch q
sh shrug-branch -d b1
sh shrug-branch -d master

