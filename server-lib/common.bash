# some common functions

export ABSD_REPO_LOG_FILE="${HOME}/log/everything.log"

log() {
  local mesg="$1"; shift
  [[ -n $ABSD_REPO_LOG_FILE ]] && \
    printf "%s: ${mesg}\n" "$ABSD_USER" "$@" >> "$ABSD_REPO_LOG_FILE"
  [[ -n $ABSD_USER_LOG_FILE ]] && \
    printf "%s: ${mesg}\n" "$ABSD_USER" "$@" >> "$ABSD_USER_LOG_FILE"
}

err() {
  local mesg="$1"; shift
  printf " (remote) \033[1;31merror:\033[0;0m ${mesg}\n" "$@" >&2
  log "error: $mesg" "$@"
}

wrn() {
  local mesg="$1"; shift
  printf " (remote) \033[1;33m---\033[0;0m ${mesg}\n" "$@" >&2
  printf "\033[1;33m---:\033[0;0m ${mesg}\n" "$@" \
    2>/dev/null >> "${path}/warnings"
  log "warning: $mesg" "$@"
}

msg() {
  local mesg="$1"; shift
  printf " (remote) \033[1;32m***\033[0;0m ${mesg}\n" "$@"
  log "msg: $mesg" "$@"
}

die() {
  err "$@"
  exit 1
}

# run a "hook" if it exists
run_hook() {
  local hookname="$1"; shift
  eval "local hook=\${${hookname}_hook}"
  if [[ -n $hook ]]; then
    $hook "$ABSD_USER" "$@" || wrn "${hookname} hook failed"
  fi
}

# See if an array contains a value or the array is simply 'ALL'
# $1: the value
# ${2-}: the array
contains_or_ALL() {
  if [[ "$2" == ALL ]]; then
    return 0
  fi
  local value="$1"
  shift
  for i in "$@"; do
    if [[ $i == $value ]]; then
      return 0
    fi
  done
  false
}

# See if the repo_list contains a repository for a specific arch
arch_has_repo() {
  local arch="$1"
  local repo="$2"
  for entry in "${repo_list[@]}"; do
    if [[ $entry == $repo || $entry == "$arch:$repo" ]]; then
      return 0
    fi
  done
}

# ABSD_ALLOWED_REPOS/ARCHS are separated by commas and sanitized to
# not contain any spaces, we set IFS=, and use [@] expansion
#    WITHOUT QUOTES!!!
# to turn it into an array we can easily iterate through
allowed_repos=()
allowed_archs=()
allowed_commands=()
load_access_from_environment() {
  local old_ifs="$IFS"
  IFS=','
  allowed_repos=(${ABSD_ALLOWED_REPOS[@]})
  allowed_archs=(${ABSD_ALLOWED_ARCHS[@]})
  allowed_commands=(${ABSD_ALLOWED_COMMANDS[@]})
  IFS="${old_ifs}"
}

# Are we currently allowed to access repo/arch/pkg
check_access() {
  local repo="$1"
  local arch="$2"
  local pkg="$3"

  if ! contains_or_ALL "$repo" "${allowed_repos[@]}"; then
    err 'you do not have access to repository %s' "${repo}"
    return 1
  fi

  if ! contains_or_ALL "$arch" "${allowed_archs[@]}"; then
    err 'you do not have access to architecture %s' "${arch}"
    return 1
  fi
  true
}

source "$HOME/admin/sys_config" || die "failed to read configuration"
source "$HOME/admin/config" || die "failed to read configuration"

load_access_from_environment
