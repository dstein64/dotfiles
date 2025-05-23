#!/usr/bin/env bash

set -o errexit

curdir="${PWD}"
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${scriptdir}/packages"

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

for prog in [ basename ln mkdir readlink realpath; do
  if ! which "${prog}" &>/dev/null; then
    echo "missing dependency: ${prog}" >&2
    exit 1
  fi
done

# Check for realpath arguments that are used later. These arguments are available
# from realpath installed from coreutils, but not available on BusyBox realpath.
for arg in --no-symlinks --relative-to; do
  if ! realpath --help 2>&1 | grep -e "${arg}" &>/dev/null; then
    echo "unsupported realpath argument: ${arg}" >&2
    if [ "$(uname)" = Darwin ] \
        && which brew &>/dev/null \
        && [ -f "$(brew --prefix)/opt/coreutils/libexec/gnubin/realpath" ]; then
      echo 'try setting PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:${PATH}"' >&2
    else
      echo "try installing realpath from coreutils" >&2
    fi
    exit 1
  fi
done

packages=( "$@" )
if [ ${#packages[@]} == 0 ]; then
  packages=( * )
fi

# TODO: Devise a config file protocol such that the functionality here could be
# achieved by the stow function below. For example, in nvim/.config, there could
# be some file specifying that a symlink should not be created to .config, but
# rather that .config should be a directory. The info in that config file would
# be utilized, but the actual file would be skipped for stowing.
function prepare {
  local source_dir="$(realpath "$1")"
  local target_dir="$(realpath "$2")"
  # If there is a e.g., .config directory in $source_dir, make sure this gets
  # created as a directory in $target_dir, so that it's not created as a link
  # when stowing.
  for name in .config .config/nvim; do
    if [ -d "${source_dir}/${name}" ] && [ ! -d "${target_dir}/${name}" ]; then
      mkdir "${target_dir}/${name}"
      echo "  MKDIR: ${name}"
    fi
  done
}

function stow {
  trap "$(shopt -p extglob)" RETURN
  shopt -s dotglob
  local source_dir="$(realpath "$1")"
  local target_dir="$(realpath "$2")"
  local target_dir_init="${3:-${target_dir}}"
  local source_child
  for source_child in "${source_dir}"/*; do
    local name="$(basename "${source_child}")"
    local ignored
    for ignored in .DS_Store; do
      if [ "${name}" = "${ignored}" ]; then
        continue 2
      fi
    done
    local link_source="$(realpath --no-symlinks --relative-to "${target_dir}" \
      "${source_child}")"
    local link_path="${target_dir}/${name}"
    local link_path_relative="$(realpath --relative-to "${target_dir_init}" \
      "${link_path}")"
    if [ ! -e "${link_path}" ]; then
      # No file nor directory exists. Create symbolic link.
      ln -s "${link_source}" "${link_path}"
      echo "  LINK: ${link_path_relative} => ${link_source}"
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
      echo "  CONFLICT: ${link_path_relative}"
    fi
  done
}

cd "${curdir}"
if [ -d "${HOME}" ]; then
  for package in "${packages[@]}"; do
    echo "installing '${package}'"
    source="${scriptdir}/packages/${package}"
    prepare "${source}" "${HOME}"
    stow "${source}" "${HOME}"
  done
else
  echo "ERROR: \$HOME=${HOME}"
  exit 1
fi
