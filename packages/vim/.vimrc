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
" Show a few lines of context around the cursor. Note that this makes the text
" scroll if you mouse-click near the start or end of the window.
set scrolloff=5
set incsearch           " incremental search
set nrformats-=octal    " no <c-a> or <c-x> for octal numbers
" <c-u> in insert mode deletes a lot. Use <c-g>u to first break undo, so that
" you can undo <c-u> after inserting a line break. Revert with ":iunmap <c-u>.
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
function! s:Terminal() abort
  if has('nvim')
    split
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
    silent! normal! i
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

function! s:GotoComment(reverse) abort
  let l:flags = 'W'
  if a:reverse | let l:flags .= 'b' | endif
  let l:pattern = '\V' . substitute(&commentstring, '%s', '\\.\\*', '')
  call search(l:pattern, l:flags)
endfunction

function! s:GotoLongLine(reverse) abort
  if &textwidth ==# 0 | return | endif
  let l:flags = 'W'
  if a:reverse | let l:flags .= 'b' | endif
  let l:pattern = printf('^.\{%d\}', &textwidth + 1)
  call search(l:pattern, l:flags)
endfunction

function! s:BinarySearch(l, x) abort
  let l:lo = 0
  let l:hi = len(a:l) - 1
  while l:lo <= l:hi
    let l:mid = float2nr(l:lo + (l:hi - l:lo) / 2)
    let l:val = a:l[l:mid]
    if l:val ==# a:x
      return l:mid
    elseif l:val <# a:x
      let l:lo = l:mid + 1
    else
      let l:hi = l:mid - 1
    endif
  endwhile
  return -1
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
    let l:idx = empty(l:file) ? -1 : s:BinarySearch(l:files, l:file)
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

" Gets a character to add/remove from 'formatoptions'. If mode is -1, the
" value is removed. If mode is 1, the value is added. If mode is 0, the value
" is toggled.
function! s:SetFormatOption(mode) abort
  let l:c = nr2char(getchar())
  let l:lookup = {
        \   -1: '-=',
        \    1: '+=',
        \    0: stridx(&formatoptions, l:c) ==# -1 ? '+=' : '-='
        \ }
  execute 'set formatoptions' . l:lookup[a:mode] . l:c
endfunction

function! s:CreateToggleMaps(char, option) abort
  execute 'nnoremap <silent> [o' . a:char . ' :<c-u>set ' . a:option . '<cr>'
  execute 'nnoremap <silent> ]o' . a:char . ' :<c-u>set no' . a:option . '<cr>'
  execute 'nnoremap <silent> yo' . a:char . ' :<c-u>set ' . a:option . '!<cr>'
endfunction

function! s:CreateVarToggleMaps(char, var) abort
  execute 'nnoremap <silent> [o' . a:char . ' :<c-u>let ' . a:var . ' = 1<cr>'
  execute 'nnoremap <silent> ]o' . a:char . ' :<c-u>let ' . a:var . ' = 0<cr>'
  execute 'nnoremap <silent> yo' . a:char . ' :<c-u>let ' . a:var .
        \ ' = !(exists("' . a:var . '") ? ' . a:var . ' : 1)<cr>'
endfunction

function! s:DefaultOptionValue(option) abort
  " WARN: this could have side effects (e.g., search highlighting may show
  " after checking for the default value of hlsearch).
  let l:tmp = eval('&' . a:option)
  execute 'set ' . a:option . '&'
  let l:result = eval('&' . a:option)
  if type(l:tmp) ==# v:t_number
    " Numeric options and boolean options are handled here (in both cases, the
    " type would be v:t_number).
    execute 'let &' . a:option . '=' . l:tmp
  else
    " String options are handled here.
    execute 'set ' . a:option . '=' . l:tmp
  endif
  return l:result
endfunction

" If mode is -1, the specified option is restored to its default. If mode is
" 1, the specified option is set from user input. If mode is 0, the option is
" restored if it has been changed from its default, or set from user input
" otherwise.
function! s:SetNumericOptionValue(option, mode, default) abort
  if index([-1, 0, 1], a:mode) ==# -1 | throw 'unknown mode' | endif
  let l:mode = a:mode
  if l:mode ==# 0
    let l:is_default = a:default ==# eval('&' . a:option)
    let l:mode = l:is_default ? 1 : -1
  endif
  if l:mode ==# -1
    execute 'set ' . a:option . '=' . a:default
  elseif l:mode ==# 1
    execute 'set ' . a:option . '=' . input('')
  endif
endfunction

function! s:CreateNumericToggleMaps(char, option, ...) abort
  let l:default = a:0 ># 0 ? a:1 : s:DefaultOptionValue(a:option)
  if type(l:default) ==# v:t_string
    let l:default = printf('"%s"', l:default)
  endif
  let l:fn = '<sid>SetNumericOptionValue'
  let l:opt = printf('"%s"', a:option)
  execute 'nnoremap <silent> [o' . a:char .
        \ printf(' :<c-u>call %s(%s, %s, %s)<cr>', l:fn, l:opt, 1, l:default)
  execute 'nnoremap <silent> ]o' . a:char .
        \ printf(' :<c-u>call %s(%s, %s, %s)<cr>', l:fn, l:opt, -1, l:default)
  execute 'nnoremap <silent> yo' . a:char .
        \ printf(' :<c-u>call %s(%s, %s, %s)<cr>', l:fn, l:opt, 0, l:default)
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

