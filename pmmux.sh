#!/usr/bin/env sh
#pmmux - package manager multiplexer
set -eu

# FUNCTIONS -------------------------------------------------------------------
exists() { sh -c 'command -v "$1" >/dev/null 2>&1' -- "$1"; }
save () {
    for x do printf %s\\n "$x"|sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/"; done
    echo " "
}

# PACKAGE MANAGERS ------------------------------------------------------------
pm_apk() {
    case "$1" in
    +) shift; sudo apk add -q "$@";;
    present) exists apk;;
    esac
}

pm_apt() {
    case "$1" in
    +) shift; sudo apt-get install -qy "$@";;
    present) exists apt-get;;
    esac
}

pm_brew() {
    case "$1" in
    +) shift; env brew install "$@";;
    !) shift; $*;;
    present) exists brew;;
    esac
}

pm_dnf() {
    case "$1" in
    +) shift; sudo dnf install -y "$@";;
    !) shift; $*;;
    present) exists dnf;;
    esac
}

pm_go() {
    case "$1" in
    +) shift; env go get "$@";;
    present) exists go;;
    esac
}

pm_git() {
    case "$1" in
    !)
        set -x
        set -- "${2%% *}" "${2#* }"
        set -- "$1" "${2%% *}" "${2#* }" "$(mktemp -d)" "$PWD"
        env git clone --branch "$2" --recurse-submodules "$1" "$4" >&2
        cd "$4"
        env sh -c "$3"
        cd "$5"
        rm -rf "$4"
        ;;
    present) exists git;;
    esac
}

pm_pacman() {
    case "$1" in
    +) shift; sudo pacman --needed --noconfirm -qS "$@";;
    !) shift; $*;;
    present) exists pacman;;
    esac
}

pm_pip() {
    case "$1" in
    +) shift; sudo pip install "$@";;
    present) exists pip3 || exists pip;;
    esac
}

pm_sh() {
    case "$1" in
    !) shift; env sh -c "$1";;
    present) true;;
    esac
}

# MAIN ------------------------------------------------------------------------
pmmux() {
    if [ -x "$1" ]; then
        exec="$(save "$@")"
        eval "set -- $(cat "$1" | sed '/^#!.*pmmux/d')"
    fi
    for x in "$@"; do
        if pm_"${x%%[+!]*}" present; then
            case "$(echo "$x" | sed -n '1s/^[^+!]*\(.\).*/\1/p')" in
            +) pm_"${x%%[+!]*}" + ${x#*[+!]};;
            !) pm_"${x%%[+!]*}" ! "${x#*[+!]}";;
            esac
            break;
        fi
    done
    eval "set -- ${exec:-}"
    if [ -n "${1:-}" ] && [ "$(command -v "$(basename "$1")")" != "$1" ]; then
        exec="$(basename "$1")"; shift; set -- "$exec" "$@"
        exec "$@"
    else
        echo "Lazily loading package for $(basename "$1") failed." >&2
        exit 127
    fi
}

pmmux "$@"