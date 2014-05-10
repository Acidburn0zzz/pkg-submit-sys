#!/usr/bin/bash

msg() {
  local mesg="$1"; shift
  printf "\033[1;32m***\033[0;0m ${mesg}\n" "$@"
}

submsg() {
  local mesg="$1"; shift
  printf "\033[1;34m  ->\033[0;0m ${mesg}\n" "$@"
}

die() {
  local mesg="$1"; shift
  printf "\033[1;31merror:\033[0;0m ${mesg}\n" "$@" >&2
  exit 1
}

source config.sh || die "failed to read config"

check_config() {
  msg "checking for key files..."
  for i in "${admin_keys[@]}"; do
    if [ -e "${i}" ]; then
      submsg "found ssh key: ${i}"
    else
      die "key not found: ${i}"
    fi
  done
}

setup_user() {
  repo_uid=$(id -u "${repo_user}" 2>/dev/null)
  if (( $? != 0 )); then
    msg "creating user ${repo_user}"
    pw useradd "${repo_user}" -m || die "failed to create user ${repo_user}"
    for i in "${repo_addgroups[@]}"; do
      pw groupmod "${i}" -m "${repo_user}" || die "failed to add ${repo_user} to group ${i}"
    done
    repo_uid=$(id -u "${repo_user}")
    if (( $? != 0 )); then die "failed to retrieve user's uid"; fi
  fi
  repo_gid=$(id -g "${repo_user}")
  if (( $? != 0 )); then die "failed to retrieve user's gid"; fi
  repo_home=$(eval "echo ~${repo_user}")
  if (( $? != 0 )); then die "failed to retrieve user's home directory"; fi

  [ -d "${repo_home}" ] || die "home does not exist: ${repo_home}"
  msg "user: ${repo_user} (${repo_uid}:${repo_gid})"
  msg "home: ${repo_home}"
}

setup_home() {
  msg "setting up home directory"
  for i in  \
    .ssh    \
    uploads \
    log     \
    bin     \
    lib     \
    admin
  do
    submsg "${repo_home}/${i}"
    install -d -g "${repo_gid}" -m755 -o "${repo_uid}" "${repo_home}/${i}" \
      || die "failed to create home directory structure"
  done
}

copy_bin() {
  msg "installing scripts"
  install -d -g "${repo_gid}" -m755 -o "${repo_uid}" "${repo_home}/bin" \
    || die "failed to create user's bin/ directory"
  for i in server-bin/*; do
    submsg "${i#server-}"
    install -g "${repo_gid}" -m755 -o "${repo_uid}" "${i}" "${repo_home}/bin/" \
      || die "failed to copy scripts"
  done
  for i in server-lib/*; do
    submsg "${i#server-}"
    install -g "${repo_gid}" -m755 -o "${repo_uid}" "${i}" "${repo_home}/lib/" \
      || die "failed to copy scripts"
  done
}

setup_admin_repo() {
  msg "setting up admin repository"
  pushd "${repo_home}/admin" >/dev/null \
    || die "failed to change directory to ${repo_home}/admin"
  [ -d "admin.git" ] || git init --bare admin.git \
    || die "failed to initialize admin git repository"
  chown -R "${repo_uid}:${repo_gid}" admin.git
  submsg "setting up git push hook"
  rm -f "admin.git/hooks/"{post-receive,post-update}
  #ln -svf "${repo_home}/bin/admin-push-hook" "admin.git/hooks/post-receive" \
  #  || die "failed to setup post-receive git hook"
  ln -svf "${repo_home}/bin/admin-push-hook" "admin.git/hooks/post-update" \
    || die "failed to setup post-receive git hook"
  popd >/dev/null
}

config_home() {
  msg "copying key files..."
  cat "${admin_keys[@]}" > "${repo_home}/.ssh/admin_keys.pub" \
    || die "failed to create .ssh/admin_keys.pub"

  chown -R "${repo_uid}:${repo_gid}" "${repo_home}/.ssh"
  msg "running admin push hook to populate the authorized_keys file"
  su - "${repo_user}" -c "cd ~/admin/admin.git && ../../bin/admin-push-hook 2>/dev/null"

  {
    grep '^repo_user=' config.sh
    grep '^repo_base=' config.sh
    grep '^push_hook=' config.sh
  } > "${repo_home}/admin/config"
}

check_config
setup_user
setup_home
copy_bin
setup_admin_repo
config_home

# vim: set ts=2 sts=2 sw=2 et:
