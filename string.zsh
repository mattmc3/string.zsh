#!/usr/bin/env zsh

##? string-length - print string lengths
##? usage: string length [STRING...]
function string-length {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo $#s
  done
}

##? string-lower - convert strings to lowercase
##? usage: string lower [STRING...]
function string-lower {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${s:l}
  done
}

##? string-upper - convert strings to uppercase
##? usage: string upper [STRING...]
function string-upper {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${s:u}
  done
}

##? string-trim - remove leading and trailing whitespace
##? usage: string trim [STRING...]
function string-trim {
  (( $# )) || return 1
  printf '%s\n' "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

##? string-escape - escape special characters
##? usage: string escape [STRING...]
function string-escape {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${(q-)s}
  done
}

##? string-unescape - expand escape sequences
##? usage: string unescape [STRING...]
function string-unescape {
  (( $# )) || return 1
  local s
  for s in "$@"; do
    echo ${s:Q}
  done
}

##? string-join - join strings with delimiter
##? usage: string join SEP [STRING...]
function string-join {
  (( $# )) || return 1
  local sep=$1; shift
  echo ${(pj.$sep.)@}
}

##? string-join0 - join strings with null character
##? usage: string join0 [STRING...]
function string-join0 {
  (( $# )) || return 1
  string-join $'\0' "$@" ''
}

##? string-split - split strings by delimiter
##? usage: string split SEP [STRING...]
function string-split {
  (( $# )) || return 1
  local s sep=$1; shift
  for s in "$@"; printf '%s\n' "${(@ps.$sep.)s}"
}

##? string-split0 - split strings by null character
##? usage: string split0 [STRING...]
function string-split0 {
  (( $# )) || return 1
  set -- "${@%$'\0'}"
  string-split $'\0' "$@"
}

##? string-sub - extract substrings
##? usage: string sub [-s start] [-e end] [STRINGS...]
function string-sub {
  (( $# )) || return 1
  local -A opts=(-s 1 -e '-1')
  zparseopts -D -F -K -A opts -- s: e: || return 1
  local s
  for s in "$@"; do
    echo $s[$opts[-s],$opts[-e]]
  done
}

##? string-sub0 - extract substrings using 0-based indexing
##? usage: string sub0 [-o offset] [-l len] [STRINGS...]
function string-sub0 {
  (( $# )) || return 1
  local -A opts=(-o 0)
  zparseopts -D -K -A opts -- o: l:
  local s
  for s in "$@"; do
    echo ${s:$opts[-o]:${opts[-l]:-$#s}}
  done
}

##? string-pad - pad strings to a fixed width
##? usage: string pad [-r] [-c padchar] [-w width] [STRINGS...]
function string-pad {
  (( $# )) || return 1
  local s rl padexp
  local -A opts=(-c ' ' -w 0)
  zparseopts -D -K -F -A opts -- r c: w: || return
  for s in "$@"; do
    [[ $#s -gt $opts[-w] ]] && opts[-w]=$#s
  done
  for s in "$@"; do
    [[ -v opts[-r] ]] && rl='r' || rl='l'
    padexp="$rl:$opts[-w]::$opts[-c]:"
    eval "echo \"\${($padexp)s}\""
  done
}

##? string - manipulate strings
function string {
  emulate -L zsh
  setopt local_options
  0=${(%):-%x}

  if [[ "$1" == (-h|--help) ]]; then
    grep "^##? string -" ${0:A} | cut -c 5-
    echo "usage:"
    grep "^##? usage:" ${0:A} | cut -c 11-
    return
  fi

  if [[ ! -t 0 ]] && [[ -p /dev/stdin ]]; then
    if (( $# )); then
      set -- "$@" "${(@f)$(cat)}"
    else
      set -- "${(@f)$(cat)}"
    fi
  fi

  if (( $+functions[string-$1] )); then
    string-$1 "$@[2,-1]"
  else
    echo >&2 "string: Subcommand '$1' is not valid." && return 1
  fi
}
