#!/bin/bash

#get path to script, hacky
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"

#set env
source "$SCRIPT_PATH"/../env.sh

#set aws credentials
. /opt/gina/config/aws.env

#inject all txt files
for vaf_file in $1/*.txt; do
    if [ -f "$vaf_file" ]; then
        python "$SCRIPT_PATH"/fire_insert.py "$vaf_file"
    fi
done
