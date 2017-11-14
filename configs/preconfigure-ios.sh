#!/bin/bash

LANG=C sed -i.bak -e 's/^\("iphoneos-cross".*\)-isysroot .* -fomit-frame-pointer \(.*\)$/\1\2/g' "Configure" || exit $?
LANG=C sed -i.bak -e 's/^\(DIRS= .*\)apps \(.*\)$/\1\1/g' "Makefile.org" || exit $?
