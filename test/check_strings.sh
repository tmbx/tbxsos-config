#!/bin/sh

grep -r 'LSTRINGS\.get' ../* 2>/dev/null | sed 's/.*\(LSTRINGS\.get[^)]*)\).*/\1/g' | grep -v getraw | grep -v 'Fichier bin' | grep -v ':controller' | grep -v '@ident'

