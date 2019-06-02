#!/bin/sh

usage() {
    printf "Usage:
    
    $0 -u <username> -n <hostname> [-t <timezone>] [-e em0] [-i em1] [-f <files>] [-o] [-h]

    -u: Specify a username for the new non-root user that will be created. No
        default.
    -n: Specify a fully qualified hostname for the new system. No default.
    -t: Specify a timezone for the system. Defaults to UTC.
    -e: Specify a custom external interface for the system. Defaults to 'em0'.
    -i: Specify a custom internal interface for the system. Defaults to 'em1'.
    -f: Custom path to a provisioning-files repo. If not specified, or if a file
        isn't found at the custom path, the files directory in this repo is
        used.
    -o: Install and set up an OpenVPN server.
    -h: Print this help message.\n"
    exit 1
}

provisioning_base_dir=$(readlink -f ../)
export provisioning_base_dir

while [ $# -gt 0 ]; do
    case "$1" in
      -n) hostname="$2"; shift;;
      -u) username="$2"; shift;;
      -t) timezone="$2"; shift;;
      -e) extif="$2"; shift;;
      -i) intif="$2"; shift;;
      -f) files="$2"; shift;;
      -o) openvpn="yes";;
      -h) help="yes";;
      *) usage; break
    esac
    shift
done

if [ -z "$hostname" ]; then
    usage
fi
domain=$(printf "$hostname" | rev | cut -sd '.' -f '1,2' | rev)
if [ ! "$domain" ]; then
    printf "Use a fully qualified hostname, e.g. pf.example.com.\\n"
fi
if [ -z "$username" ]; then
    usage
fi
if [ -z "$timezone" ]; then
    timezone="UTC"
fi
if [ -z "$extif" ]; then
    extif='em0'
fi
if [ -z "$intif" ]; then
    intif='em1'
fi
if [ -z "$files" ]; then
    files="${provisioning_base_dir}/files"
else
    files=$(readlink -f "$files")
fi
if [ "$help" = "yes" ]; then
    usage
fi

"${provisioning_base_dir}/lib/base.sh" -o openbsd -n "$hostname" -u "$username" -t "$timezone" -f "$files"
"${provisioning_base_dir}/scripts/pf/01.sh" "$files" "$extif" "$intif" "$hostname" "$domain"
if [ "$openvpn" = "yes" ]; then
    # Run OpenVPN role script; -s skips common setup like hostname and username
    ./openvpn.sh -u "$username" -f "$files" -s
fi
