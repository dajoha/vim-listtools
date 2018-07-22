
let s:specials = {
	\ "\b":'\b', "\e":'\e', "\f":'\f', "\n":'\n',
	\ "\r":'\r', "\t":'\t', "\\":'\\', "\"":'\"',
\}


"''''''''''''''''''''     function! listtools#utils#stringify(source)
" Returns a vim string representation of a given string, which may be used as a vim string
" expression in an `eval()` function, or an `:execute` command when a vim string expression is
" needed.
" When the string is really simple, the returned output will be surrounded by single quotes, which
" may improve performance in some rare cases. Otherwise, when some characters need any escape
" sequence, the output will be surrounded by double quotes.
function! listtools#utils#stringify(source)
	let output = ''
	let string_is_special = v:false

	for i in range(strlen(a:source))
		let char = a:source[i]
		let ascii = char2nr(char)

		let char_is_special = v:false
		for [key, str] in items(s:specials)
			if char == key
				let output .= str
				let char_is_special = v:true
				let string_is_special = v:true
				break
			endif
		endfor

		if !char_is_special
			if ascii < 32
				let output .= printf('\x%02x', ascii)
				let string_is_special = v:true
			else
				let output .= char
			endif
		endif
	endfor

	return printf(string_is_special ? '"%s"' : "'%s'", output)
endf

