#!/usr/bin/bash

die() {
  local mesg="$1"; shift
  printf "\033[1;35merror:\033[0;0m ${mesg}\n" "$@" >&2
  exit 1
}

source config.sh || die "failed to read config"

setup_user() {
  repo_uid=$(id -u "${repo_user}" 2>/dev/null)
  if (( $? != 0 )); then
    pw useradd "${repo_user}" -m || die "failed to create user ${repo_user}"
    for i in "${repo_addgroups[@]}"; do
      pw groupmod "${i}" -m "${repo_user}" || die "failed to add ${repo_user} to group ${i}"
    done
    repo_uid=$(id -u "${repo_user}")
    if (( $? != 0 )); then die "failed to retrieve user's uid"; fi
  fi
  repo_gid=$(id -g "${repo_user}")
  if (( $? != 0 )); then die "failed to retrieve user's gid"; fi
  repo_home=$(echo ~${repo_user})
  if (( $? != 0 )); then die "failed to retrieve user's home directory"; fi

  [ -d "${repo_home}" ] || die "home does not exist: ${repo_home}"
}

setup_home() {
  for i in  \
    .ssh    \
    uploads \
    log     \
    bin     \
    admin
  do
    mkdir -p "${repo_home}/${i}" \
    || die "failed to create home directory structure"
  done
}

copy_bin() {
  for i in bin/*; do
    install -m755 "${i}" "${repo_home}/bin/" \
    || die "failed to copy scripts"
  done
}

setup_admin_repo() {
  cd "${repo_home}/admin" \
    || die "failed to change directory to ${repo_home}/admin"
  [ -d "admin.git" ] || git init --bare admin.git \
    || die "failed to initialize admin git repository"
  ln -sf "${repo_home}/bin/admin-push-hook" "admin.git/hooks/post-receive" \
    || die "failed to setup post-receive git hook"
}

setup_user
setup_home
setup_admin_repo
