" Vim indent file
" Language:   COBOL
" Maintainer: Jorengarenar <dev@joren.ga>
"     (formerly Tim Pope <vimNOSPAM@tpope.info>)

if exists("b:did_indent") | finish | endif
let b:did_indent = 1

setlocal expandtab
setlocal indentexpr=GetCobolIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+=0*,0/,0$,0D,0-,0=01,=~DIVISION,=~SECTION,0=~END,0=~THEN,0=~ELSE,0=~WHEN,*<CR>,.

" Vars (b:/g:)
"   cobol_indent_data_items - for DATA DIVISION: 0=none | (1)=B | 2=cascade
"   cobol_indent_id_paras   - paragraphs in IDENTIFICATION DIVISION
"   cobol_format_free       - FORMAT FREE indentation

" Only define the function once.
if exists("*GetCobolIndent") | finish | endif

let s:skip = 'getline(".") =~ "\\v^.{6}[*/$-]|\"[^\"]*\""'

" Helpers {{{

function! s:get(var, def) abort
  return get(b:, a:var, get(g:, a:var, a:def))
endfunction

function! s:prevgood(lnum) " Find a non-blank line above the current line.
  let lnum = a:lnum
  while lnum > 0
    let lnum = prevnonblank(lnum - 1)
    let line = getline(lnum)
    if line !~ '\v^%(.{' . s:sw_min . '}|\s*)[*/$D-]' " skip over comments etc.
      break
    endif
  endwhile
  return lnum
endfunction

function! s:stripped(lnum)
  return substitute(strpart(getline(a:lnum), 0, 72), '^\s*', '', '')
endfunction

function! s:optionalblock(lnum, ind, blocks, clauses)
  let ind = a:ind

  let clauses   = '\v<%(<NOT\s+)@<!%(NOT\s+)?%('.a:clauses.')'
  let begin     = '\v-@<!<%('.a:blocks.')>'
  let beginfull = begin.'\ze.*%(\n%(s*%([*/$-].*)?\n)*)?\s*%('.clauses.')'
  let end       = '\v<END-%('.a:blocks.')>|%(\.%( |$))@='

  let cline = s:stripped(a:lnum)
  let line  = s:stripped(s:prevgood(a:lnum))

  if cline =~ clauses "&& line !~ '^search\>'
    call cursor(a:lnum, 1)
    let lastclause = searchpair(beginfull, clauses, end, 'bWr', s:skip)
    if getline(lastclause) =~ clauses && s:stripped(lastclause) !~ '^'.begin
      let ind = indent(lastclause)
    elseif lastclause > 0
      let ind = indent(lastclause) + shiftwidth()
    endif
  elseif line =~ clauses && cline !~ end
    let ind += shiftwidth()
  endif

  return ind
endfunction

function! s:set_areas_vars(lnum)
  let s:sw_min = 6
  let s:sw_A   = s:sw_min + 1
  let s:sw_B   = s:sw_A   + 4

  if s:get("cobol_legacy_code", 0) | return | endif

  let lnum = s:prevgood(a:lnum)
  let line = s:stripped(lnum)
  while lnum > 0 && line !~? '>>\s*SOURCE\s\?FORMAT'
    let lnum = s:prevgood(lnum)
    let line = s:stripped(lnum)
  endwhile

  if (line =~? 'FREE') || (s:get("cobol_format_free", 0) && line !~? "FIXED")
    let [ s:sw_min, s:sw_A, s:sw_B ] = [ 0, 0, shiftwidth() ]
  endif
endfunction

" }}}

