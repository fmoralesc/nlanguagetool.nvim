function! nlanguagetool#call(...)
    let fname = expand('%')
    if !fname
	let fname = tempname()
	silent! execute '%!tee' fnameescape(fname)
    endif
    let bufnr = bufnr('%')
    let tmpfile = tempname()
    let call_s = 'languagetool --disablecategories TYPOGRAPHY --json ' . fname . ' > ' . tmpfile
    call jobstart(call_s,  extend({'bufnr' : bufnr, 'tf': tmpfile}, {'on_exit': 'nlanguagetool#handler'}))
endfunction

function! nlanguagetool#handler(job_id, data, event) dict abort
    try
        let j = json_decode(readfile(self.tf))
    catch
	echom "languagetool: couldn't decode data (".v:exception.")"
	return
    endtry
    call setqflist([])
    for i in j.matches
	let lnum = byte2line(i.offset + 1)
	let col = i.offset - line2byte(lnum) + 2
	let repl = i.replacements != [] ? '[' . i.replacements[0].value . ']' : ''
	let text = i.message . ' '. repl .' (' . i.rule.description . ')'
	call setqflist([{'bufnr': self.bufnr, 'lnum': lnum, 'col': col,
		    \ 'text': text}], 'a')
	"call matchaddpos('Error', [[lnum, col]])
    endfor
    let nerrs = len(j.matches)
    if nerrs == 0
	echom 'languagetool: '.strftime('%T').' found no errors'
    else
	echom 'languagetool: '.strftime('%T').' found '.nerrs.' error'. (nerrs > 1 ? 's' : '').', check :copen'
	if exists('g:worldslice#sigils')
	    let g:worldslice#sigils.languagetool = '%#SLError#'.
			\ nerrs
	    augroup nltool_sigils
		au BufLeave * if &buftype == 'quickfix' && has_key(g:worldslice#sigils, 'languagetool')| 
			    \ call remove(g:worldslice#sigils, 'languagetool') | endif
	    augroup END
	endif
    endif
    call delete(self.tf)
endfunction
