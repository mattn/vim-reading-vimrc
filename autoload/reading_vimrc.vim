let s:room = 'vim-jp/reading-vimrc'

function! s:send_message() abort
  let l:lines = getline(1, '$')
  %d _
  setlocal nomodified
  call system('gitter-cli update --stdin --room ' . s:room, l:lines)
endfunction

function! s:close_window() abort
  try
    call job_stop(s:job)
  catch
  endtry

  let l:win = bufwinnr('reading-vimrc:logs')
  if l:win != -1
    if l:win != bufwinnr('%')
      exe l:win 'wincmd w'
    endif
    bw!
  endif
  let l:win = bufwinnr('reading-vimrc:message')
  if l:win != -1
    if l:win != bufwinnr('%')
      exe l:win 'wincmd w'
    endif
    bw!
  endif
endfunction

function! s:on_stdout(ch, msg) abort
  let l:win = bufwinnr('reading-vimrc:logs')
  if l:win == -1
    return
  endif
  if l:win != bufwinnr('%')
    exe l:win 'wincmd w'
  endif
  setlocal modifiable
  call append('$', split(a:msg, "\n"))
  setlocal nomodifiable
  $
  wincmd w
endfunction

function! reading_vimrc#start() abort
  silent new
  silent only!
  silent file `="reading-vimrc:logs"`
  setlocal buftype=nofile bufhidden=hide noswapfile

  augroup ReadingVimrc
    au! BufWipeout <buffer> call s:close_window()
  augroup END

  let l:log = split(system('gitter-cli recent --room ' . s:room), "\n")
  call setline(1, l:log)
  $
  setlocal nomodifiable

  silent botright 3new
  silent file `="reading-vimrc:message"`
  setlocal buftype=acwrite bufhidden=hide noswapfile

  augroup ReadingVimrc
    au! BufWriteCmd <buffer> call s:send_message()
    au! BufWipeout <buffer> call s:close_window()
  augroup END

  let l:args = ['gitter-cli', 'stream', '--room', s:room]
  let l:opts = {
  \  'exit_cb': {job, status->s:close_window()},
  \  'callback': function('s:on_stdout'),
  \}
  let s:job = job_start(l:args, l:opts)
endfunction
