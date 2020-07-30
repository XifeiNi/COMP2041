#!/bin/dash

rm -r .shrug/
sh shrug-init

rm -r .shrug/
touch c
sh shrug-add c #error msg

