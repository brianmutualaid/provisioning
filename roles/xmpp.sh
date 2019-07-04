#!/bin/sh

provisioning_base_dir=$(readlink -f ../)
export provisioning_base_dir

while [ $# -gt 0 ]; do
    case "$1" in
      -n) hostname="$2"; shift;;
      -u) username="$2"; shift;;
      -f) files="$2"; shift;;
      *) break
    esac
    shift
done

if [ -z "$hostname" -o -z "$username" ]; then
    usage
fi
domain=$(printf "$hostname" | rev | cut -sd '.' -f '1,2' | rev)
if [ ! "$domain" ]; then
    printf "Use a fully qualified hostname, e.g. pf.example.com.\\n"
fi
timezone="UTC"
if [ -z "$files" ]; then
    files="${provisioning_base_dir}/files"
else
    files=$(readlink -f "$files")
fi

. "${provisioning_base_dir}/lib/base.sh"
base_setup \
  -c \
  -n "$hostname" \
  -t "$timezone" \
  -u "$username" \
  -o openbsd \
  -f "$files"

"${provisioning_base_dir}/scripts/xmpp/01.sh" "$files" "$hostname" "$email"
