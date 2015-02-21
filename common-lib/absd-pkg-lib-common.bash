# ArchBSD package lib: common


APLC_PKG_REST_EXTGLOB='-[0-9]*([^-])-+([^-])-+([^-]).pkg.tar.+([^.])'
APLC_PKG_REST_RE='-([0-9][^-]*)-([^-]+)-([^-]+)\.pkg\.tar\.([^.]+)'
APLC_PKG_FULL_RE="(.*)${APLC_PKG_REST_RE}"

pushopt() {
  local arg="$1"; shift
  local opt
  for opt; do
    eval "APLC_optstack_$opt+=(\"\$(shopt -p \"$opt\")\")"
    shopt "$arg" "$opt"
  done
}

popopt() {
  local opt;
  for opt; do
    eval "local count=\${#APLC_optstack_$opt[@]}"
    eval "local last=\${APLC_optstack_$opt[$((count-1))]}"
    eval "$last"
  done
}

# aplc-split-pkg-filename
#
# input: a package filename
# output: whether it's a valid filename
# clobbers: BASH_REMATCH
# sets:
#   APLC_pkgname
#   APLC_pkgver
#   APLC_pkgrel
#   APLC_pkgarch
#   APLC_pkgcompression
aplc-split-pkg-filename() {
  local full="$1"
  unset APLC_pkgname APLC_pkgver APLC_pkgrel APLC_pkgarch APLC_pkgcompression
  if [[ $full =~ ^${APLC_PKG_FULL_RE}$ ]]; then
    APLC_pkgname="${BASH_REMATCH[1]}"
    APLC_pkgver="${BASH_REMATCH[2]}"
    APLC_pkgrel="${BASH_REMATCH[3]}"
    APLC_pkgarch="${BASH_REMATCH[4]}"
    APLC_pkgcompression="${BASH_REMATCH[5]}"
    true
  else
    false
  fi
}

# aplc-is-version-of-package
#
# input: a package name
# input: a list of package filenames
# clobbers: BASH_REMATCH
# output: whether the files are all versions of the named package
aplc-is-version-of-package() {
  local name="$1"; shift
  local len=${#name}
  local rv=true
  local file
  for file; do
    local base="${file:0:${len}}"
    file="${file:${len}}"
    if [[ $base != "$name" ]]; then
      rv=false
      break
    fi
    if ! [[ $file =~ ^$APLC_PKG_REST_RE$ ]]; then
      rv=false
      break
    fi
  done
  $rv
}

# aplc-each-pkg0
#
# input: a path
# input: a package name
# clobbers: nothing
# output: NUL separated list of package and signature files
aplc-each-pkg() {
  local entry='%s\n'
  if [[ "$1" == '-0' ]]; then
    shift
    entry='%s\0'
  fi
  [[ "$1" == '--' ]] && shift

  local path="$1"
  local pkgname="$2"
  local cmd="$3"
  local file

  pushopt -s extglob nullglob
  for file in "${path}/${pkgname}"${APLC_PKG_REST_EXTGLOB}; do
    printf "$entry" "$file"
  done
  popopt extglob nullglob
}
