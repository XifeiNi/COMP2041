#!/bin/dash

not_prime() {
    local n i
    n=$1
    i=2
    while test $i -lt $n
    do
        test $((n % i)) -eq 0 && return 0
        i=$((i + 1))
    done
    return 1
}

divisible_by_two() {
	test $((n % 2)) -eq 0 && return 0
	test $((n % 2)) -eq 1 && return 1
}

i=0
while test $i -le 100
do
    not_prime $i && divisible_by_two $i && echo $i
    i=$((i + 1))
done