" Returns a string indicating option settings (e.g., '[tw=80,sts=8]'),
" intended to be used as part of 'statusline'.
function! OptsStl() abort
  let l:options = []
  if &binary
    call add(l:options, 'bin')
  endif
  if &expandtab
    call add(l:options, 'et')
  endif
  let l:fo = ''
  " Only some format options are considered for statusline display.
  for l:c in ['c', 't']
    if stridx(&formatoptions, l:c) !=# -1
      let l:fo .= l:c
    endif
  endfor
  if !empty(l:fo)
    " Use ':' instead of '=', since the full value of 'formatoptions' is not
    " shown (only a selection of letters).
    call add(l:options, 'fo:' . l:fo)
  endif
  if &list
    call add(l:options, 'list')
  endif
  if &paste
    call add(l:options, 'paste')
  endif
  if &softtabstop !=# 0
    call add(l:options, 'sts=' . &softtabstop)
  endif
  if &shiftwidth !=# 0
    call add(l:options, 'sw=' . &shiftwidth)
  endif
  call add(l:options, 'ts=' . &tabstop)
  if &textwidth !=# 0
    call add(l:options, 'tw=' . &textwidth)
  endif
  if !empty(&virtualedit)
    call add(l:options, 've=' . &virtualedit)
  endif
  if empty(&mouse)
    call add(l:options, 'mouse=')
  endif
  let l:result = ''
  if !empty(l:options)
    let l:result = '[' . join(l:options, ',') . ']'
  endif
  return l:result
endfunction

