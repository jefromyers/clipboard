let s:unnamed_file = $XDG_RUNTIME_DIR . '/vimclip'


function! s:trim(str)
    return substitute(a:str, '^\s\+\|\s\+$', '', 'g')
endfunction


function! s:can_send_str(str)
    return s:can_send_lines(split(a:str, "\n"))
endfunction


function! s:can_send_lines(lines)
    let minb = get(g:, 'clipboard_min_bytes', 0)
    if !minb
      return 1
    endif

    let excl_ws = get(g:, 'clipboard_exclude_whitespace', 1)
    let bl = 0

    for line in a:lines
      let bl += len(excl_ws ? s:trim(line) : line)
      if bl >= minb
        break
      endif
    endfor

    return bl >= minb
endfunction


function! s:get_data(reg) abort
  if a:reg ==# '*'
    if filereadable(s:unnamed_file)
      let data = readfile(s:unnamed_file, 1)[0]
      return eval(data)
    endif
    return []
  endif

  let data = systemlist('pbpaste')
  return [data, 'v']
endfunction


function! s:set_data(reg, data, rtype) abort
  if type(a:data) == type('')
    let data = [a:data]
  else
    let data = a:data
  endif

  if !s:can_send_lines(data)
    return
  endif

  if a:reg ==# '*'
    call writefile([string([data, a:rtype])], s:unnamed_file, 'b')
    return
  endif

  call system('pbcopy', data)
endfunction


function! provider#clipboard#Call(method, args) abort
  if a:method == 'get'
    return s:get_data(a:args[0])
  elseif a:method == 'set'
    call s:set_data(a:args[2], a:args[0], a:args[1])
  endif
endfunction


function! provider#clipboard#Executable() abort
  return $VIM
endfunction
