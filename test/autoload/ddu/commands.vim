" set verbose=1

const s:suite = themis#suite('parse')
const s:assert = themis#helper('assert')

function! s:suite.parse_options_args() abort
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \     #{ name: 'bar', options: {}, params: {} },
        \   ],
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -input=bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   input: 'bar',
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ '-source-option-path=bar foo'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   sourceOptions: #{
        \     _: #{
        \       path: 'bar',
        \     },
        \   },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -source-option-path=bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: #{ path: 'bar' }, params: {} },
        \   ],
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ '-source-param-path=bar foo'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   sourceParams: #{
        \     _: #{
        \       path: 'bar',
        \     },
        \   },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -source-param-path=bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: #{ path: 'bar' } },
        \   ],
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -ui-option-foo=bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiOptions: #{ _: #{ foo: 'bar' } },
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -ui-param-foo=bar'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiParams: #{ _: #{ foo: 'bar' } },
        \ })

  " If omit value, v:true is used
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -resume'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   resume: v:true,
        \ })
  call s:assert.equals(ddu#commands#_parse_options_args(
        \ 'foo -ui-param-foo'),
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiParams: #{ _: #{ foo: v:true } },
        \ })
endfunction
