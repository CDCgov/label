#!/bin/bash

TP=LABEL_RES/third_party
rm $TP/*Darwin || exit 1
if [ "$(uname -m)" == "x86_64" ]; then
    rm $TP/*aarch64
else
    rm $TP/*x86_64
fi
