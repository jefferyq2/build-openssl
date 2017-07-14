#!/bin/bash

LANG=C sed -i.bak -e "s|makedepend|${CC}|g" "Makefile.org" \
                                            "crypto/Makefile" \
                                            "crypto/srp/Makefile" \
                                            "crypto/ts/Makefile" || exit $?
