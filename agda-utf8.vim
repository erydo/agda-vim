" Agda Input Method
"
let s:cpo_save = &cpo
set cpo&vim

if agda#enable_omni
  call agda#omni#enable()
  let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . ' | call agda#omni#disable()'
else
  for [sequence, symbol] in items(g:agda#glyphs)
    execute printf('noremap! <buffer> <LocalLeader>%s %s', sequence, symbol)
  endfor

  " The only mapping that was not prefixed by LocalLeader:
  noremap! <buffer> <C-_> →
endif

let &cpo = s:cpo_save
