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
set formatoptions-=t    " don't autowrap text
set formatoptions-=c    " don't autowrap comments
set formatoptions+=j    " remove comment leader when joining lines
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
" Use a popup menu to show possible completions.
set completeopt=longest,menu
" Only insert longest common text of matches for command-line completion.
set wildmode=longest:full,full
" Set a binding to toggle paste mode (for literal pastes).
set pastetoggle=<leader>p
set keywordprg=:Man
" Allow unwritten buffers to lose visibility. For ZQ and :q!, vim will issue a
" warning before closing the window. There's no warning for :qall!.
set hidden
" Always show the status line.
set laststatus=2
if has('gui_running')
  set cursorline        " highlight current line
endif
" Don't scroll the entire screen for messages (Neovim only as of 2021/1/1)
try | set display+=msgsep | catch | endtry

" *********************************************************
" * Basic Commands
" *********************************************************

" Add a command for generating tags (requires exuberant/universal ctags).
command! Tags !ctags -R .

" *********************************************************
" * Basic Mappings
" *********************************************************

" Add mapping for :nohlsearch to turn off highlight.
noremap <silent> <leader><space> :nohlsearch<bar>:echo<cr>
" Add mapping to change working directory to directory of current file.
noremap <silent> <leader>cd :cd %:h<bar>:pwd<cr>
" Add mapping to change working directory up a directory.
noremap <silent> <leader>.. :cd ..<bar>:pwd<cr>
" Add mapping to open current buffer in new tab.
noremap <silent> <leader>b :tab split<cr>
" Add mapping to open a new tab.
noremap <silent> <leader>n :tabnew<cr>
" Add mapping for sourcing the current file.
noremap <leader>s :source %<cr>
" Add mapping to insert longest common text when the completion menu is visible
" (assumes 'completeopt' contains 'longest').
inoremap <expr> <tab> pumvisible() ? "\<c-e>\<c-n>" : "\<tab>"
" Map <c-k> to <up> for the wildmenu.
cnoremap <expr> <c-k> wildmenumode() ? "\<up>" : "\<c-k>"
" Map <c-j> to <down> for the wildmenu. Special handling required.
"   https://stackoverflow.com/q/14842987/1509433
cnoremap <expr> <c-j> wildmenumode() ? feedkeys("\<down>", 't')[-1] : "\<c-j>"

" *********************************************************
" * Plugins
" *********************************************************

packadd! termdebug      " source termdebug
packadd! matchit        " source matchit
runtime ftplugin/man.vim
" Add 'nu' and 'rnu' to the default netrw bufsettings. Setting these with a
" ftplugin or after/ftplugin file doesn't work, since the setting is clobbered
" by $VIMRUNTIME/autoload/netrw.vim.
let g:netrw_bufsettings = "noma nomod nowrap ro nobl nu rnu"

" *********************************************************
" * LSP
" *********************************************************

" Configure LSP for the buffer, if there is an LSP client.
function! s:LspConfigBuffer() abort
  " Mappings
  nnoremap <buffer> <silent> gd    <cmd>lua vim.lsp.buf.declaration()<cr>
  nnoremap <buffer> <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<cr>
  nnoremap <buffer> <silent> K     <cmd>lua vim.lsp.buf.hover()<cr>
  nnoremap <buffer> <silent> gD    <cmd>lua vim.lsp.buf.implementation()<cr>
  nnoremap <buffer> <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<cr>
  nnoremap <buffer> <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<cr>
  nnoremap <buffer> <silent> gr    <cmd>lua vim.lsp.buf.references()<cr>
  nnoremap <buffer> <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<cr>
  nnoremap <buffer> <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<cr>
  nnoremap <buffer> <silent> <leader>d
        \ <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>

  " Commands
  command! -bar -buffer LspFormatDocument :lua vim.lsp.buf.formatting()
  command! -bar -buffer LspRename :lua vim.lsp.buf.rename()
  command! -bar -buffer LspNextDiag :lua vim.lsp.diagnostic.goto_next()
  command! -bar -buffer LspPrevDiag :lua vim.lsp.diagnostic.goto_prev()

  " Options
  setlocal omnifunc=v:lua.vim.lsp.omnifunc
  setlocal signcolumn=yes
endfunction

