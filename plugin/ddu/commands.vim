if exists('g:loaded_ddu_commands')
  finish
endif
let g:loaded_ddu_commands = 1

command! -nargs=+ -range -bar -complete=customlist,ddu#commands#complete
      \ Ddu call ddu#commands#call(<q-args>)
