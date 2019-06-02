#!/bin/sh

provisioning_base_dir=$(readlink -f ../)
export provisioning_base_dir

while [ $# -gt 0 ]; do
    case "$1" in
        -f) files="$2"; shift;;
        *) break
    esac
    shift
done

if [ -z "$files" ]; then
    files="${provisioning_base_dir}/files"
fi

# Load base setup functions and run base_setup
. "${provisioning_base_dir}/lib/base.sh"
base_setup \
    -c \
    -o ubuntu \
    -f "$files"

"${provisioning_base_dir}/scripts/codimd/01.sh" "$files" "$hostname"
