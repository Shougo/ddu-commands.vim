" set verbose=1

let s:suite = themis#suite('parse')
let s:assert = themis#helper('assert')

function! s:suite.parse_options_args() abort
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo bar'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': {}},
        \     {'name': 'bar', 'options': {}, 'params': {}},
        \   ],
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -input=bar'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': {}},
        \   ],
        \   'input': 'bar',
        \ })
endfunction
