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
" * Functions
" *********************************************************

" Opens a terminal, with consistent handling for Neovim and Vim, and handling
" for macOS.
function! s:Terminal()
  if has('nvim')
    topleft split
  endif
  " Use a bash login shell on macOS. Updating 'shell' to do this has unwanted
  " side effects (e.g., slowing down execute() calls).
  if has('mac') && match(&shell, '/\?bash$') !=# -1
    terminal bash -l
  else
    terminal
  endif
  " Switch to terminal-insert mode (only relevant for Neovim).
  startinsert
endfunction

" *********************************************************
" * Settings
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
" * Commands
" *********************************************************

" Generate tags (requires exuberant/universal ctags).
command! Tags !ctags -R .
" Open a terminal.
command! Terminal call s:Terminal()

" *********************************************************
" * Mappings
" *********************************************************

" WARN: The usage of <m-...> mappings may not function properly outside of
" Neovim.

" Turn off highlight.
noremap <silent> <leader><space> :nohlsearch<bar>:echo<cr>
" Change working directory to directory of current file.
noremap <silent> <leader>cd :cd %:h<bar>:pwd<cr>
" Change working directory up a directory.
noremap <silent> <leader>.. :cd ..<bar>:pwd<cr>
" Open current buffer in new tab.
noremap <silent> <leader>b :tab split<cr>
" Open a new tab.
noremap <silent> <leader>n :tabnew<cr>
" Source the current file.
noremap <leader>s :source %<cr>
" Insert longest common text when the completion menu is visible
" (assumes 'completeopt' contains 'longest').
inoremap <expr> <tab> pumvisible() ? "\<c-e>\<c-n>" : "\<tab>"
" Map <c-k> to <up> for the wildmenu.
cnoremap <expr> <c-k> wildmenumode() ? "\<up>" : "\<c-k>"
" Map <c-j> to <down> for the wildmenu. Special handling required.
"   https://stackoverflow.com/q/14842987/1509433
cnoremap <expr> <c-j> wildmenumode() ? feedkeys("\<down>", 't')[-1] : "\<c-j>"
" Move to first non-blank character of the line, in insert mode (override).
inoremap <silent> <c-a> <c-o>^
" Move to the end of line in insert mode (override).
inoremap <silent> <c-e> <end>
" Move to the beginning of the command-line (override).
cnoremap <c-a> <home>
" Enable hjkl movements for insert mode.
inoremap <silent> <c-h> <left>
inoremap <silent> <c-j> <down>
inoremap <silent> <c-k> <up>
inoremap <silent> <c-l> <right>
" Enable h and l movements for the command-line (overrides).
cnoremap <c-h> <left>
cnoremap <c-l> <right>
" Enable alt+(hl) for larger movements in insert mode.
inoremap <silent> <m-h> <c-o>b
inoremap <silent> <m-l> <esc>ea
" Enable alt+(hl) for larger movements in command-line mode. '+' ensures that
" the cursor doesn't move to a preceding command. 'b', '+' and 'e' are
" executed with 'silent!' so that they don't cause an error (e.g., when
" executed from the first character, last line, or last character). 'redraw'
" removes the command-line window. Yanking to the black hole register results
" in the cursor re-appearing.
cnoremap <m-h>
      \ <c-f><cmd>silent! normal! b+<cr><c-c>
      \<cmd>redraw<cr><cmd>normal! "_yl<cr>
cnoremap <m-l>
      \ <c-f><cmd>silent! normal! e<cr>a<c-c>
      \<cmd>redraw<cr><cmd>normal! "_yl<cr>
" Enable <c-s> to save. This key sequence freezes some terminals. Use <c-q> to
" unfreeze.
noremap <c-s> :<c-u>write<cr>
inoremap <c-s> <c-o>:write<cr>
" Open a terminal.
noremap <silent> <leader>t :Terminal<cr>
" Enable alt+k to delete the text until the end of line in insert mode.
inoremap <silent> <m-k> <c-o>D

