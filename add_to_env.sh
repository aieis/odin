#!/bin/bash

ODIN_DIR=~/source/Odin

if [[ $PATH == *"$ODIN_DIR"* ]]; then
    echo "Already in path"
else
    export PATH=$ODIN_DIR:$PATH
fi