function! s:indent_data_items(cline, lnum) abort
  if a:cline =~ '\v^(0?1|66|77)>'
    return s:sw_A
  endif

  let x = s:get("cobol_indent_data_items", 1)
  if x == 0 | return s:sw_A | endif

  if a:cline =~ '^78 '
    let line = s:stripped(s:prevgood(a:lnum))
    let lnum = a:lnum

    while line !~ '\v<SECTION>.*($|\.)' && line !~ '\v^\d?\d '
      let lnum -= 1
      let line = s:stripped(s:prevgood(lnum))
    endwhile

    if line =~ '\v<SECTION>.*($|\.)' || line =~ '\v^(66|77|78)'
      return s:sw_A
    endif
  endif

  if x == 1 | return s:sw_B | endif

  let cnum = str2nr(matchstr(a:cline, '\v^\d?\d>'))
  let default = 0
  let lnum    = a:lnum

  while lnum > 0 && lnum > a:lnum - 500 && lnum < a:lnum + 500
    let lnum = s:prevgood(lnum)
    let line = s:stripped(lnum)
    let ind  = indent(lnum)

    if line =~ '\v^\d?\d>'
      let num = str2nr(matchstr(line, '\v^\d?\d>'))
      if cnum == num
        return ind
      elseif cnum > num && default < ind + shiftwidth()
        let default = ind + shiftwidth()
      endif
    elseif ind < s:sw_B && ind >= s:sw_A
      break
    endif
  endwhile

  return default ? default : s:sw_B
endfunction