" Move to a line based on indentation relative to the current indent.
" 'direction' can be -1 or 1 and indicates whether to move backward or
" forward. 'mode' can be -1, 0, 1, and indicates whether the relative indent
" should be less than, the same, or greater than the current indent. 'skip'
" specifies whether empty lines should be skipped.
function! s:MoveRelativeToIndent(direction, mode, skip) abort
  let l:line = line('.')
  let l:indent = indent(l:line)
  let l:last = line('$')
  let l:direction = min([max([a:direction, -1]), 1])
  while 1
    let l:line += l:direction
    if &wrapscan
      if l:line <=# 0
        let l:line = l:last
      elseif l:line >=# l:last + 1
        let l:line = 1
      endif
    endif
    if l:line ==# line('.')
      break
    endif
    if l:line <# 1 || l:line ># l:last
      break
    endif
    let l:indent2 = indent(l:line)
    if a:skip && virtcol([l:line, '$']) - 1 - l:indent2 <=# 0
      continue
    endif
    let l:diff_sign = min([max([l:indent2 - l:indent, -1]), 1])
    let l:match = (a:mode == -1 && l:diff_sign ==# a:mode)
          \ || (a:mode == 1 && l:diff_sign ==# a:mode)
          \ || (a:mode == 0 && l:diff_sign ==# a:mode)
    if l:match
      execute 'normal! ' .. l:line .. 'gg^'
      break
    endif
  endwhile
endfunction

" === Git ===

" Signature:
"   GitCmd(args, [split])
function! s:GitCmd(args, ...) abort
  if !executable('git')
    throw 'git unavailable'
  endif
  if get(a:, 1, 1)
    topleft split
  endif
  enew
  let l:args = a:args
  if l:args == 'diff' || l:args =~# '^diff '
    if g:git_diff_ignore_whitespace
      let l:args = 'diff --ignore-all-space' . l:args[4:]
    endif
  endif
  " 'silent' is used to suppress 'X more lines'.
  silent execute 'read! git ' . l:args
  keepjumps normal! ggdd0
  setlocal ft=git nomodifiable buftype=nofile nobuflisted
  " Hiding the buffer leaks memory, but allows navigating away and back.
  " TODO: Rather, create temporary files with bufhidden=delete and a
  " BufWipeout autocmd that deletes the file.
  setlocal bufhidden=hide
  " When navigating away and then back to a buffer (e.g., <c-^><c-^> to edit
  " alternate file consecutively), buflisted is enabled. Create an autocommand
  " to re-disable.
  autocmd BufEnter <buffer> set nobuflisted
  nnoremap <buffer> <silent> K
        \ :<c-u>call system('git show ' . expand('<cword>'))
        \ <bar> if v:shell_error ==# 0
        \ <bar>   call <sid>GitCmd('show ' . expand('<cword>'), 0)
        \ <bar> endif<cr>
endfunction

function! s:GitCmdFile(args, ...) abort
  if !empty(expand('%'))
    execute call(
          \ 's:GitCmd', [a:args . ' ' . fnameescape(expand('%:p'))] + a:000)
  endif
endfunction

" WARN: Existing scrollbind/cursorbind is turned off and not restored.
function! s:GitBlame() abort
  let l:file = fnameescape(expand('%:p'))
  if empty(l:file)
    return
  endif
  if !executable('git')
    throw 'git unavailable'
  endif
  let l:cmd = 'git blame --porcelain '
  if g:git_blame_ignore_whitespace
    let l:cmd .= '-w '
  endif
  let l:cmd .= l:file
  let l:blame = systemlist(l:cmd)
  if v:shell_error
    echoerr join(l:blame)
    return
  endif
  for l:winnr in range(winnr('$'))
    call setwinvar(l:winnr, '&cursorbind', 0)
    call setwinvar(l:winnr, '&scrollbind', 0)
  endfor
  let l:winid = win_getid()
  let l:restore = [
        \   printf('call setwinvar(%d, "&wrap", %d)', l:winid, &l:wrap),
        \   printf(
        \     'call setwinvar(%d, "&foldenable", %d)', l:winid, &l:foldenable),
        \   printf('call setwinvar(%d, "&cursorbind", %d)', l:winid, 0),
        \   printf('call setwinvar(%d, "&scrollbind", %d)', l:winid, 0),
        \ ]
  keepjumps normal! 0
  setlocal cursorbind scrollbind nowrap nofoldenable
  let l:view = winsaveview()
  let l:curline = line('.')
  call reverse(l:blame)
  " Maps each commit to a dictionary of associated information.
  let l:commits = {}
  let l:items = []
  while len(l:blame) ># 0
    let l:info = {}
    let l:header = remove(l:blame, -1)
    let l:split = split(l:header)
    let l:commit = l:split[0]
    let l:group_lines = str2nr(l:split[3])
    while 1
      let l:line = remove(l:blame, -1)
      if l:line =~# '^\t'
        call add(l:blame, l:line)
        call add(l:blame, l:header)
        if !empty(l:info)
          let l:commits[l:commit] = l:info
        endif
        break
      endif
      let l:idx = stridx(l:line, ' ')
      let l:key = l:line[:l:idx - 1]
      let l:val = l:line[l:idx + 1:]
      let l:info[l:key] = l:val
    endwhile
    for l:idx in range(l:group_lines)
      let l:header = remove(l:blame, -1)
      let l:split = split(l:header)
      let l:line = remove(l:blame, -1)[1:]
      " 'original': "the line number of the line in the original file"
      " 'final': "the line number of the line in the final file"
      let l:item = {
            \   'commit': l:commit,
            \   'original': str2nr(l:split[1]),
            \   'final': str2nr(l:split[2]),
            \   'line': l:line
            \ }
      call add(l:items, l:item)
    endfor
  endwhile
  vsplit
  enew
  let l:width = 0
  let b:commits = []
  let l:groups = [
        \   'Comment',
        \   'Constant',
        \   'Identifier',
        \   'Statement',
        \   'Type',
        \ ]
  " WARN: The same commit doesn't always get the same color. It's changed when
  " keeping the color would cause the same color for two adjacent different
  " commits.
  let l:groupidx = 0
  let l:groupidx_lookup = {}
  for l:idx in range(len(l:items))
    let l:item = l:items[l:idx]
    let l:commit = l:item.commit
    if l:idx ># 0
      let l:prior_commit = l:items[l:idx - 1].commit
      if l:commit !=# l:prior_commit
        if has_key(l:groupidx_lookup, l:commit)
              \ && l:groupidx_lookup[l:commit] !=# l:groupidx_lookup[l:prior_commit]
          let l:groupidx = l:groupidx_lookup[l:commit]
        else
          let l:groupidx = (l:groupidx + 1) % len(l:groups)
        endif
      endif
    endif
    let l:groupidx_lookup[l:commit] = l:groupidx
    call add(b:commits, l:commit)
    let l:info = l:commits[l:commit]
    let l:date = strftime('%Y-%m-%d', l:info['author-time'])
    let l:author = l:info.author
    if strchars(l:author) ># 20
      let l:author = strcharpart(l:author, 0, 19) . '>'
    endif
    let l:hash  = l:commit[:7]
    let l:line = l:hash . ' ' . l:date . ' ' . l:author
    let l:width = max([l:width, len(l:line)])
    call setline(l:item['final'], l:line)
    " prop_add/nvim_buf_add_highlight are used instead of matchaddpos since
    " they attach to the buffer (as opposed to the window), and because
    " using matchaddpos resulted in lag when scrolling large buffers.
    " Each highlight is represented as a list of:
    "   [linenr, start_col, length, group].
    let l:highlights = []
    let l:group = l:groups[l:groupidx]
    if l:commit ==# '0000000000000000000000000000000000000000'
      " Not committed yet.
      call add(l:highlights, [l:item['final'], 1, len(l:line), 'Ignore'])
    else
      call add(l:highlights, [l:item['final'], 1, len(l:hash), l:group])
      call add(l:highlights,
            \ [l:item['final'], len(l:hash) + 2, len(l:date), 'Special'])
    endif
    for [l:linenr, l:start_col, l:len, l:group] in l:highlights
      let l:end_col = l:start_col + l:len
      let l:bufnr = bufnr('%')
      if has('textprop')
        if empty(prop_type_get(l:group, {'bufnr': l:bufnr}))
          let l:props = {
                \   'highlight': l:group,
                \   'bufnr': l:bufnr,
                \ }
          call prop_type_add(l:group, l:props)
        endif
        let l:props = {
              \   'type': l:group,
              \   'end_col': l:end_col + 1,
              \ }
        call prop_add(l:linenr, l:start_col, l:props)
      elseif exists('*nvim_buf_add_highlight')
        call nvim_buf_add_highlight(
              \ l:bufnr,
              \ -1,
              \ l:group,
              \ l:linenr - 1,
              \ l:start_col - 1,
              \ l:end_col - 1)
      endif
    endfor
  endfor
  " Configure the blame window to have the same view as the source.
  call winrestview(l:view)
  setlocal nowrap nomodifiable buftype=nofile nobuflisted bufhidden=wipe
  setlocal nonumber norelativenumber signcolumn=no
  setlocal cursorbind scrollbind nowrap nofoldenable
  setlocal filetype=gitblame
  execute 'vertical resize ' . l:width
  call add(l:restore,
        \ printf('call setwinvar(%d, "&cursorbind", %d)', win_getid(), 0))
  call add(l:restore,
        \ printf('call setwinvar(%d, "&scrollbind", %d)', win_getid(), 0))
  execute 'autocmd BufWinLeave <buffer> ' . join(l:restore, ' | ')
  " The commit hash doesn't have to be retrieved prior to splitting since the
  " window buffer after splitting still has b:commits.
  nnoremap <buffer> <silent> K
        \ :<c-u>if b:commits[line('.') - 1]
        \           !=# '0000000000000000000000000000000000000000'
        \ <bar>   topleft split
        \ <bar>   call <sid>GitCmd('show ' . b:commits[line('.') - 1], 0)
        \ <bar> endif<cr>
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
set shiftwidth=0         " use tabstop value for shiftwidth
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
set laststatus=2        " always show the status line
set autoread            " automatically read files changed outside Vim
" Show tabs as ">", trailing spaces as "-", and non-breaking spaces as "+".
set listchars=tab:>\ ,trail:-,nbsp:+
set sidescroll=1        " scroll horizontally by 1 column with nowrap
set nostartofline       " keep cursor position for various movements commands
" Jump to the previously used window for quickfix jumps.
try | set switchbuf+=uselast | catch | endtry
set tabpagemax=50       " max tab pages for -p command line arg or ':tab all'
" Don't scroll the entire screen for messages (Neovim only as of 2021/1/1)
try | set display+=msgsep | catch | endtry
" Save undo history.
set undofile
if !has('nvim')
  " Save swap files in ~/.vim/swap instead of using the same directory as the
  " edited files. Only do this on Vim, since the defaults on Neovim already
  " use a separate directory. One reason for doing this is so that the ]f
  " mapping, defined below, doesn't infinitely cycle through swap files on
  " Vim.
  let s:vimdir = expand(printf('~/%s', has('win32') ? 'vimfiles' : '.vim'))
  let s:directory = s:vimdir . '/swap//'
  " The try block is used since it may not be possible to call mkdir (e.g.,
  " restricted mode). In that case, the default 'directory', which may include
  " '.', will be used.
  try
    if !isdirectory(s:directory)
      call mkdir(s:directory, 'p')
    endif
    set directory-=.
    execute 'set directory^=' . s:directory
  catch
  endtry
  " Similarly, don't save undo files in the same directory as edited files.
  " Unlike above for swap files, if it's not possible to call mkdir, undo
  " file functionality will essentially be disabled.
  let s:undodir = s:vimdir . '/undo/'
  execute 'set undodir=' . s:undodir
  try
    if !isdirectory(s:undodir)
      call mkdir(s:undodir, 'p')
    endif
  catch
  endtry
endif
" Temporarily highlight search matches (custom setting).
let g:tmphls = 1
" Ignore whitespace for git blame.
let g:git_blame_ignore_whitespace = 1
" Dont't ignore whitespace for git diff.
let g:git_diff_ignore_whitespace = 0
" Customize the status line (takes precedence over 'ruler').
set statusline=%<%f%(\ %y%m%r%{OptsStl()}%)\ %=%-14.(%l,%c%V%)\ %P
" Add a dictionary file for use with <c-x><c-k> in insert mode.
" ('apt install spell' to get dictionary file)
if filereadable('/usr/share/dict/words')
  set dictionary+=/usr/share/dict/words
endif
" Disable smarttab (enabled on Neovim) so that softtabstop works as expected.
set nosmarttab
if !has('nvim') && &term != 'win32'
  " Show a bar cursor in insert mode, an underscore in replace mode, and a
  " block in normal mode. This matches the default behaviour in Neovim.
  let &t_SI = "\e[6 q"  " Insert mode
  let &t_SR = "\e[4 q"  " Replace mode
  let &t_EI = "\e[2 q"  " Normal mode
  " Wrap these with "\eP" and "\e\\" to work in screen.
  if &term ==# 'screen' || &term =~# '^screen[.-]'
    let &t_SI = "\eP" . &t_SI . "\e\\"
    let &t_SR = "\eP" . &t_SR . "\e\\"
    let &t_EI = "\eP" . &t_EI . "\e\\"
  endif
endif
" Disable cursor blinking in GUI.
set guicursor+=a:blinkon0
" Specify Vim's default fillchars, so it's used on Neovim too.
set fillchars=vert:\|,fold:-
try | set fillchars+=eob:~ | catch | endtry
" Enable mousemoveevent on Neovim (for scrollview hovering).
if has('nvim') && exists('&mousemoveevent')
  set mousemoveevent
endif
set notermguicolors

" *********************************************************
" * Color scheme
" *********************************************************

if has('nvim-0.10')
  silent! colorscheme vim
endif

" *********************************************************
" * Commands
" *********************************************************

" Generate tags (requires exuberant/universal ctags).
command! Tags !ctags -R .
" Open a terminal.
command! Terminal call s:Terminal()
command! -nargs=* GitDiff call s:GitCmd('diff <args>')
command! -nargs=* GitLog call s:GitCmd('log <args>')
command! GitBlame call s:GitBlame()

" *********************************************************
" * Autocommands
" *********************************************************

augroup autocommands
  autocmd!
  " Always enter insert mode when entering a terminal window.
  autocmd WinEnter * call s:InsertModeIfTerminal()
  " Turn off search highlighting when the cursor moves (tmphls). Use a
  " try/catch block since match() throws an exception (E383, E866) when the
  " pattern is invalid (e.g., "\@a").
  autocmd CursorMoved *
        \   try
        \ |   if v:hlsearch && get(g:, 'tmphls', 1)
        \         && col('.') - 1 !=# match(getline('.'), @/, col('.') - 1)
        \ |     call feedkeys("\<Plug>(NoHls)")
        \ |   endif
        \ | catch
        \ | endtry
  " For insert mode, only do so when not in paste mode, since mappings aren't
  " expanded in that mode.
  autocmd InsertEnter * if !&paste && v:hlsearch && get(g:, 'tmphls', 1)
        \ | call feedkeys("\<Plug>(NoHls)") | endif

  " Create non-existent directories when saving files.
  autocmd BufWritePre * if !isdirectory(expand('<afile>:p:h'))
        \ | call mkdir(expand('<afile>:p:h'), 'p') | endif

  " Add a workaround for Neovim #23621 (see the first comment, about <silent>
  " used with :, which is applicable here).
  autocmd OptionSet * silent! redrawstatus!

  " === FileType ===
  " FileType autocommands are used in preference to ftplugin/ and
  " after/ftplugin, to 1) keep settings contained to .vimrc and avoid
  " redundancy (a single autocmd can cover multiple filetypes).

  autocmd FileType man,help set number relativenumber
  " Don't highlight current line (quickfix has its own highlighting).
  autocmd FileType qf set nocursorline
  " Break on words for soft wrapping.
  autocmd FileType text set linebreak
augroup END

" *********************************************************
" * Highlights
" *********************************************************

" Specify Vim's default VertSplit highlighting, so it's used on Neovim too.
" Run asynchronously as a workaround for Neovim #30048.
call timer_start(0, {-> execute(
      \ 'highlight VertSplit term=reverse cterm=reverse gui=reverse')})

" *********************************************************
" * Mappings
" *********************************************************

" WARN: The usage of <m-...> mappings may not function properly outside of
" Neovim.

" === Leader mappings (alphabetical) ===
" Turn off highlight.
noremap <silent> <leader><space> :<c-u>nohlsearch<bar>:echo<cr>
" Highlight matches with the word under cursor, but don't move the cursor.
noremap <silent> <leader>*
      \ :<c-u>let @/="\\<<c-r>=expand('<cword>')<cr>\\>"<cr>:set hlsearch<cr>
" Change working directory to directory of current file.
noremap <silent> <leader>. :<c-u>cd %:h<bar>:pwd<cr>
" Change working directory up a directory.
noremap <silent> <leader>.. :<c-u>cd ..<bar>:pwd<cr>
noremap <silent> <leader>/
      \ :<c-u>call feedkeys(":grep -R  ." . repeat(<sid>Left(), 2), 'n')<cr>
noremap <silent> <leader>?
      \ :<c-u>call feedkeys(":vimgrep  **/*" . repeat(<sid>Left(), 5), 'n')<cr>
" Delete current buffer if there are no changes.
noremap <silent> <leader><bs> :<c-u>call <sid>Bdelete(0)<cr>
" Delete current buffer even if there are changes.
noremap <silent> <leader><s-bs> :<c-u>call <sid>Bdelete(1)<cr>
" Edit the alternate file.
noremap <silent> <leader>a <c-^>
" Open current buffer in new tab.
noremap <silent> <leader>b :<c-u>tab split<cr>
" Change text to system clipboard.
noremap <silent> <leader>c "+c
" Change remaining line to system clipboard.
noremap <silent> <leader>C "+C
" Delete text to system clipboard.
noremap <silent> <leader>d "+d
" Delete remaining line to system clipboard.
noremap <silent> <leader>D "+D
" Toggle Netrw's left explorer.
noremap <silent> <leader>e :<c-u>Lexplore<cr>
" Show git blame for current file.
nnoremap <silent> <leader>gb :<c-u>call <sid>GitBlame()<cr>
" Show git diff for current file.
nnoremap <silent> <leader>gd :<c-u>call <sid>GitCmdFile('diff')<cr>
" Show git diff for workspace.
nnoremap <silent> <leader>gD :<c-u>call <sid>GitCmd('diff')<cr>
" Show git log for current file.
nnoremap <silent> <leader>gl :<c-u>call <sid>GitCmdFile('log')<cr>
" Show git log for workspace.
nnoremap <silent> <leader>gL :<c-u>call <sid>GitCmd('log')<cr>
" Navigate to previous tab.
noremap <silent> <leader>h :<c-u>tabprevious<cr>
" Navigate to next tab.
noremap <silent> <leader>l :<c-u>tabnext<cr>
" Open/close location list window.
noremap <silent> <leader>L :<c-u>call <sid>ToggleLocList()<cr>
" Open a new tab.
noremap <silent> <leader>n :<c-u>tabnew<cr>
" Put after from system clipboard.
noremap <silent> <leader>p "+p
" Put before from system clipboard.
noremap <silent> <leader>P "+P
" Quit without checking for changes (like ZQ).
noremap <silent> <leader>q :<c-u>quit!<cr>
" Toggle quickfix window.
noremap <silent> <leader>Q :<c-u>call <sid>ToggleQuickfix()<cr>
" Replace the word under the cursor.
" WARN: The visual mode mapping clobbers the 'z' named register.
nnoremap <leader>r
      \ :%s/\<<c-r>=expand('<cword>')<cr>\>//gc<left><left><left>
vnoremap <leader>r "zy:%s/<c-r>z//gc<left><left><left>
" Also add versions that have an initialized replacement.
nnoremap <leader>R
      \ :%s/\<<c-r>=expand('<cword>')<cr>\>/
      \<c-r>=expand('<cword>')<cr>/gc<left><left><left>
vnoremap <leader>R "zy:%s/<c-r>z/<c-r>z/gc<left><left><left>
" Source the current file.
noremap <leader>s :source %<cr>
" Open a terminal.
noremap <silent> <leader>t :<c-u>Terminal<cr>
" Start window command.
noremap <silent> <leader>v :<c-u>ScrollViewToggle<cr>
noremap <silent> <leader>w <c-w>
" Load vim-win.
noremap <silent> <leader>W :<c-u>Win<cr>
" Delete characters to system clipboard.
noremap <silent> <leader>x "+x
" Delete characters before cursor to system clipboard.
noremap <silent> <leader>X "+X
" Yank from system clipboard.
noremap <silent> <leader>y "+y
" Yank remaining line to system clipboard.
noremap <silent> <leader>Y "+y$
" Write file if modified, and close window (like ZZ).
noremap <silent> <leader>z :<c-u>xit<cr>

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
" Scroll down completion menu.
inoremap <expr> <c-d> pumvisible() ? "\<pagedown>" : "\<c-d>"
" Scroll up completion menu.
inoremap <expr> <c-u> pumvisible() ? "\<pageup>" : "\<c-u>"
" Move to the beginning of the command-line (override).
cnoremap <c-a> <home>
" Enable hjkl movements for insert mode.
" WARN: On some systems, the <c-h> mapping may be problematic since backspace
" emits <c-h>. To resolve this on e.g., QTerminal, change the Emulation
" setting to 'linux' and add mappings so backspace works properly:
"   noremap <c-?> <bs>
"   noremap! <c-?> <bs>
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
inoremap <expr> <silent> <m-k> col('.') ==# col('$') ? "\<del>" : "\<c-o>D"
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
" Use jk to exit insert mode.
inoremap jk <esc>
" Use jk to exit command-line mode.
cnoremap jk <c-c>
" Map <c-space> to omnifunc completion.
inoremap <c-space> <c-x><c-o>
" On Vim, <c-space> inserts <c-@> (<NUL>), confirmed with ctrl-v.
inoremap <c-@> <c-x><c-o>
" Make Y work similarly to C and D.
noremap Y y$
" Delete the word after the cursor in insert mode (reverse of ctrl-w).
inoremap <expr> <c-b> col('.') ==# col('$') ? "\<del>" : "\<space>\<esc>ce"
" Delete the WORD after the cursor in insert mode.
inoremap <expr> <m-b> col('.') ==# col('$') ? "\<del>" : "\<space>\<esc>cE"
" Delete the WORD before the cursor in insert mode.
inoremap <expr> <m-w> col('.') ==# 1 ? "\<bs>" : "\<space>\<esc>cvb"
noremap <m-bs> <del>
noremap! <m-bs> <del>
" Inner line motions
noremap <silent> il :<c-u>normal! ^vg_<cr>
nunmap il
" Line motions (visual mode not defined; just use V)
onoremap <silent> al :<c-u>normal! V<cr>
" Switch ; and : (makes the higher frequency key press more accessible)
noremap ; :
noremap : ;
" Enter an Ex command with '<c-w>;'.
if exists(':tnoremap') ==# 2
  tnoremap <c-w>; <c-w>:
endif
" Switch ` and ' (makes the higher frequency key press more accessible)
noremap ` '
noremap ' `
" Replace ^ with <c-h> since the former is harder to press.
noremap <c-h> ^
" Open command-line window.
noremap q; q:
" Reselect visual selection after shifting
vnoremap < <gv
vnoremap > >gv
" Move visual selection.
vnoremap <c-j> :move '>+1<cr>gv
vnoremap <c-k> :move '<-2<cr>gv
" Move visual selection, with re-formatting.
vnoremap <m-j> :move '>+1<cr>gv=gv
vnoremap <m-k> :move '<-2<cr>gv=gv

" === Neovim terminal mappings ===
" Configure some of Vim's special terminal mappings in Neovim. Unlike Vim,
" some of these mappings switch the mode from Terminal-Job to Terminal-Normal.
if has('nvim')
  " Move focus to the next window.
  tnoremap <c-w><c-w> <c-\><c-n><c-w><c-w>
  tnoremap <c-w>w <c-\><c-n><c-w>w
  " Move focus to the last accessed window.
  tnoremap <c-w><c-p> <c-\><c-n><c-w><c-p>
  tnoremap <c-w>p <c-\><c-n><c-w>p
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
  tnoremap <c-w>; <c-\><c-n>:
  " Paste the specified register.
  tnoremap <expr> <c-w>" '<c-\><c-n>"' . nr2char(getchar()) . 'pi'
  " Send <ctrl-w> to the job in the terminal.
  tnoremap <c-w>. <c-w>
  " Resize the window.
  tnoremap <c-w>= <c-\><c-n><c-w>=i
  tnoremap <c-w>+ <c-\><c-n><c-w>+i
  tnoremap <c-w>- <c-\><c-n><c-w>-i
  tnoremap <c-w>_ <c-\><c-n><c-w>_i
  tnoremap <c-w>< <c-\><c-n><c-w><i
  tnoremap <c-w>> <c-\><c-n><c-w>>i
  tnoremap <c-w>\| <c-\><c-n><c-w>\|i
  " Close the window.
  tnoremap <c-w>c <c-\><c-n><c-w>c
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
noremap <silent> [< <cmd>call <sid>MoveRelativeToIndent(-1, -1, !v:count)<cr>
noremap <silent> ]< <cmd>call <sid>MoveRelativeToIndent(1, -1, !v:count)<cr>
noremap <silent> [= <cmd>call <sid>MoveRelativeToIndent(-1, 0, !v:count)<cr>
noremap <silent> ]= <cmd>call <sid>MoveRelativeToIndent(1, 0, !v:count)<cr>
noremap <silent> [> <cmd>call <sid>MoveRelativeToIndent(-1, 1, !v:count)<cr>
noremap <silent> ]> <cmd>call <sid>MoveRelativeToIndent(1, 1, !v:count)<cr>
noremap <silent> [n :<c-u>call <sid>GotoConflictOrDiff(1)<cr>
noremap <silent> ]n :<c-u>call <sid>GotoConflictOrDiff(0)<cr>
noremap <silent> [, :<c-u>call <sid>GotoComment(1)<cr>
noremap <silent> ], :<c-u>call <sid>GotoComment(0)<cr>
noremap <silent> [t :<c-u>call <sid>GotoLongLine(1)<cr>
noremap <silent> ]t :<c-u>call <sid>GotoLongLine(0)<cr>
noremap <silent> [f :<c-u>call <sid>EditSiblingFile(-v:count1)<cr>
noremap <silent> ]f :<c-u>call <sid>EditSiblingFile(v:count1)<cr>
noremap <silent> [F :<c-u>call <sid>EditSiblingFile('^')<cr>
noremap <silent> ]F :<c-u>call <sid>EditSiblingFile('$')<cr>
noremap <silent> [v :<c-u><c-r>=v:count1<cr>ScrollViewPrev<cr>
noremap <silent> ]v :<c-u><c-r>=v:count1<cr>ScrollViewNext<cr>
noremap <silent> [V :<c-u>ScrollViewFirst<cr>
noremap <silent> ]V :<c-u>ScrollViewLast<cr>

" === Option toggling ===
" (inspired by vim-unimpaired)
call s:CreateNumericToggleMaps('<tab>', 'tabstop', &tabstop)
call s:CreateNumericToggleMaps('<s-tab>', 'softtabstop', 0)
call s:CreateNumericToggleMaps('>', 'shiftwidth', 0)
call s:CreateVarToggleMaps('*', 'g:tmphls')
call s:CreateVarToggleMaps('.', 'g:ctrlp_show_hidden')
nnoremap <silent> [o# :<c-u>set number relativenumber<cr>
nnoremap <silent> ]o# :<c-u>set nonumber norelativenumber<cr>
nnoremap <silent> <expr> yo# &number \|\| &relativenumber
      \ ? ':<c-u>set nonumber norelativenumber<cr>'
      \ : ':<c-u>set number relativenumber<cr>'
nnoremap <silent> [ob :<c-u>set background=light<cr>
nnoremap <silent> ]ob :<c-u>set background=dark<cr>
nnoremap <silent> <expr> yob ':<c-u>set background='
      \ . (&background ==# 'dark' ? 'light' : 'dark') . '<cr>'
call s:CreateToggleMaps('1', 'binary')
call s:CreateToggleMaps('c', 'cursorline')
nnoremap <silent> [od :<c-u>diffthis<cr>
nnoremap <silent> ]od :<c-u>diffoff<cr>
nnoremap <silent> <expr> yod
      \ ':<c-u>' . (&diff ? 'diffoff' : 'diffthis') . '<cr>'
call s:CreateToggleMaps('e', 'expandtab')
nnoremap <silent> [of :<c-u>call <sid>SetFormatOption(1)<cr>
nnoremap <silent> ]of :<c-u>call <sid>SetFormatOption(-1)<cr>
nnoremap <silent> yof :<c-u>call <sid>SetFormatOption(0)<cr>
call s:CreateVarToggleMaps('gb', 'g:git_blame_ignore_whitespace')
call s:CreateVarToggleMaps('gd', 'g:git_diff_ignore_whitespace')
call s:CreateToggleMaps('h', 'hlsearch')
call s:CreateToggleMaps('i', 'ignorecase')
call s:CreateToggleMaps('l', 'list')
nnoremap <silent> [om :<c-u>set mouse=a<cr>
nnoremap <silent> ]om :<c-u>set mouse=<cr>
nnoremap <silent> <expr> yom ':<c-u>set mouse='
      \ . (empty(&mouse) ? 'a' : '') . '<cr>'
call s:CreateToggleMaps('n', 'number')
call s:CreateToggleMaps('p', 'paste')
call s:CreateToggleMaps('r', 'relativenumber')
call s:CreateToggleMaps('s', 'spell')
call s:CreateNumericToggleMaps('t', 'textwidth')
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
call s:CreateNumericToggleMaps('<bar>', 'colorcolumn')

" *********************************************************
" * Menus
" *********************************************************

" Can't use the existing 'Buffers' menu, since it is deleted/recreated from
" code in menu.vim.
noremenu <silent> B&uffer.&Delete\ (keep\ window)<tab><leader><bs>
      \ :<c-u>call <sid>Bdelete(0)<cr>
noremenu <silent> B&uffer.&Force\ Delete\ (keep\ window)<tab><leader><s-bs>
      \ :<c-u>call <sid>Bdelete(1)<cr>

" === Buffer Modification Functionality ===
noremenu <silent> &Tools.-sep3- <nop>
noremenu <silent> &Tools.Replace\ Word<tab><leader>r
      \ :<c-u>call feedkeys('<leader>r', 'm')<cr>
noremenu <silent> &Tools.Replace\ Word\ (initialized)<tab><leader>R
      \ :<c-u>call feedkeys('<leader>R', 'm')<cr>
noremenu <silent> &Tools.-sep4- <nop>
" WARN: The selection movement menu entries are not functional, but rather
" serve as reminders.
noremenu <silent> &Tools.Move\ Selection\ Down<tab><c-j> <nop>
noremenu <silent> &Tools.Move\ Selection\ Up<tab><c-k> <nop>
noremenu <silent> &Tools.Move\ Selection\ Down\ (format)<tab><m-j> <nop>
noremenu <silent> &Tools.Move\ Selection\ Up\ (format)<tab><m-k> <nop>

" === Git ===
noremenu <silent> &Tools.-sep4- <nop>
noremenu <silent> &Tools.Git\ Blame<tab><leader>gb :<c-u>GitBlame<cr>
noremenu <silent> &Tools.Git\ Diff\ <curfile><tab><leader>gd
      \ :<c-u>call <sid>GitCmdFile('diff')<cr>
noremenu <silent> &Tools.Git\ Diff<tab><leader>gD :<c-u>GitDiff<cr>
noremenu <silent> &Tools.Git\ Log\ <curfile><tab><leader>gl
      \ :<c-u>call <sid>GitCmdFile('log')<cr>
noremenu <silent> &Tools.Git\ Log<tab><leader>gL :<c-u>GitLog<cr>

" === Navigation and Search ===
noremenu <silent> Search\ and\ &Navigation.:&grep\ -R\ <text>\ \.<tab><leader>/
      \ :<c-u>call feedkeys(':grep -R  .' . repeat(<sid>Left(), 2), 'n')<cr>
noremenu <silent> Search\ and\ &Navigation.:&vimgrep\ <text>\ **/*<tab><leader>?
      \ :<c-u>call feedkeys(':vimgrep  **/*' . repeat(<sid>Left(), 5), 'n')<cr>
noremenu <silent> Search\ and\ &Navigation.-sep1- <nop>
menu <silent> Search\ and\ &Navigation.Show\ Matches<tab><leader>* <leader>*
noremenu <silent> Search\ and\ &Navigation.-sep2- <nop>
noremenu <silent> Search\ and\ &Navigation.Previous\ Lower\ Indent<tab>[<
      \ :<c-u>call <sid>MoveRelativeToIndent(-1, -1, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.Next\ Lower\ Indent<tab>]<
      \ :<c-u>call <sid>MoveRelativeToIndent(1, -1, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ Higher\ Indent<tab>[>
      \ :<c-u>call <sid>MoveRelativeToIndent(-1, 1, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.Next\ Higher\ Indent<tab>]>
      \ :<c-u>call <sid>MoveRelativeToIndent(1, 1, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ Same\ Indent<tab>[=
      \ :<c-u>call <sid>MoveRelativeToIndent(-1, 0, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.Next\ Same\ Indent<tab>]=
      \ :<c-u>call <sid>MoveRelativeToIndent(1, 0, 1)<cr>
noremenu <silent> Search\ and\ &Navigation.-sep3- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ Conflict\ or\ Diff<tab>]n
      \ :<c-u>call <sid>GotoConflictOrDiff(0)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ Conflict\ or\ Diff<tab>[n
      \ :<c-u>call <sid>GotoConflictOrDiff(1)<cr>
noremenu <silent> Search\ and\ &Navigation.-sep4- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ Comment<tab>],
      \ :<c-u>call <sid>GotoComment(0)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ Comment<tab>[,
      \ :<c-u>call <sid>GotoComment(1)<cr>
noremenu <silent> Search\ and\ &Navigation.-sep5- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ Long\ Line<tab>]t
      \ :<c-u>call <sid>GotoLongLine(0)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ Long\ Line<tab>[t
      \ :<c-u>call <sid>GotoLongLine(1)<cr>
noremenu <silent> Search\ and\ &Navigation.-sep6- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ File<tab>]f
      \ :<c-u>call <sid>EditSiblingFile(1)<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ File<tab>[f
      \ :<c-u>call <sid>EditSiblingFile(-1)<cr>
noremenu <silent> Search\ and\ &Navigation.-sep7- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ Mispelled\ Word<tab>]s ]s
noremenu <silent> Search\ and\ &Navigation.Previous\ Mispelled\ Word<tab>[s [s
noremenu <silent> Search\ and\ &Navigation.-sep8- <nop>
noremenu <silent> Search\ and\ &Navigation.Next\ ScrollView\ Sign\ Line<tab>]v
      \ :<c-u>ScrollViewNext<cr>
noremenu <silent> Search\ and\ &Navigation.Previous\ ScrollView\ Sign\ Line<tab>[v
      \ :<c-u>ScrollViewPrev<cr>

" === Options ===
let s:options = [
      \   ['b', 'background'],
      \   ['1', 'binary'],
      \   ['\|', 'colorcolumn'],
      \   ['u', 'cursorcolumn'],
      \   ['c', 'cursorline'],
      \   ['x', 'cursorline/cursorcolumn'],
      \   ['d', 'diff'],
      \   ['e', 'expandtab'],
      \   ['f', 'formatoptions'],
      \   ['fc', 'formatoptions\ (comment\ autowrap)'],
      \   ['ft', 'formatoptions\ (text\ autowrap)'],
      \   ['\.', 'g:ctrlp_show_hidden'],
      \   ['gb', 'g:git_blame_ignore_whitespace'],
      \   ['gd', 'g:git_diff_ignore_whitespace'],
      \   ['*', 'g:tmphls'],
      \   ['h', 'hlsearch'],
      \   ['i', 'ignorecase'],
      \   ['l', 'list'],
      \   ['m', 'mouse'],
      \   ['n', 'number'],
      \   ['#', 'number/relativenumber'],
      \   ['p', 'paste'],
      \   ['r', 'relativenumber'],
      \   ['>', 'shiftwidth'],
      \   ['<s-tab>', 'softtabstop'],
      \   ['s', 'spell'],
      \   ['<tab>', 'tabstop'],
      \   ['t', 'textwidth'],
      \   ['v', 'virtualedit'],
      \   ['w', 'wrap'],
      \ ]
let s:seen_keys = {}  " For confirming no duplicates.
let s:last_option = ''  " For confirming alphabetical order.
for [s:key, s:option] in s:options
  if has_key(s:seen_keys, s:key)
    throw 'duplicate keys in s:options'
  endif
  let s:seen_keys[s:key] = 1
  if s:option <# s:last_option
    throw 'alphabetical ordering not maintained'
  endif
  let s:last_option = s:option
  " feedkeys() is used instead of :normal to avoid the issue described in Vim
  " #9356. The latter requires a complete command, which e.g., is not
  " satisfied when getchar() is used by s:SetFormatOption.
  execute 'noremenu <silent> &Options.Turn\ &On.' . s:option
        \ . '<tab>[o' . s:key . ' :call feedkeys("[o' . s:key . '")<cr>'
  execute 'noremenu <silent> &Options.Turn\ O&ff.' . s:option
        \ . '<tab>]o' . s:key . ' :call feedkeys("]o' . s:key . '")<cr>'
  execute 'noremenu <silent> &Options.&Toggle.' . s:option
        \ . '<tab>yo' . s:key . ' :call feedkeys("yo' . s:key . '")<cr>'
endfor

" *********************************************************
" * Plugins
" *********************************************************

silent! packadd! termdebug
silent! packadd! matchit
runtime ftplugin/man.vim
if !has('nvim') && has('patch-9.1.0375')
  silent! packadd! comment
endif

" === Netrw ===
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_banner = 0
" Add 'nu' and 'rnu' to the default netrw bufsettings. Setting these with a
" ftplugin or after/ftplugin file doesn't work, since the setting is clobbered
" by $VIMRUNTIME/autoload/netrw.vim.
let g:netrw_bufsettings = "noma nomod nowrap ro nobl nu rnu"

" A mapping for Lexplore is configured with your <leader> mappings.

noremenu <silent> &Plugins.-sep1- <nop>
noremenu <silent> &Plugins.:Lexplore<tab><leader>e
      \ :<c-u>Lexplore<cr>

" === CtrlP ===
" Enable CtrlP cross-session caching.
let g:ctrlp_clear_cache_on_exit = 0
" Always use Vim's working directory for CtrlP's working path.
let g:ctrlp_working_path_mode = 0

noremenu <silent> &Plugins.-sep2- <nop>
noremenu <silent> &Plugins.:CtrlP<tab><c-p> :<c-u>CtrlP<cr>
noremenu <silent> &Plugins.:CtrlPBuffer<tab><c-p><c-f> :<c-u>CtrlPBuffer<cr>
noremenu <silent> &Plugins.:CtrlPMRU<tab><c-p><c-f><c-f> :<c-u>CtrlPMRU<cr>

" === nvim-scrollview ===
" A mapping for:ScrollViewToggle is configured with your <leader> mappings.
" Menu items for :ScrollViewPrev, :ScrollViewNext, :ScrollViewFirst, and
" :ScrollViewLast are configured with your paired bracket mappings.

let g:scrollview_excluded_filetypes = ['gitblame']
let g:scrollview_signs_on_startup = ['all']
