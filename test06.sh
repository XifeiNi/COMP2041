#!/bin/dash

rm -r .shrug/
sh shrug-init
echo "3" > c.txt
sh shrug-add c.txt
sh shrug-show c.txt
sh shrug-commit -am "add c.txt"
sh shrug-log
echo "4" > c.txt
sh shrug-status