" === Neovim terminal mappings ===
" Configure some of Vim's special terminal mappings in Neovim. Unlike Vim,
" some of these mappings switch the mode from Terminal-Job to Terminal-Normal.
if has('nvim')
  " Move focus to the next window.
  tnoremap <c-w><c-w> <c-\><c-n><c-w><c-w>
  " Move focus to the specified window.
  tnoremap <c-w>h <c-\><c-n><c-w>h
  tnoremap <c-w>j <c-\><c-n><c-w>j
  tnoremap <c-w>k <c-\><c-n><c-w>k
  tnoremap <c-w>l <c-\><c-n><c-w>l
  " Move the window.
  tnoremap <c-w>H <c-\><c-n><c-w>Hi
  tnoremap <c-w>J <c-\><c-n><c-w>Ji
  tnoremap <c-w>K <c-\><c-n><c-w>Ki
  tnoremap <c-w>L <c-\><c-n><c-w>Li
  " Go to the next tabpage.
  tnoremap <c-w>gt <c-\><c-n>gt
  " Go to the previous tabpage.
  tnoremap <c-w>gT <c-\><c-n>gT
  " Enter an Ex command.
  tnoremap <c-w>: <c-\><c-n>:
  " Paste the specified register.
  tnoremap <expr> <c-w>" '<c-\><c-n>"' . nr2char(getchar()) . 'pi'
  " Send <ctrl-w> to the job in the terminal.
  tnoremap <c-w>. <c-w>
endif

" === Paired bracket mappings ===
" (inspired by vim-unimpaired)
noremap <silent> [b :bprevious<cr>
noremap <silent> ]b :bnext<cr>
noremap <silent> [B :bfirst<cr>
noremap <silent> ]B :blast<cr>
noremap <silent> [l :lprevious<cr>
noremap <silent> ]l :lnext<cr>
noremap <silent> [L :lfirst<cr>
noremap <silent> ]L :llast<cr>
noremap <silent> [q :cprevious<cr>
noremap <silent> ]q :cnext<cr>
noremap <silent> [Q :cfirst<cr>
noremap <silent> ]Q :clast<cr>
" '[-1 and ']+1 are :[range] commands. (see ':h :[range]' or ':h :index' for
" details.
noremap <silent> ]<space>
      \ :<c-u>put =repeat(nr2char(10), v:count1)<bar>'[-1<cr>
noremap <silent> [<space>
      \ :<c-u>put! =repeat(nr2char(10), v:count1)<bar>']+1<cr>

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

" A function for 'formatexpr' that uses the LSP's range formatting.
function! LspFormatExpr()
  if mode() !=# 'n' | return 1 | endif
  lua vim.lsp.buf.range_formatting(
        \ {}, {vim.v.lnum, 0}, {vim.v.lnum + vim.v.count - 1, 0})
  return 0
endfunction

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
  nnoremap <buffer> <silent> gO    <cmd>lua vim.lsp.buf.document_symbol()<cr>
  nnoremap <buffer> <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<cr>
  nnoremap <buffer> <silent> <leader>d
        \ <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>
  nnoremap <buffer> <silent> [d    <cmd>lua vim.lsp.diagnostic.goto_prev()<cr>
  nnoremap <buffer> <silent> ]d    <cmd>lua vim.lsp.diagnostic.goto_next()<cr>

  " Commands
  command! -bar -buffer LspFormatDocument :lua vim.lsp.buf.formatting()
  command! -bar -buffer LspRename :lua vim.lsp.buf.rename()
  command! -bar -buffer LspListDiagnostics :lua vim.lsp.diagnostic.set_loclist()

  " Options
  setlocal omnifunc=v:lua.vim.lsp.omnifunc
  setlocal signcolumn=yes
  setlocal formatexpr=LspFormatExpr()
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
  noremenu <silent> &LSP.&Diagnostics.Show\ Line\ Diagnostics<tab><leader>d
        \ <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>
  noremenu <silent> &LSP.&Diagnostics.List\ Diagnostics<tab>:LspListDiagnostics
        \ <cmd>lua vim.lsp.diagnostic.set_loclist()<cr>
  noremenu <silent> &LSP.&Diagnostics.Next\ Diagnostic<tab>]d
        \ <cmd>lua vim.lsp.diagnostic.goto_next()<cr>
  noremenu <silent> &LSP.&Diagnostics.Previous\ Diagnostic<tab>]d
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
  noremenu <silent> &LSP.&Format\ Selection<tab>gq gq
  noremenu <silent> &LSP.&Information<tab>K
        \ <cmd>lua vim.lsp.buf.hover()<cr>
  noremenu <silent> &LSP.&List\ Document\ Symbols<tab>gO
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
