#!/usr/bin/env bash

set -o errexit

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmpdir="$(mktemp -d)"
trap "rm -r ${tmpdir}" EXIT

cd "${tmpdir}"
# Copy install.sh and packages/ so that relative paths in output are all
# contained within this directory.
cp "${scriptdir}/install.sh" .
cp -r "${scriptdir}/packages" .

mkdir home
HOME=home ./install.sh
tree -a home | tee tree

read -r -d '' expected << END || :
FAIL
home
├── .config
│   └── nvim -> ../../packages/nvim/.config/nvim
├── .gitconfig -> ../packages/git/.gitconfig
├── .gitignore -> ../packages/git/.gitignore
├── .screenrc -> ../packages/screen/.screenrc
└── .vimrc -> ../packages/vim/.vimrc

2 directories, 4 files
END

cmp tree <(echo "${expected}")
