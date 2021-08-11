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

" Enter insert mode if the current buffer is a terminal buffer.
function! s:InsertModeIfTerminal() abort
  if &buftype ==# 'terminal' && mode() ==# 'n'
    normal! i
  endif
endfunction

" Return the left key sequence.
function! s:Left() abort
  return "\<left>"
endfunction

" Go to git conflict or diff/patch hunk.
function! s:GotoConflictOrDiff(reverse) abort
  let l:flags = 'W'
  if a:reverse | let l:flags .= 'b' | endif
  call search('^\(@@ .* @@\|[<=>]\{7\}\)', l:flags)
endfunction

" :edit the sibling file at the specified offset to the current file. '^' and
" '$' can be used to edit the first and last sibling, respectively.
function! s:EditSiblingFile(offset) abort
  " Only apply on normal buffers. The functionality may work on other buffer
  " types, like 'nowrite', but is not currently supported.
  if !empty(&buftype) | return | endif
  let l:file = expand('%:p')
  if isdirectory(l:file) | return | endif
  let l:parent = fnamemodify(l:file, ':h')
  let l:files = split(globpath(l:parent, '*', 1), '\n')
  " Add hidden files.
  call extend(l:files, split(globpath(l:parent, '.*', 1), '\n'))
  call map(l:files, 'fnamemodify(v:val, ":p")')
  call filter(l:files, '!isdirectory(v:val)')
  if empty(l:files) | return | endif
  call sort(l:files)
  if type(a:offset) ==# v:t_number
    " TODO: binary search
    let l:idx = empty(l:file) ? -1 : index(l:files, l:file)
    let l:idx += a:offset
  elseif a:offset ==# '^'
    let l:idx = 0
  elseif a:offset ==# '$'
    let l:idx = len(l:files) - 1
  else
    return
  endif
  let l:idx = min([len(l:files) - 1, max([0, l:idx])])
  if l:files[l:idx] ==# l:file | return | endif
  execute 'edit ' . fnamemodify(l:files[l:idx], ':.')
endfunction

function! s:ToggleQuickfix() abort
  if getqflist({'winid': 0}).winid
    cclose
  else
    copen
  endif
endfunction

function! s:ToggleLocList() abort
  if getloclist(winnr(), {'winid': 0}).winid
    lclose
  else
    silent! lopen
  endif
endfunction

function! s:CreateToggleMaps(char, option) abort
  execute 'nnoremap <silent> [o' . a:char . ' :<c-u>set ' . a:option . '<cr>'
  execute 'nnoremap <silent> ]o' . a:char . ' :<c-u>set no' . a:option . '<cr>'
  execute 'nnoremap <silent> yo' . a:char . ' :<c-u>set ' . a:option . '!<cr>'
endfunction

" Deletes the current buffer, without changing window layout.
function! s:Bdelete(force) abort
  let l:bufnr = bufnr()
  if !a:force && getbufinfo(l:bufnr)[0].changed
    return
  endif
  bnext
  if bufnr() ==# l:bufnr
    enew
  endif
  let l:bufnr2 = bufnr()
  for l:win in win_findbuf(l:bufnr)
    call win_execute(l:win, l:bufnr2 . 'buffer!')
  endfor
  execute l:bufnr . 'bdelete!'
endfunction

" *********************************************************
" * Settings
" *********************************************************

let mapleader="\<space>" " set <leader>
set number               " show line numbers
set relativenumber       " show relative line numbers
set expandtab            " convert tabs to spaces
set autoindent           " indent newlines using prededing line indent
set tabstop=2            " 2 spaces for tab (and expandtab)
set shiftwidth=2         " 2 spaces for shifting indentation
set formatoptions-=t     " don't autowrap text
set formatoptions-=c     " don't autowrap comments
set formatoptions+=j     " remove comment leader when joining lines
" Ignore case when patte rn is only lowercase. Disable with \C.
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
" Save swap files in ~/.vim/swap instead of using the same directory as the
" edited files. Only do this on Vim, since the defaults on Neovim already use
" a separate directory. One reason for doing this is so that the ]f mapping,
" defined below, doesn't infinitely cycle through swap files on Vim.
if !has('nvim')
  set directory-=.
  " Set directory to ~/.vim/swap// on Unix and ~/vimfiles/swap// on Windows.
  let s:directory = printf('~/%s/swap//', has('win32') ? 'vimfiles' : '.vim')
  call mkdir(expand(s:directory), 'p')
  execute 'set directory^=' . s:directory
