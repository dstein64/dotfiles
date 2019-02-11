" *********************************************************
" * Defaults (when there is no .vimrc)
" * These options are a subset taken/modified from:
" *   $VIMRUNTIME/defaults.vim
" * The ordering matches defaults.vim
" *********************************************************

set nocompatible        " disable vi compatibility
" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start
set history=9999        " 9999 lines of command line history
set ruler               " show cursor position all the time
set showcmd             " display incomplete commands
set wildmenu            " display completion matches in a status line
set ttimeout            " time out for key codes
set ttimeoutlen=100     " wait up to 100ms after Esc for special key
" Show @@@ in the last line if it is truncated.
set display=truncate
" Show a few lines of context around the cursor. Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=5
set incsearch           " incremental search
set nrformats-=octal    " no <c-a> or <c-x> for octal numbers
" <c-u> in insert mode deletes a lot.  Use <c-g>u to first break undo,
" so that you can undo <c-u> after inserting a line break.
" Revert with ":iunmap <c-u>.
inoremap <c-u> <c-g>u<c-u>.
set mouse=a             " mouse works fine in many terminal emulators
syntax on               " syntax highlighting
filetype on             " enable filetype detection
filetype plugin on      " enable loading filetype plugins
filetype indent on      " enable loading filetype indent files

" *********************************************************
" * Additional Customizations
" *********************************************************

let mapleader="\\"			" set <leader>
set number              " show line numbers
set relativenumber      " show relative line numbers
set expandtab           " convert tabs to spaces
set autoindent          " indent newlines using prededing line indent
set tabstop=2           " 2 spaces for tab (and expandtab)
set shiftwidth=2        " 2 spaces for shifting indentation
" Ignore case when pattern is only lowercase. Disable with \C.
set ignorecase
set smartcase
" Highlight search (turn off with :noh[lsearch]
" Use a conditional to prevent this from turning on highlighting when
" :nohlsearch was already executed and .vimrc is manually source'd.
if !&hlsearch
  set hlsearch
endif
" Add mapping for :nohlsearch to turn off highlight.
noremap <silent> <leader>n :nohlsearch<bar>:echo<cr>
" Disable insertion of two spaces after periods when joining lines.
" E.g., when using 'gw' to format lines.
set nojoinspaces
" Only insert longest common text of matches for <c-n>/<c-p>.
set completeopt+=longest
set pastetoggle=<leader>p    " to toggle paste mode (for literal pastes)
" Add mapping to change working directory to directory of current file.
noremap <leader>cd :cd %:h<bar>:pwd<cr>

