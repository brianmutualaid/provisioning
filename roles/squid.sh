#!/bin/sh

usage() {
  printf "Usage:
  
  $0 [-n <hostname>] [-u <username>] [-t <timezone>] [-f <files>] [-h]

  -n: Specify a hostname for the new system. Defaults to 'squid'.
  -u: Specify a username for the new non-root user that will be created. Defaults to 'brian'.
  -t: Specify a timezone for the system. Defaults to America/New_York.
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

if [ -z "$disk" ]; then
  usage
fi
if [ -z "$hostname" ]; then
  hostname="squid"
fi
if [ -z "$username" ]; then
  username="brian"
fi
if [ -z "$timezone" ]; then
  timezone="America/New_York"
fi
if [ -z "$files" ]; then
  files=$(readlink -f ../files)
fi
if [ "$help" = "yes" ]; then
  usage
fi

../scripts/common/centos.sh "$hostname" "$username" "$timezone" "$files"
../scripts/squid/01.sh "$files" "$username"
