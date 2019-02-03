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
set nrformats-=octal    " no Ctrl-A or Ctrl-X for octal numbers
" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" Revert with ":iunmap <C-U>".
inoremap <C-U> <C-G>u<C-U>
set mouse=a             " mouse works fine in many terminal emulators
syntax on               " syntax highlighting
filetype on             " enable filetype detection
filetype plugin on      " enable loading filetype plugins
filetype indent on      " enable loading filetype indent files

" *********************************************************
" * Additional Customizations
" *********************************************************

set number              " show line numbers
set relativenumber      " show relative line numbers
set expandtab           " convert tabs to spaces
set tabstop=4           " 4 spaces for tab (and expandtab)
set shiftwidth=4        " 4 spaces for shifting indentation
set hlsearch            " highlight search (turn off with :noh[lsearch]
" Add mappings for :nohlsearch to turn off highlight.
:noremap <silent> <F4> :nohlsearch<Bar>:echo<CR>
:imap <silent> <F4> <C-O><F4>
" Disable insertion of two spaces after periods when joining lines.
" E.g., when using 'gw' to format lines.
set nojoinspaces
" Only insert longest common text of matches for Ctrl-N/Ctrl-P.
set completeopt+=longest
set pastetoggle=<F5>    " use <F5> to toggle paste mode (for literal pastes)

