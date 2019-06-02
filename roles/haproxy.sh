#!/bin/sh

usage() {
  printf "Usage:
  
  $0 -u <username> -n <hostname> [-t <timezone>] [-f <files>] [-h]

  -u: Specify a username for the new non-root user that will be created. No default.
  -n: Specify a hostname for the new system. No default.
  -t: Specify a timezone for the system. Defaults to UTC.
  -f: Path to the files directory. Defaults to absolute path to '../files'.
  -h: Print this help message.\n"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n) hostname="$2"; shift;;
    -u) username="$2"; shift;;
    -t) timezone="$2"; shift;;
    -f) files="$2"; shift;;
    -h) help="yes";;
    *) usage; break
  esac
  shift
done

if [ -z "$hostname" ]; then
  usage
fi
if [ -z "$username" ]; then
  usage
fi
if [ -z "$timezone" ]; then
  timezone="UTC"
fi
if [ -z "$files" ]; then
  files=$(readlink -f ../files)
fi
if [ "$help" = "yes" ]; then
  usage
fi

../scripts/common/centos.sh "$hostname" "$username" "$timezone" "$files"
# Make sure these arguments are referenced correctly from 01.sh before uncommenting!
#../scripts/haproxy/01.sh "$username" "$files"