endif
" Temporarily highlight search matches (custom setting).
let g:tmphls = 1

" *********************************************************
" * Commands
" *********************************************************

" Generate tags (requires exuberant/universal ctags).
command! Tags !ctags -R .
" Open a terminal.
command! Terminal call s:Terminal()

" *********************************************************
" * Autocommands
" *********************************************************

augroup autocommands
  autocmd!
  " Always enter insert mode when entering a terminal window.
  autocmd WinEnter * call s:InsertModeIfTerminal()
  " Turn off search highlighting when the cursor moves (tmphls).
  autocmd CursorMoved *
        \   if v:hlsearch && get(g:, 'tmphls', 1)
        \       && col('.') - 1 !=# match(getline('.'), @/, col('.') - 1)
        \ |   call feedkeys("\<Plug>(NoHls)")
        \ | endif
  " For insert mode, only do so when not in paste mode, since mappings aren't
  " expanded in that mode.
  autocmd InsertEnter * if !&paste | call feedkeys("\<Plug>(NoHls)") | endif
augroup END

" *********************************************************
" * Mappings
" *********************************************************

" WARN: The usage of <m-...> mappings may not function properly outside of
" Neovim.

" === Leader mappings ===
" Turn off highlight.
noremap <silent> <leader><space> :nohlsearch<bar>:echo<cr>
" Change working directory to directory of current file.
noremap <silent> <leader>. :cd %:h<bar>:pwd<cr>
" Change working directory up a directory.
noremap <silent> <leader>.. :cd ..<bar>:pwd<cr>
" Open current buffer in new tab.
noremap <silent> <leader>b :tab split<cr>
" Open a new tab.
noremap <silent> <leader>n :tabnew<cr>
" Source the current file.
noremap <leader>s :source %<cr>
" Open a terminal.
noremap <silent> <leader>t :Terminal<cr>
" Toggle quickfix window.
noremap <silent> <leader>q :<c-u>call <SID>ToggleQuickfix()<cr>
" Open/close location list window.
noremap <silent> <leader>l :<c-u>call <SID>ToggleLocList()<cr>
" Delete current buffer if there are no changes.
noremap <silent> <leader>x :<c-u>call <SID>Bdelete(0)<cr>
" Delete current buffer even if there are changes.
noremap <silent> <leader>X :<c-u>call <SID>Bdelete(1)<cr>

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
" Move to the end of line in (non-complete) insert mode (override).
inoremap <silent> <expr> <c-e> pumvisible() ? "\<c-e>" : "\<end>"
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
" Enable alt+k to delete the text until the end of line in insert mode.
inoremap <silent> <m-k> <c-o>D
" Insert and edit a line above.
inoremap <m-,> <c-o>O
" Insert and edit a line below.
inoremap <m-.> <c-o>o
" Turn off search highlighting.
if has('nvim') || has('patch-8.2.1978')
  " This approach, with no <expr> mapping, is compatible with nvim-scrollview.
  noremap <Plug>(NoHls) <cmd>nohlsearch<cr>
  noremap! <Plug>(NoHls) <cmd>nohlsearch<cr>
else
  noremap <Plug>(NoHls) :<c-u>nohlsearch<cr>
  noremap! <expr> <Plug>(NoHls) execute('nohlsearch')
endif
" Mappings for copy and cut.
vnoremap <c-c> "+y
vnoremap <c-x> "+d
" Use jk to exit insert mode.
inoremap jk <esc>
" Map <c-space> to omnifunc completion.
inoremap <c-space> <c-x><c-o>
" On Vim, <c-space> inserts <c-@> (<NUL>), confirmed with ctrl-v.
inoremap <c-@> <c-x><c-o>
" Make Y work similarly to C and D.
noremap Y y$

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
noremap <silent> [n :<c-u>call <SID>GotoConflictOrDiff(1)<cr>
noremap <silent> ]n :<c-u>call <SID>GotoConflictOrDiff(0)<cr>
noremap <silent> [f :<c-u>call <SID>EditSiblingFile(-v:count1)<cr>
noremap <silent> ]f :<c-u>call <SID>EditSiblingFile(v:count1)<cr>
noremap <silent> [F :<c-u>call <SID>EditSiblingFile('^')<cr>
noremap <silent> ]F :<c-u>call <SID>EditSiblingFile('$')<cr>

