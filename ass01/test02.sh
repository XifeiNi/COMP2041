#!/bin/dash

rm -r .shrug/
sh shrug-init
echo 1 >a
echo 2 >b
sh shrug-add a b
sh shrug-commit -m "first commit"
echo 3 >c
echo 4 >d
sh shrug-add c d
sh shrug-rm --cached  a c
sh shrug-commit -m "second commit"
sh shrug-show 0:a
sh shrug-show 1:a

