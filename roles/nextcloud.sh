#!/bin/sh

usage() {
  printf "Usage:
  
  $0 -u <username> [-v <nextcloud username>] [-n <hostname>] [-t <timezone>] [-f <files>] [-h]

  -u: Specify a username for the new non-root user that will be created. No default.
  -v: Specify a username for the initial NextCloud admin user. Defaults to 'nc-admin'.
  -n: Specify a hostname for the new system. Defaults to 'cloud'.
  -t: Specify a timezone for the system. Defaults to UTC.
  -f: Path to the files directory. Defaults to absolute path to '../files'.
  -h: Print this help message.\n"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n) hostname="$2"; shift;;
    -u) username="$2"; shift;;
    -v) nc_admin="$2"; shift;;
    -t) timezone="$2"; shift;;
    -f) files="$2"; shift;;
    -h) help="yes";;
    *) usage; break
  esac
  shift
done

if [ -z "$hostname" ]; then
  hostname="cloud"
fi
if [ -z "$username" ]; then
  usage
fi
if [ -z "$nc_admin" ]; then
  nc_admin="nc-admin"
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

../scripts/common/ubuntu.sh "$hostname" "$username" "$timezone" "$files"
../scripts/nextcloud/01.sh "$hostname" "$nc_admin"
