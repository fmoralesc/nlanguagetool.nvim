function! nlanguagetool#call(...)
    let fname = expand('%')
    let bufnr = bufnr('%')
    let tmpfile = tempname()
    let call_s = 'languagetool --disablecategories TYPOGRAPHY --json ' . fname . ' > ' . tmpfile
    call jobstart(call_s,  extend({'bufnr' : bufnr, 'tf': tmpfile}, {'on_exit': 'nlanguagetool#handler'}))
endfunction

function! nlanguagetool#handler(job_id, data, event) dict abort
    try
        let j = json_decode(readfile(self.tf))
    catch
	echom "languagetool: couldn't decode data"
	return
    endtry
    call setqflist([])
    for i in j.matches
	let lnum = byte2line(i.offset + 1)
	let col = i.offset - line2byte(lnum) + 2
	echom string([lnum, col, i.length])
	let repl = i.replacements != [] ? '[' . i.replacements[0].value . ']' : ''
	let text = i.message . ' '. repl .' (' . i.rule.description . ')'
	call setqflist([{'bufnr': self.bufnr, 'lnum': lnum, 'col': col,
		    \ 'text': text}], 'a')
	"call matchaddpos('Error', [[lnum, col]])
    endfor
    let nerrs = len(j.matches)
    echom 'languagetool: found '.nerrs.' error'. (len(nerrs) > 1 ? 's' : '').', check :copen'
    call delete(self.tf)
endfunction