function! s:indent(lnum) abort
  call s:set_areas_vars(a:lnum)
  let cline = s:stripped(a:lnum)

  " Numbered lines
  if cline =~ '\v^\d{6}%($|[ */$D-])'
    return 0
  endif

  " Directives
  if cline =~ '^>>'
      return s:sw_A
  endif

  " Comments, debugs etc.
  if cline =~ '^[*/$D-]'
    if cline =~ '^. '
      return s:sw_min
    elseif cline =~ '^D'
      let g:foo =
      if index(syntaxcomplete#OmniSyntaxList(), cline[:match(cline, '\k\+\zs')-1], 0, 1) < 0
        return s:sw_min
      endif
    elseif indent(a:lnum) == s:sw_min
      return s:sw_min
    endif
  endif

  " Divisions, sections and file descriptions start in area A
  if cline =~ '\v<%(DIVISION|SECTION)>.*($|\.)' || cline =~ '^[FS]D\>'
    return s:sw_A
  endif

  let lnum = s:prevgood(a:lnum)

  " Hit top of the file, so use area A indent
  if lnum == 0 | return s:sw_A | endif

  let [ line, ind ]  = [ s:stripped(lnum),  indent(lnum) ]

  " Sentence
  let ind -= line =~ '[.]$' ? shiftwidth() : 0

  " Paragraphs
  if cline =~ '\v^(EXIT>)@<!\k+\.' && line =~ '\.\s*$'
    if cline =~ '^\v<(PROGRAM-ID|AUTHOR|INSTALLATION|DATE-WRITTEN|DATE-COMPILED|SECURITY)>'
      return s:get("cobol_indent_id_paras", 0) ? s:sw_B : s:sw_A
    endif
    return s:sw_A
  endif

  " Data items {{{
  if cline =~ '\v^\d?\d>'
    return s:indent_data_items(cline, a:lnum)
  endif

  if line =~ '\v^\d?\d>.*[^.]$'
    return ind + shiftwidth()
  endif
  " }}}

  " EVERYTHING ELSE {{{

  " TODO: does it make sense?
  if line =~ '\v^%(UNTIL)>'
    let ind -= shiftwidth()
  endif

  if line =~ '^PERFORM\>'
    let perfline = substitute(line, '^PERFORM\s*', "", "")
    if perfline =~ '\v^%(\k+\s+TIMES)?\s*$'
      let ind += shiftwidth()
    elseif perfline =~ '\v^%(WITH\s+TEST|VARYING|UNTIL)>.*[^.]$'
      let ind += shiftwidth()
    endif
  elseif line =~ '\v^%(IF|THEN|ELSE|READ|EVALUATE|SEARCH|SELECT|STRING|UNSTRING|COMPUTE|ADD|SUBTRACT|DIVIDE|MULTIPLY|CALL|WRITE|REWRITE|RECEIVE|EXEC)>'
    let ind += shiftwidth()
  endif

  let ind = s:optionalblock(a:lnum, ind, 'ADD|COMPUTE|DIVIDE|MULTIPLY|SUBTRACT', 'ON\s+SIZE\s+ERROR')
  let ind = s:optionalblock(a:lnum, ind, 'STRING|UNSTRING|ACCEPT|DISPLAY|CALL', 'ON\s+OVERFLOW|ON\s+EXCEPTION')

  if cline !~ '^AT\s\+END\>' || line !~ '^SEARCH\>'
    let ind = s:optionalblock(a:lnum, ind, 'DELETE|REWRITE|START|WRITE|READ', 'INVALID\s+KEY|AT\s+END|NO\s+DATA|AT\s+END-OF-PAGE')
  endif

  if cline =~ '^WHEN\>'
    call cursor(a:lnum, 1)
    " Search for READ so that contained AT ENDs are skipped
    let lastclause = searchpair('\v-@<!<%(SEARCH|EVALUATE|READ)>',
          \                     '\v<%(WHEN|AT\s+END)>',
          \                     '\v<END-%(SEARCH|EVALUATE|READ)>',
          \                     'bW',  s:skip)

    if s:stripped(lastclause) =~ '\<\%(WHEN\|AT\s\+END\)\>'
      "&& s:stripped(lastclause) !~ '^\%(SEARCH\|EVALUATE\|READ\)\>'
      let ind = indent(lastclause)
    elseif lastclause > 0
      let ind = indent(lastclause) + shiftwidth()
    endif
  elseif line =~ '^WHEN\>'
    let ind += shiftwidth()
  endif

  if cline =~ '\v^(END)>-@!'
    let ind -= shiftwidth() " On lines with just END, 'guess' a simple shift left
  elseif cline =~ '\v^(END-IF|THEN|ELSE)>-@!'
    call cursor(a:lnum,indent(a:lnum))
    let match = searchpair('\v-@<!<IF>', '\v-@<!%(THEN|ELSE)>','\v-@<!<END-IF>\zs','bnW',s:skip)
    if match > 0
      let ind = indent(match)
    endif
  elseif cline =~ '^END-\a'
    let beginword = matchstr(cline, '\<END-\zs\k\+')

    let suffix = '\v.*%(\n%(%(\s*|.{6})[*/].*\n)*)?\s*'
    let first  = 1
    let follow = ""

    if beginword == 'PERFORM'
      let follow = '<%(UNTIL)>' " TODO: finish this!
    elseif beginword =~ '\v^%(DELETE|REWRITE|START|READ|WRITE)$'
      let follow = '<%(NOT\s+)?(INVALID\s+KEY'
      if beginword =~ '^READ'
        let first = 0
        let follow .= '|AT\s+END|NO\s+DATA'
      elseif beginword =~ '^WRITE'
        let follow .= '|AT\s+END-OF-PAGE'
      endif
      let follow .= ')'
    else
      let first  = 0
      let suffix = ""
    endif

    call cursor(a:lnum, indent(a:lnum))
    let match = searchpair('\v-@<!<'. beginword . suffix . follow .'>',
          \                '',   '\<END-'. beginword .'\>\zs',
          \                'bnW'.(first ? 'r' : ''), s:skip )

    if match > 0
      let ind = indent(match)
    elseif cline =~ '\v^%(END-(READ|EVALUATE|SEARCH|PERFORM))>'
      let ind -= shiftwidth()
    endif
  endif

  " }}}

  return ind < s:sw_B ? s:sw_B : ind

endfunction

function! GetCobolIndent(lnum) abort
  if s:get("cobol_legacy_code", 0)
    return s:indent(a:lnum)
  endif

  let [ ic_old, &l:ic ] = [ &l:ic, 1 ]
  let ind = s:indent(a:lnum)
  let &l:ic = ic_old
  return ind
endfunction
