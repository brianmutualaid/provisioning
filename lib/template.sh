#!/bin/sh

substitute() {
    while [ ! -z "$1" ]; do
        sed -i "s/!${1}!/${2}/g" "$tmp_file"
        shift
        shift
    done
}

compare() {
    if ! diff "$1" "$2" 2> /dev/null; then
        if [ -f "$2" ]; then
            cp "$2" "$2".$(date +%Y-%m-%d_%H:%M:%S)
        else
            printf "${2} not found. Copying new file into place.\\n"
        fi
        cp "$1" "$2"
        chown "$owner" "$2"
        chmod "$permissions" "$2"
        changes="yes"
    fi
}

rename() {
    while [ ! -z "$1" ]; do
        copy_to=$(printf "$copy_to" | sed "s/${1}/${2}/g")
        shift
        shift
    done
}

template() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f) file_path="$2"; shift;;
            -t) target="$2"; shift;;
            -c) content_replacements="$2"; shift;;
            -r) filename_replacements="$2"; shift;;
            -o) owner="$2"; shift;;
            -p) permissions="$2"; shift;;
            -s) restart_command="$2"; shift;;
        esac
        shift
    done
    if [ -z "$owner" ]; then
        owner="root:wheel"
    fi
    if [ -z "$permissions" ]; then
        permissions="644"
    fi
    changes="no"
    for i in $(ls $file_path); do
        tmp_file=$(mktemp)
        cp "$i" "$tmp_file"
        if [ ! -z "$content_replacements" ]; then
            set -f
            substitute $content_replacements
            set +f
        fi
        if [ -d "$target" ]; then
            copy_to="$target"/$(basename "$i")
        else
            copy_to="$target"
        fi
        if [ ! -z "$filename_replacements" ]; then
            set -f
            rename $filename_replacements
            set +f
        fi
        compare "$tmp_file" "$copy_to"
    done
    if [ "$changes" = "yes" ]; then
        eval "$restart_command"
        return 1
    else
        return 0
    fi
    unset file_path
    unset target
    unset content_replacements
    unset filename_replacements
    unset owner
    unset permissions
    unset restart_command
}
