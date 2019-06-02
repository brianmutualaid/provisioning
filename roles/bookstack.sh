#!/bin/bash

provisioning_base_dir=$(readlink -f ../)
export provisioning_base_dir

while [ $# -gt 0 ]; do
    case "$1" in
        -f) files="$2"; shift;;
        -n) hostname="$2"; shift;;
        -u) username="$2"; shift;;
        -e) email="$2"; shift;;
        *) break
    esac
    shift
done

if [ -z "$files" ]; then
    files="${provisioning_base_dir}/files"
fi
if [ -z "$hostname" -o -z "$username" -o -z "$email" ]; then
    exit 1
fi

timezone="UTC"

# Load base setup functions and run base_setup
. "${provisioning_base_dir}/lib/base.sh"
base_setup \
    -c \
    -n "$hostname" \
    -t "$timezone" \
    -u "$username" \
    -o ubuntu \
    -f "$files"

"${provisioning_base_dir}/scripts/bookstack/01.sh" "$files" "$hostname" "$email"
