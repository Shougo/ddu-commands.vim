function! ddu#commands#complete(arglead, cmdline, cursorpos) abort
  let _ = []

  if a:arglead =~# '^-'
    " Option names completion.
    let options = ddu#custom#get_default_options()
    let bool_options = keys(filter(copy(options),
          \ { _, val -> type(val) == v:t_bool }))
    let _ += map(copy(bool_options), { _, val -> '-' . tr(val, '_', '-') })
    let string_options = keys(filter(copy(options),
          \ { _, val -> type(val) == v:t_string }))
    let _ += map(copy(string_options),
          \ { _, val -> '-' . tr(val, '_', '-') . '=' })

    " Add "-no-" option names completion.
    let _ += map(copy(bool_options),
          \ { _, val -> '-no-' . tr(val, '_', '-') })
  else
    " Source name completion.
    let _ += s:get_available_sources()
  endif

  return uniq(sort(filter(_, { _, val -> stridx(val, a:arglead) == 0 })))
endfunction

function! ddu#commands#call(args) abort
  let options = ddu#commands#_parse_options_args(a:args)
  call ddu#start(options)
endfunction

function! ddu#commands#_parse_options_args(cmdline) abort
  let sources = []
  let [args, options] = s:parse_options(a:cmdline)

  for arg in args
    " Add source name.
    let source_name = matchstr(arg, '^[^:]*')
    call add(sources, { 'name': source_name, 'options': {}, 'params': {} })
  endfor

  let options.sources = sources
  return options
endfunction
function! s:re_unquoted_match(match) abort
  " Don't match a:match if it is located in-between unescaped single or double
  " quotes
  return a:match . '\v\ze([^"' . "'" . '\\]*(\\.|"([^"\\]*\\.)*[^"\\]*"|'
        \ . "'" . '([^' . "'" . '\\]*\\.)*[^' . "'" . '\\]*' . "'" . '))*[^"'
        \ . "'" . ']*$'
endfunction
function! s:remove_quote_pairs(s) abort
  " remove leading/ending quote pairs
  let s = a:s
  if s[0] ==# '"' && s[len(s) - 1] ==# '"'
    let s = s[1: len(s) - 2]
  elseif s[0] ==# "'" && s[len(s) - 1] ==# "'"
    let s = s[1: len(s) - 2]
  else
    let s = substitute(a:s, '\\\(.\)', "\\1", 'g')
  endif
  return s
endfunction
function! s:parse_options(cmdline) abort
  let args = []
  let options = {}

  " Eval
  let cmdline = (a:cmdline =~# '\\\@<!`.*\\\@<!`') ?
        \ s:eval_cmdline(a:cmdline) : a:cmdline

  for s in split(cmdline, s:re_unquoted_match('\%(\\\@<!\s\)\+'))
    let arg = substitute(s, '\\\( \)', '\1', 'g')
    let arg_key = substitute(arg, '=\zs.*$', '', '')

    let name = substitute(tr(arg_key, '-', '_'), '=$', '', '')[1:]
    if name =~# '^no_'
      let name = name[3:]
      let value = v:false
    else
      let value = (arg_key =~# '=$') ?
            \ s:remove_quote_pairs(arg[len(arg_key) :]) : v:true
    endif

    if arg_key[0] ==# '-'
      let options[name] = value
    else
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction
function! s:eval_cmdline(cmdline) abort
  let cmdline = ''
  let prev_match = 0
  let eval_pos = match(a:cmdline, '\\\@<!`.\{-}\\\@<!`')
  while eval_pos >= 0
    if eval_pos - prev_match > 0
      let cmdline .= a:cmdline[prev_match : eval_pos - 1]
    endif
    let prev_match = matchend(a:cmdline,
          \ '\\\@<!`.\{-}\\\@<!`', eval_pos)
    let cmdline .= escape(eval(a:cmdline[eval_pos+1 : prev_match - 2]), '\ ')

    let eval_pos = match(a:cmdline, '\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let cmdline .= a:cmdline[prev_match :]
  endif

  return cmdline
endfunction

function! s:get_available_sources() abort
  return filter(map(globpath(&runtimepath, 'denops/@ddu-sources/*.ts', 1, 1),
        \ { _, val -> fnamemodify(val, ':t:r') }), { _, val -> val !=# '' })
endfunction
