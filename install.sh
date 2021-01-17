#!/usr/bin/env bash

# Usage: ./install.sh [package1 [package2 ...]]
# Without specifying any packages, all packages are installed.

set -o errexit

if ! which stow &>/dev/null; then
  echo "missing dependency: stow" >&2
  exit 1
fi

TARGET="${HOME}"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${SCRIPTDIR}/packages"

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
