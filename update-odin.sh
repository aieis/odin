#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
ODIN_DIR=~/source/Odin

(cd $ODIN_DIR && git pull && make)
