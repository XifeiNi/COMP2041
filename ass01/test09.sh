#!/bin/dash
touch a
rm -r .shrug/
sh shrug-rm a
sh shrug-init
sh shrug-add a
sh shrug-rm a
rm a
touch b
sh shrug-rm --cached b
sh shrug-add b
sh shrug-rm b
sh shrug-add b
sh shrug-commit -am "commit b"
sh shrug-rm --forced b
