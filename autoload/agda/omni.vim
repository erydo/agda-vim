" Agda Omni Function
"
" Exposes the configuration variable:
"   agda#omni#trigger_char (default: '\')
" and the functions:
"   agda#omni#enable()
"   agda#omni#disable()
"
let s:cpo_save = &cpo
set cpo&vim

" Packing/unpacking extra completion data.
" The 'user_data' part of a completion function can only be a string, so the
" dict must be stringified/destringified.
" To avoid other plugins handling completions, so we also include a marker to
" differentiate the user data type in the completion events.
" {{
let s:agda_input_user_data_marker = 'agda:'

fun! s:pack(data_dict)
  return s:agda_input_user_data_marker . string(a:data_dict)
endfun

fun! s:unpack(data_str)
  if a:data_str =~# ('^\V' . s:agda_input_user_data_marker)
    return eval(strpart(a:data_str, len(s:agda_input_user_data_marker)))
  endif
endfun
" }}

" Core omni completion functionality
" {{
let g:agda#omni#trigger_char = get(g:, 'agda#omni#trigger_char', '\')

fun! s:start()
  if !pumvisible() && (v:char == g:agda#omni#trigger_char)
    call feedkeys("\<C-X>\<C-O>", 'n')
  endif
endfun

fun! agda#omni#func(findstart, base)
  let l:line = line('.')
  let l:start = col('.') - 1
  let l:text = getline('.')

  " Do not consider the completion char (e.g. backslash) in the completion
  let l:leading_chars = len(g:agda#omni#trigger_char)

  if a:findstart
    while l:start > 0 && l:text[l:start - 1] =~ '\a'
      let l:start -= 1
    endwhile
    return l:start
  else
    let l:seqs = []
    for [sequence, symbol] in items(g:agda#glyphs)
      if sequence =~ '^' . a:base
        call add(l:seqs, sequence)
      endif
    endfor

    let l:res = []
    for sequence in sort(l:seqs)
      let l:symbol = g:agda#glyphs[sequence]
      call add(l:res, {
      \   'word': sequence,
      \   'abbr': sequence,
      \   'menu': symbol,
      \   'user_data': s:pack({
      \     'leading_chars': l:leading_chars,
      \     'symbol': symbol,
      \     'orig_text': l:text,
      \     'line': l:line,
      \     'start': l:start,
      \   }),
      \ })
    endfor

    call complete(l:start + l:leading_chars, l:res)
    return ''
  endif
endfun

fun! s:done()
  let l:ud = s:unpack(get(v:completed_item, 'user_data', ''))
  if empty(l:ud)
    return
  endif

  let l:leading_chars = l:ud.leading_chars
  let l:symbol = l:ud.symbol
  let l:orig_text = l:ud.orig_text
  let l:line = l:ud.line
  let l:start = l:ud.start

  let l:real_start = l:start - l:leading_chars
  let l:text_before_symbol = l:real_start <= 0 ? '' : l:orig_text[:(l:real_start - 1)]
  let l:text_after_symbol = l:orig_text[(l:start):]
  let l:new_text = l:text_before_symbol . l:symbol . l:text_after_symbol

  call setline(l:line, l:new_text)
  call cursor(l:line, l:real_start + len(l:symbol) + 1)
endfun
" }}

" {{
fun! agda#omni#enable()
  if get(b:, 'is_agda_omni_enabled', v:false)
    return
  endif
  let b:is_agda_omni_enabled = v:true

  augroup agda_input
    autocmd!
    autocmd InsertCharPre <buffer> call s:start()
    autocmd CompleteDone <buffer> call s:done()
  augroup END
  setlocal omnifunc=agda#omni#func
  setlocal completeopt+=menu,noinsert
endfun

fun! agda#omni#disable()
  if !get(b:, 'is_agda_omni_enabled', v:false)
    return
  endif
  let b:is_agda_omni_enabled = v:false

  augroup! agda_input
  setlocal omnifunc< completeopt<
endfun
" }}

let &cpo = s:cpo_save
