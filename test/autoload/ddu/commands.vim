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
        \   'sourceOptions': { '_': {} },
        \   'sourceParams': { '_': {} },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -input=bar'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': {}},
        \   ],
        \   'input': 'bar',
        \   'sourceOptions': { '_': {} },
        \   'sourceParams': { '_': {} },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ '-source-option-path=bar foo'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': {}},
        \   ],
        \   'sourceOptions': {
        \     '_': {
        \       'path': 'bar',
        \     },
        \   },
        \   'sourceParams': { '_': {} },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -source-option-path=bar'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': { 'path': 'bar' }, 'params': {}},
        \   ],
        \   'sourceOptions': { '_': {} },
        \   'sourceParams': { '_': {} },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ '-source-param-path=bar foo'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': {}},
        \   ],
        \   'sourceOptions': { '_': {} },
        \   'sourceParams': {
        \     '_': {
        \       'path': 'bar',
        \     },
        \   },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -source-param-path=bar'),
        \ {
        \   'sources': [
        \     {'name': 'foo', 'options': {}, 'params': { 'path': 'bar' }},
        \   ],
        \   'sourceOptions': { '_': {} },
        \   'sourceParams': { '_': {} },
        \ })
endfunction
