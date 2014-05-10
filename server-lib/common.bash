# some common functions

err() {
  local mesg="$1"; shift
  printf " (remote) \033[1;31merror:\033[0;0m ${mesg}\n" "$@" >&2
}

wrn() {
  local mesg="$1"; shift
  printf " (remote) \033[1;33m---\033[0;0m ${mesg}\n" "$@"
  printf "\033[1;33m---:\033[0;0m ${mesg}\n" "$@" \
    >> "${path}/warnings"
}

msg() {
  local mesg="$1"; shift
  printf " (remote) \033[1;32m***\033[0;0m ${mesg}\n" "$@"
}

die() {
  err "$@"
  exit 1
}

