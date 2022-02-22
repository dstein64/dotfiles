#!/usr/bin/env bash

set -o errexit

TARGET="${HOME}"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${SCRIPTDIR}/packages"

for arg in "$@"; do
  if [ "$arg" == '--help' ]; then
    echo "Usage: $0 [package1 [package2 ...]]"
    echo 'Without specifying any packages, all packages are installed.'
    echo 'Packages:'
    for package in *; do
      echo "  ${package}"
    done
    exit 0
  fi
done

for prog in [ basename realpath; do
  if ! which "${prog}" &>/dev/null; then
    echo "missing dependency: ${prog}" >&2
    exit 1
  fi
done

PACKAGES=( "$@" )
if [ ${#PACKAGES[@]} == 0 ]; then
  PACKAGES=( * )
fi

function stow {
  trap "$(shopt -p extglob)" RETURN
  shopt -s dotglob
  source_dir="$(realpath "$1")"
  target_dir="$(realpath "$2")"
  target_dir_init="${3:-${target_dir}}"
  for source_child in "${source_dir}"/*; do
    name="$(basename "${source_child}")"
    for ignored in .DS_Store; do
      if [ "${name}" = "${ignored}" ]; then
        continue 2
      fi
    done
    link_source="$(realpath --no-symlinks --relative-to "${target_dir}" \
      "${source_child}")"
    link_path="${target_dir}/${name}"
    link_path_relative="$(realpath --relative-to "${target_dir_init}" \
      "${link_path}")"
    if [ ! -e "${link_path}" ]; then
      # No file nor directory exists. Create symbolic link.
      ln -s "${link_source}" "${link_path}"
      echo "LINK: ${link_path_relative} => ${link_source}"
    elif [ -L "${link_path}" ] \
        && [ "${link_source}" = "$(readlink "${link_path}")" ]; then
      # Symbolic link already exists.
      :
    elif [ ! -L "${link_path}" ] && [ ! -L "${source_child}" ] \
        && [ -d "${link_path}" ] && [ -d "${source_child}" ]; then
      # Directories exist. Call stow recursively.
      stow "${source_child}" "${link_path}" "${target_dir_init}"
    else
      # A conflict can occur from 1) the link path already belonging to a file,
      # 2) the link path already belonging to a link pointing to some other
      # location, or 3) one of the link path or link source is a directory and
      # the other is not.
      echo "CONFLICT: ${link_path_relative}"
    fi
  done
}

for package in "${PACKAGES[@]}"; do
  echo "installing '${package}'"
  source="${SCRIPTDIR}/packages/${package}"
  stow "${source}" "${HOME}"
done
