#!/bin/sh

usage() {
  printf "Usage:
  
  $0 -d <disk> -u <username> [-n <hostname>] [-t <timezone>] [-f <files>] [-h]

  -d: The disk to create a KVM storage pool on. Must be empty and uninitialized with LVM. Do not include \"/dev/\".
  -n: Specify a hostname for the new system. Defaults to 'kvm'.
  -u: Specify a username for the new non-root user that will be created. Defaults to 'brian'.
  -t: Specify a timezone for the system. Defaults to UTC.
  -f: Path to the files directory. Defaults to absolute path to '../files'.
  -h: Print this help message.\n"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d) disk="$2"; shift;;
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
  hostname="kvm"
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
../scripts/kvm/01.sh "$disk" "$username" "$files"
