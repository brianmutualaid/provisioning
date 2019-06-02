#!/bin/sh

usage() {
  printf "Usage:
  
  $0 -u <username> [-n <hostname>] [-t <timezone>] [-f <files>] [-s] [-h]

  -u: Specify a username for the new non-root user that will be created. No default.
  -n: Specify a hostname for the new system. Defaults to 'openvpn'.
  -t: Specify a timezone for the system. Defaults to UTC.
  -f: Path to the files directory. Defaults to absolute path to '../files'.
  -s: Skip common setup like hostname and username, useful for including this
      role in another role.
  -h: Print this help message.\n"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n) hostname="$2"; shift;;
    -u) username="$2"; shift;;
    -t) timezone="$2"; shift;;
    -f) files="$2"; shift;;
    -s) skip="yes";;
    -h) help="yes";;
    *) usage; break
  esac
  shift
done

if [ -z "$hostname" ]; then
  hostname="openvpn"
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

if [ "$skip" != "yes" ]; then
  ../scripts/common/openbsd.sh "$hostname" "$username" "$timezone" "$files"
fi
../scripts/openvpn/01.sh "$files" "$username"
