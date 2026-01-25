" Test for ddu#commands module
" set verbose=1

function Test_parse_options_args() abort
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \     #{ name: 'bar', options: {}, params: {} },
        \   ],
        \ },
        \ ddu#commands#_parse_options_args('foo bar')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   input: 'bar',
        \ },
        \ ddu#commands#_parse_options_args('foo -input=bar')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   sourceOptions: #{
        \     foo: #{
        \       path: 'bar',
        \     },
        \   },
        \ },
        \ ddu#commands#_parse_options_args('-source-option-foo-path=bar foo')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: #{ path: 'bar' }, params: {} },
        \   ],
        \ },
        \ ddu#commands#_parse_options_args('foo -source-option-foo-path=bar')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   sourceParams: #{
        \     foo: #{
        \       path: 'bar',
        \     },
        \   },
        \ },
        \ ddu#commands#_parse_options_args('-source-param-foo-path=bar foo')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: #{ path: 'bar' } },
        \   ],
        \ },
        \ ddu#commands#_parse_options_args('foo -source-param-foo-path=bar')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiOptions: #{
        \     foo: #{
        \       foo: 'bar',
        \     },
        \   },
        \ },
        \ ddu#commands#_parse_options_args('foo -ui-option-foo-foo=bar')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiParams: #{
        \     foo: #{
        \       foo: 'bar',
        \     },
        \   },
        \ },
        \ ddu#commands#_parse_options_args('foo -ui-param-foo-foo=bar')
        \ )
  " If omit value, v:true is used
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   resume: v:true,
        \ },
        \ ddu#commands#_parse_options_args('foo -resume')
        \ )
  call assert_equal(
        \ #{
        \   sources: [
        \     #{ name: 'foo', options: {}, params: {} },
        \   ],
        \   uiParams: #{
        \     foo: #{
        \       foo: v:true,
        \     },
        \   },
        \ },
        \ ddu#commands#_parse_options_args('foo -ui-param-foo-foo')
        \ )
endfunction
