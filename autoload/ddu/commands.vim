function ddu#commands#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    " Option names completion.
    let default_options = ddu#custom#get_default_options()
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
  else
    " Source name completion.
    let _ = s:get_available_sources()
  endif

  return _->filter({ _, val -> val->stridx(a:arglead) == 0 })->sort()->uniq()
endfunction

function ddu#commands#call(args) abort
  call ddu#start(ddu#commands#_parse_options_args(a:args))
endfunction

function ddu#commands#_parse_options_args(cmdline) abort
  let sources = []
  let ui_options = {}
  let ui_params = {}
  let source_options = {}
  let source_params = {}
  let [args, options] = s:parse_options(a:cmdline)

  for arg in args
    if arg =~# '^-\w\+-\%(option\|param\)-\w\+'
      " options/params
      let a = arg->substitute('^-\w\+-\w\+-', '', '')
      let name = a->substitute('=.*$', '', '')
      let value = (a =~# '=.*$') ?
          \ s:remove_quote_pairs(a[name->len() + 1 :]) : v:true
      if value ==# 'v:true' || value ==# 'v:false'
        " Use boolean instead
        let value = value ==# 'v:true' ? v:true : v:false
      endif

      let dest = arg->matchstr('^-\zs\w\+\ze-')
      let option_or_param = arg->matchstr('^-\w\+-\zs\%(option\|param\)')

      if dest ==# 'source' && option_or_param ==# 'option'
            \ && name ==# 'columns'
        " Like defx.nvim
        let value = value->split(':')
      endif

      if dest ==# 'ui'
        let ui_{option_or_param}s[name] = value
      elseif dest ==# 'source'
        if sources->empty()
          " For global
          let source_{option_or_param}s[name] = value
        else
          " For source local
          let sources[-1][option_or_param .. 's'][name] = value
        endif
      endif
    elseif arg[0] ==# '-'
      call s:print_error(printf('option "%s": is invalid.', arg))
    else
      " Add source name.
      let source_name = arg->matchstr('^[^:]*')
      call add(sources, #{ name: source_name, options: {}, params: {} })
    endif
  endfor

  if !(sources->empty())
    let options.sources = sources
  endif
  if !(source_options->empty())
    let options.sourceOptions = #{ _: source_options }
  endif
  if !(source_params->empty())
    let options.sourceParams = #{ _: source_params }
  endif
  if !(ui_options->empty())
    let options.uiOptions = #{ _: ui_options }
  endif
  if !(ui_params->empty())
    let options.uiParams = #{ _: ui_params }

    if options->has_key('ui')
      let options.uiParams[options.ui] = ui_params
    endif
  endif

  return options
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

  " Eval
  const cmdline = (a:cmdline =~# '\\\@<!`.*\\\@<!`') ?
        \ s:eval_cmdline(a:cmdline) : a:cmdline

  for s in cmdline->split(s:re_unquoted_match('\%(\\\@<!\s\)\+'))
    let arg = s->substitute('\\\( \)', '\1', 'g')
    let arg_key = arg->substitute('=\zs.*$', '', '')

    let name = arg_key->tr('-', '_')->substitute('=$', '', '')[1:]
    let value = (arg_key =~# '=$') ?
          \ s:remove_quote_pairs(arg[arg_key->len() :]) : v:true
    if value ==# 'v:true' || value ==# 'v:false'
      " Use boolean instead
      let value = value ==# 'v:true' ? v:true : v:false
    endif

    if arg_key[0] ==# '-' && arg_key !~# '-option-\|-param-'
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
        \ + ddu#custom#get_source_names()
  const aliases = ddu#custom#get_alias_names('source')
  return (sources + aliases)->sort()->uniq()
endfunction

function s:print_error(string, name = 'ddu') abort
  echohl Error
  echomsg printf('[%s] %s', a:name,
        \ a:string->type() ==# v:t_string ? a:string : a:string->string())
  echohl None
endfunction
