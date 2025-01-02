function ddu#commands#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    " Option names completion.
    const default_options = s:get_default_options()
    let _ = []

    let _ = default_options->copy()->filter(
          \ { _, val -> val->type() == v:t_bool || val->type() == v:t_string })
          \ ->map({ key, val -> '-' .. key
          \        .. (val->type() == v:t_bool ? '' : '=') })
          \ ->values()

    for prefix in ['action', 'column', 'filter', 'kind', 'source', 'ui']
      let _ += default_options[prefix .. 'Options']->copy()
            \ ->filter(
            \ { _, val -> val->type() == v:t_bool || val->type() == v:t_string })
            \ ->map({ key, val -> '-' .. prefix .. '-option-' .. key
            \        .. (val->type() == v:t_bool ? '' : '=') })
            \ ->values()
      let _ += ['-' .. prefix .. '-option-', '-' .. prefix .. '-param-']
    endfor

    " Local names
    let _ += ddu#custom#get_names()->map({ _, val -> '-name=' .. val })
  else
    " Source name completion.
    let _ = s:get_available_sources()
  endif

  return _->sort()->uniq()->join("\n")
endfunction

function ddu#commands#call(args) abort
  call ddu#start(ddu#commands#_parse_options_args(a:args))
endfunction

function ddu#commands#_parse_options_args(cmdline) abort
  const default_options = s:get_default_options()

  const types = [
        \   'ui', 'source', 'filter', 'column', 'action',
        \ ]

  for name in types
    let {name}_options = {}
    let {name}_params = {}
  endfor

  let sources = []
  let [args, options] = s:parse_options(a:cmdline)

  for arg in args
    let matches = arg->matchlist(
          \ '^-\(\w\+\)-\(option\|param\)-\(\w\+\)-\(\w\+\)\%(=\?\(.*\)\)\?')
    if !matches->empty()
      " options/params
      let type = matches[1]
      let option_or_param = matches[2]
      let type_name = matches[3]
      let name = matches[4]

      let a = arg->substitute('^-\w\+-\w\+-', '', '')
      let value = (a =~# '=.*$') ? s:remove_quote_pairs(matches[5]) : v:true

      if type ==# 'source'
            \ && option_or_param ==# 'option'
            \ && name ==# 'columns'
        " Like defx.nvim
        let value = value->split(':')
      endif

      let value = s:convert_option_or_param(
            \ default_options, type, option_or_param, name, value)

      if type ==# 'source' && !sources->empty()
        " For source local
        let dest_option = {type}s[-1][option_or_param .. 's']
      else
        if !has_key({type}_{option_or_param}s, type_name)
          let {type}_{option_or_param}s[type_name] = {}
        endif
        let dest_option = {type}_{option_or_param}s[type_name]
      endif

      let dest_option[name] = value
    elseif arg[0] ==# '-'
      call ddu#util#print_error(printf('option "%s": is invalid.', arg))
    else
      " Add source name.
      let source_name = arg->matchstr('^[^:]*')
      call add(sources, #{ name: source_name, options: {}, params: {} })
    endif
  endfor

  if !sources->empty()
    let options.sources = sources
  endif

  for name in types
    if !{name}_options->empty()
      let options[name .. 'Options'] = {name}_options
    endif
    if !{name}_params->empty()
      let options[name .. 'Params'] = {name}_params
    endif
  endfor

  return options
endfunction
function s:convert_option_or_param(
      \ default_options, dest, option_or_param,
      \ name, value) abort
  const key = a:dest ..
        \ (a:option_or_param ==# 'option' ? 'Options' : 'Params')
  const default = a:default_options->get(key, {})->get(a:name, v:false)
  if default->type() ==# v:t_bool
        \ && type(a:value) ==# v:t_string
        \ && (a:value ==# 'v:true' || a:value ==# 'v:false')
    " Use boolean instead
    let value = a:value ==# 'v:true' ? v:true : v:false
  else
    let value = a:value
  endif

  return value
endfunction
function s:re_unquoted_match(match) abort
  " Don't match a:match if it is located in-between unescaped single or double
  " quotes
  return a:match .. '\v\ze([^"' .. "'" .. '\\]*(\\.|"([^"\\]*\\.)*[^"\\]*"|'
        \ .. "'" .. '([^' .. "'" .. '\\]*\\.)*[^' .. "'" .. '\\]*' .. "'"
        \ .. '))*[^"' .. "'" .. ']*$'
endfunction
function s:remove_quote_pairs(s) abort
  " remove leading/ending quote pairs
  let s = a:s
  if s[0] ==# '"' && s[len(s) - 1] ==# '"'
    let s = s[1: len(s) - 2]
  elseif s[0] ==# "'" && s[len(s) - 1] ==# "'"
    let s = s[1: len(s) - 2]
  else
    let s = a:s->substitute('\\\(.\)', "\\1", 'g')
  endif
  return s
endfunction
function s:parse_options(cmdline) abort
  let args = []
  let options = {}

  const default_options = s:get_default_options()

  " Eval
  const cmdline = (a:cmdline =~# '\\\@<!`.*\\\@<!`') ?
        \ s:eval_cmdline(a:cmdline) : a:cmdline

  for s in cmdline->split(s:re_unquoted_match('\%(\\\@<!\s\)\+'))
    let arg = s->substitute('\\\( \)', '\1', 'g')
    let arg_key = arg->substitute('=\zs.*$', '', '')

    if arg_key[0] ==# '-' && arg_key !~# '-option-\|-param-'
      let name = arg_key->tr('-', '_')->substitute('=$', '', '')[1:]
      let value = (arg_key =~# '=$') ?
            \ s:remove_quote_pairs(arg[arg_key->len() :]) : v:true
      if default_options->get(name, '')->type() == v:t_bool
            \ && type(value) ==# v:t_string
            \ && (value ==# 'v:true' || value ==# 'v:false')
        " Use boolean instead
        let value = value ==# 'v:true' ? v:true : v:false
      endif

      let options[name] = value
    else
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction
function s:eval_cmdline(cmdline) abort
  let cmdline = ''
  let prev_match = 0
  let eval_pos = a:cmdline->match('\\\@<!`.\{-}\\\@<!`')
  while eval_pos >= 0
    if eval_pos - prev_match > 0
      let cmdline .= a:cmdline[prev_match : eval_pos - 1]
    endif
    let prev_match = a:cmdline->matchend(
          \ '\\\@<!`.\{-}\\\@<!`', eval_pos)
    silent! let cmdline .= a:cmdline[eval_pos+1 : prev_match - 2]->eval()

    let eval_pos = a:cmdline->match('\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let cmdline .= a:cmdline[prev_match :]
  endif

  return cmdline
endfunction

function s:get_available_sources() abort
  " NOTE: ddu#custom#get_source_names() is for already loaded sources
  const sources = 'denops/@ddu-sources/*.ts'
        \ ->globpath(&runtimepath, 1, 1)
        \ ->map({ _, val -> fnamemodify(val, ':t:r') })
        \ ->filter({ _, val -> val !=# '' })
        \ + ddu#custom#get_source_names('default')
  const aliases = ddu#custom#get_alias_names('default', 'source')
  return (sources + aliases)->sort()->uniq()
endfunction

function s:get_default_options() abort
  return '*ddu#custom#get_default_options'->exists() ?
        \ ddu#custom#get_default_options() : {}
endfunction