" === Option toggling ===
" (inspired by vim-unimpaired)
nnoremap <silent> [ob :<c-u>set background=light<cr>
nnoremap <silent> ]ob :<c-u>set background=dark<cr>
nnoremap <silent> <expr> yob ':<c-u>set background='
      \ . (&background ==# 'dark' ? 'light' : 'dark') . '<cr>'
call s:CreateToggleMaps('c', 'cursorline')
nnoremap <silent> [od :<c-u>diffthis<cr>
nnoremap <silent> ]od :<c-u>diffoff<cr>
nnoremap <silent> <expr> yod
      \ ':<c-u>' . (&diff ? 'diffoff' : 'diffthis') . '<cr>'
call s:CreateToggleMaps('e', 'expandtab')
call s:CreateToggleMaps('h', 'hlsearch')
call s:CreateToggleMaps('i', 'ignorecase')
call s:CreateToggleMaps('l', 'list')
call s:CreateToggleMaps('n', 'number')
call s:CreateToggleMaps('p', 'paste')
call s:CreateToggleMaps('r', 'relativenumber')
call s:CreateToggleMaps('s', 'spell')
nnoremap <silent> [ot :<c-u>let g:tmphls = 1<cr>
nnoremap <silent> ]ot :<c-u>let g:tmphls = 0<cr>
nnoremap <silent> yot :<c-u>let g:tmphls = !get(g:, 'tmphls', 1)<cr>
call s:CreateToggleMaps('u', 'cursorcolumn')
nnoremap <silent> [ov :<c-u>set virtualedit=all<cr>
nnoremap <silent> ]ov :<c-u>set virtualedit=<cr>
nnoremap <silent> <expr> yov ':<c-u>set virtualedit='
      \ . (empty(&virtualedit) ? 'all' : '') . '<cr>'
call s:CreateToggleMaps('w', 'wrap')
nnoremap <silent> [ox :<c-u>set cursorline cursorcolumn<cr>
nnoremap <silent> ]ox :<c-u>set nocursorline nocursorcolumn<cr>
nnoremap <silent> <expr> yox &cursorline \|\| &cursorcolumn
      \ ? ':<c-u>set nocursorline nocursorcolumn<cr>'
      \ : ':<c-u>set cursorline cursorcolumn<cr>'

" *********************************************************
" * Menus
" *********************************************************

noremenu <silent> &Tools.-sep- <nop>
noremenu <silent> &Tools.&Grep<tab>:grep\ -R\ TEXT\ \.
      \ :<c-u>call feedkeys(":grep -R  ." . repeat(<SID>Left(), 2))<cr>
noremenu <silent> &Tools.&Vim\ Grep<tab>:vimgrep\ TEXT\ **/*
      \ :<c-u>call feedkeys(":vimgrep  **/*" . repeat(<SID>Left(), 5))<cr>
noremenu <silent> &Tools.Next\ Conflict\ or\ Diff<tab>]n
      \ :<c-u>call <SID>GotoConflictOrDiff(0)<cr>
noremenu <silent> &Tools.Previous\ Conflict\ or\ Diff<tab>[n
      \ :<c-u>call <SID>GotoConflictOrDiff(1)<cr>
noremenu <silent> &Tools.Next\ File<tab>]f
      \ :<c-u>call <SID>EditSiblingFile(1)<cr>