" nvim-lspconfig is from: https://github.com/neovim/nvim-lspconfig
" Installation paths:
"   Unix: ~/.local/share/nvim/site/pack/plugins/opt/nvim-lspconfig
"   Windows: ~/AppData/Local/nvim-data/site/pack/plugins/opt/nvim-lspconfig
function! s:ConfigureLsp() abort
  if !has('nvim-0.5') | return | endif
  silent! packadd nvim-lspconfig
  if !get(g:, 'lspconfig', 0) | return | endif
  " Disable virtual text diagnostics
  lua vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        \   vim.lsp.diagnostic.on_publish_diagnostics, {
        \     virtual_text = false,
        \   }
        \ )
  if executable('clangd')
    lua require('lspconfig').clangd.setup{}
    augroup lsp_clangd
      autocmd!
      autocmd FileType c,cpp,objc,objcpp call s:LspConfigBuffer()
    augroup END
  endif

  " Add LSP menu items. The right-aligned text for some entries corresponds to
  " the mappings and commands defined in s:LspConfigBuffer.

  " Diagnostics
  noremenu <silent> &LSP.&Diagnostics.Line\ Diagnostics<tab><leader>d
        \ <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>
  noremenu <silent> &LSP.&Diagnostics.Next\ Diagnostic<tab>:LspNextDiag
        \ <cmd>lua vim.lsp.diagnostic.goto_next()<cr>
  noremenu <silent> &LSP.&Diagnostics.Previous\ Diagnostic<tab>:LspPrevDiag
        \ <cmd>lua vim.lsp.diagnostic.goto_prev()<cr>

  " Jumps
  noremenu <silent> &LSP.&Jump.Declaration<tab>gd
        \ <cmd>lua vim.lsp.buf.declaration()<cr>
  noremenu <silent> &LSP.&Jump.Definition<tab>^]
        \ <cmd>lua vim.lsp.buf.definition()<cr>
  noremenu <silent> &LSP.&Jump.Type\ Definition<tab>1gD
        \ <cmd>lua vim.lsp.buf.type_definition()<cr>

  " Other
  noremenu <silent> &LSP.&Format\ Document<tab>:LspFormatDocument
        \ <cmd>lua vim.lsp.buf.formatting()<cr>
  noremenu <silent> &LSP.&Information<tab>K
        \ <cmd>lua vim.lsp.buf.hover()<cr>
  noremenu <silent> &LSP.&List\ Document\ Symbols<tab>g0
        \ <cmd>lua vim.lsp.buf.document_symbol()<cr>
  noremenu <silent> &LSP.&List\ Workspace\ Symbols<tab>gW
        \ <cmd>lua vim.lsp.buf.workspace_symbol()<cr>
  noremenu <silent> &LSP.List\ I&mplementations<tab>gD
        \ <cmd>lua vim.lsp.buf.implementation()<cr>
  noremenu <silent> &LSP.List\ Re&ferences<tab>gr
        \ <cmd>lua vim.lsp.buf.references()<cr>
  noremenu <silent> &LSP.&Rename<tab>:LspRename
        \ <cmd>lua vim.lsp.buf.rename()<cr>
  noremenu <silent> &LSP.&Signature\ Information<tab>^k
        \ <cmd>lua vim.lsp.buf.signature_help()<cr>
endfunction
call s:ConfigureLsp()

" *********************************************************
" * Customizations
" *********************************************************

" When called, updates path with the preprocessor's #include search paths. The
" C search paths are a subset of the C++ search paths, so they don't have to
" be additionally included. This is implemented with a function, command, and
" mapping, 1) to prevent slowing vim's startup time, and 2) so the
" functionality is only used when wanted (as it can slow vim responsiveness).
" The function returns the number of search preprocessor #include search
" paths, or -1 on error.
function! s:UpdatePath()
  if !has('unix') || !executable('gcc')
    echoerr 'A Unix environment with gcc is required.'
    return -1
  endif
  let l:expr = 'gcc -Wp,-v -x c++ - -fsyntax-only 2>&1 </dev/null'
  let l:lines = systemlist(l:expr)
  if v:shell_error !=# 0
    echoerr 'Error ' . v:shell_error . ' returned when running gcc.'
    return -1
  endif
  let l:count = 0
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
  return l:count
endfunction
command! UpdatePath :call s:UpdatePath()
noremap <silent> <leader>up :UpdatePath<cr>

" Use a bash login shell on macOS. Updating 'shell' to do this has unwanted
" side effects (e.g., slowing down execute() calls).
function! s:Terminal()
  if has('nvim')
    topleft split
  endif
  if has('mac') && match(&shell, '/\?bash$') !=# -1
    terminal bash -l
  else
    terminal
  endif
  " Switch to terminal-insert mode (only relevant for Neovim).
  startinsert
endfunction
command! Terminal call s:Terminal()
noremap <silent> <leader>t :Terminal<cr>
