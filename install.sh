#!/usr/bin/env bash

if ! which stow &>/dev/null; then
  echo "missing dependency: stow" >&2
  exit 1
fi

TARGET=${HOME}
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}/packages
for package in *; do
  stow --ignore '\.DS_Store' \
       --verbose 1 \
       --target ${TARGET} \
       ${package}
done

