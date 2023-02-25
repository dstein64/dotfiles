#!/usr/bin/env bash

set -o errexit

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

head=head
if [ "$(uname)" = Darwin ]; then
  head=ghead
fi

tmpdir="$(mktemp -d)"
trap "rm -r ${tmpdir}" EXIT

cd "${tmpdir}"
# Copy install.sh and packages/ so that relative paths in output are all
# contained within this directory.
cp "${scriptdir}/install.sh" .
cp -r "${scriptdir}/packages" .

mkdir home
HOME=home ./install.sh
tree --charset=ascii -a home | "${head}" -n -2 | tee tree

expected=$(cat << 'END'
home
|-- .config
|   `-- nvim -> ../../packages/nvim/.config/nvim
|-- .gdbinit -> ../packages/gdb/.gdbinit
|-- .gitconfig -> ../packages/git/.gitconfig
|-- .gitignore -> ../packages/git/.gitignore
|-- .screenrc -> ../packages/screen/.screenrc
`-- .vimrc -> ../packages/vim/.vimrc
END
)

cmp tree <(echo "${expected}")
