#!/bin/sh

set -e

[ ! -d vendor ] && mkdir vendor
for i in /usr/share/rails/*
do
    if [ ! -L ./vendor/`basename $i` ]; then
        (cd ./vendor && ln -s $i `basename $i`)
    fi
done
[ ! -d vendor/rails ] && (cd vendor && ln -s . rails)

exit 0