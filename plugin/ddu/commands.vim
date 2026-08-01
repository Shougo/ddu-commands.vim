if 'g:loaded_ddu_commands'->exists()
  finish
endif
let g:loaded_ddu_commands = 1

command -nargs=* -range -bar -complete=custom,ddu#commands#complete
      \ Ddu call ddu#commands#call(<q-args>)
