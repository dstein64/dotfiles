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

if ! which stow &>/dev/null; then
  echo 'missing dependency: stow' >&2
  exit 1
fi

PACKAGES=( "$@" )
if [ ${#PACKAGES[@]} == 0 ]; then
  PACKAGES=( * )
fi

for package in "${PACKAGES[@]}"; do
  echo "installing '${package}'"
  stow --ignore '\.DS_Store' \
       --verbose 1           \
       --target "${TARGET}"  \
       "${package}"
done