noremenu <silent> &Tools.Previous\ File<tab>[f
      \ :<c-u>call <SID>EditSiblingFile(-1)<cr>

let s:options = [
      \   ['c', 'cursorline'],
      \   ['d', 'diff'],
      \   ['e', 'expandtab'],
      \   ['h', 'hlsearch'],
      \   ['i', 'ignorecase'],
      \   ['l', 'list'],
      \   ['n', 'number'],
      \   ['p', 'paste'],
      \   ['r', 'relativenumber'],
      \   ['s', 'spell'],
      \   ['t', 'g:tmphls'],
      \   ['u', 'cursorcolumn'],
      \   ['v', 'virtualedit'],
      \   ['w', 'wrap'],
      \   ['x', 'cursorline/cursorcolumn'],
      \ ]
for [s:key, s:option] in s:options
  execute 'noremenu <silent> &Options.Turn\ &On.' . s:option
        \ . '<tab>[o' . s:key . ' :normal [o' . s:key . '<cr>'
  execute 'noremenu <silent> &Options.Turn\ O&ff.' . s:option
        \ . '<tab>]o' . s:key . ' :normal ]o' . s:key . '<cr>'
  execute 'noremenu <silent> &Options.&Toggle.' . s:option
        \ . '<tab>yo' . s:key . ' :normal yo' . s:key . '<cr>'
endfor

" *********************************************************
" * Plugins
" *********************************************************

packadd! termdebug        " source termdebug
silent! packadd! matchit  " source matchit
runtime ftplugin/man.vim
" Add 'nu' and 'rnu' to the default netrw bufsettings. Setting these with a
" ftplugin or after/ftplugin file doesn't work, since the setting is clobbered
" by $VIMRUNTIME/autoload/netrw.vim.
let g:netrw_bufsettings = "noma nomod nowrap ro nobl nu rnu"
noremap <silent> <c-n> :<c-u>NERDTreeToggle<cr>

" *********************************************************
" * LSP
" *********************************************************

" Define a custom synchronous omnifunc, instead of using the asynchronous
" built-in, v:lua.lsp.omnifunc. This version supports completeopt=longest,
" unlike the built-in (Neovim Issue #15314).
if has('nvim-0.5')
lua << EOF
local result = {}
function _G.lsp_sync_omnifunc(findstart, base)
  if findstart == 0 then return result end
  -- Get LSP completions on first call to the omnifunc (when findstart == 1),
  -- instead of on the second call (when findstart == 0), since the buffer is
  -- modified prior to the second call.
  local bufnr = vim.fn.bufnr()
  result = {}
  local has_clients = not vim.tbl_isempty(vim.lsp.buf_get_clients(bufnr))
  if not has_clients then return -3 end
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  local match = vim.fn.match(line_to_cursor, '\\k*$')
  local token = line:sub(match + 1)
  local params = vim.lsp.util.make_position_params()
  local timeout = 1000
  local completions = vim.lsp.buf_request_sync(
    bufnr, 'textDocument/completion', params, timeout)
  if completions ~= nil then
    for _, val in pairs(completions) do
      items = vim.lsp.util.text_document_completion_list_to_complete_items(
        val['result'], base)
      for _, item in ipairs(items) do
        if vim.startswith(item.word, token) then
          table.insert(result, item)
        end
      end
    end
  end
  return match
end
EOF
endif

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
  nnoremap <buffer> <silent> <leader>f
        \ <cmd>lua vim.lsp.buf.code_action()<cr>
  nnoremap <buffer> <silent> [d    <cmd>lua vim.lsp.diagnostic.goto_prev()<cr>
  nnoremap <buffer> <silent> ]d    <cmd>lua vim.lsp.diagnostic.goto_next()<cr>

  " Commands
  command! -bar -buffer LspFormatDocument :lua vim.lsp.buf.formatting()
  command! -bar -buffer LspRename :lua vim.lsp.buf.rename()
  command! -bar -buffer LspListDiagnostics :lua vim.lsp.diagnostic.set_loclist()

  " Options
  setlocal omnifunc=v:lua.lsp_sync_omnifunc
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
  noremenu <silent> &LSP.&Diagnostics.Code\ Action\ (apply\ fix)<tab><leader>f
        \ <cmd>lua vim.lsp.buf.code_action()<cr>
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
  noremenu <silent> &LSP.&Jump.Switch\ Source/Header<tab>:ClangdSwitchSourceHeader
        \ <cmd>ClangdSwitchSourceHeader<cr>

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
