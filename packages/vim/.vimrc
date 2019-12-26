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
inoremap <c-u> <c-g>u<c-u>
set mouse=a             " mouse works fine in many terminal emulators
syntax on               " syntax highlighting
filetype on             " enable filetype detection
filetype plugin on      " enable loading filetype plugins
filetype indent on      " enable loading filetype indent files

" *********************************************************
" * Basic Settings
" *********************************************************

let mapleader='\'       " set <leader>
set number              " show line numbers
set relativenumber      " show relative line numbers
set expandtab           " convert tabs to spaces
set autoindent          " indent newlines using prededing line indent
set tabstop=2           " 2 spaces for tab (and expandtab)
set shiftwidth=2        " 2 spaces for shifting indentation
set formatoptions-=t    " Don't autowrap text
set formatoptions-=c    " Don't autowrap comments
" Ignore case when pattern is only lowercase. Disable with \C.
set ignorecase
set smartcase
" Highlight search (turn off with :noh[lsearch]
" Use a conditional to prevent this from turning on highlighting when
" :nohlsearch was already executed and .vimrc is manually source'd.
if !&hlsearch
  set hlsearch
endif
" Disable insertion of two spaces after periods when joining lines.
" E.g., when using 'gw' to format lines.
set nojoinspaces
" Only insert longest common text of matches for <c-n>/<c-p>.
set completeopt+=longest
" Only insert longest common text of matches for command-line completion.
set wildmode=longest:full,full
" Set a binding to toggle paste mode (for literal pastes).
set pastetoggle=<leader>p
" Use a bash login shell on macOS.
if has('mac') && match(&shell, '/\?bash$') !=# -1
  set shell+=\ -l
endif
" Load man page ftplugin (so :Man is available).
runtime ftplugin/man.vim
" Use :Man for the K command.
set keywordprg=:Man
" Allow unwritten buffers to lose visibility. For ZQ and :q!, vim will issue a
" warning before closing the window. There's no warning for :qall!.
set hidden
" Always show the status line.
set laststatus=2
if has('gui_running')
  set cursorline        " highlight current line
endif

" *********************************************************
" * Basic Commands
" *********************************************************

" Add a command for generating tags (requires exuberant/universal ctags).
command! Tags !ctags -R .

" *********************************************************
" * Basic Mappings
" *********************************************************

" Add mapping for :nohlsearch to turn off highlight.
noremap <silent> <leader>n :nohlsearch<bar>:echo<cr>
" Add mapping to change working directory to directory of current file.
noremap <silent> <leader>cd :cd %:h<bar>:pwd<cr>
" Add mapping to change working directory up a directory.
noremap <silent> <leader>.. :cd ..<bar>:pwd<cr>
" Add mapping to open current buffer in new tab.
noremap <leader>b :tab split<cr>
" Add mapping to launch a terminal.
noremap <silent> <leader>t :terminal<cr>

" *********************************************************
" * Plugins
" *********************************************************

packadd termdebug       " source termdebug
" Add 'nu' and 'rnu' to the default netrw bufsettings. Setting these with a
" ftplugin or after/ftplugin file doesn't work, since the setting is clobbered
" by $VIMRUNTIME/autoload/netrw.vim.
let g:netrw_bufsettings = "noma nomod nowrap ro nobl nu rnu"

" *********************************************************
" * Customizations
" *********************************************************

" Update path with the preprocessor's #include search paths. The C search
" paths are a subset of the C++ search paths, so they don't have to be
" additionally included. This is implemented with a function, command, and
" mapping, to prevent slowing vim's startup time.
function! s:UpdatePath()
  let l:count = 0
  if has('unix') && executable('gcc')
    let l:expr = 'gcc -Wp,-v -x c++ - -fsyntax-only 2>&1 </dev/null'
    let l:lines = systemlist(l:expr)
    if v:shell_error ==# 0
      for l:line in l:lines
        if match(l:line, '^ ') ==# -1 | continue | endif
        let l:include = substitute(l:line, '^ ', '', '')
        " Remove ' (framework directory)' suffix (applicable on macOS).
        if match(l:include, ' (framework directory)$') && !isdirectory(l:include)
          let l:include = substitute(l:include, ' (framework directory)$', '', '')
        endif
        if !isdirectory(l:include) | continue | endif
        " Escape the path, including additional handling for spaces and commas.
        let l:include = fnameescape(l:include)
        let l:include = substitute(l:include, ',', '\\\\,', 'g')
        let l:include = substitute(l:include, '\ ', '\\\\ ', 'g')
        let l:count += 1
        execute 'set path+=' . l:include
      endfor
    endif
  endif
  return l:count
endfunction
command! UpdatePath :call s:UpdatePath()
noremap <silent> <leader>p :UpdatePath<cr>

