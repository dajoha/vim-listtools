
"''''''''''''''''''''     function! s:range_and_args(args, bang)
" Used inside functions below to determinate the list range depending of
" if a bang was used with the command.
" Returns a pair with the final range as 1st element, and the remaining
" arguments as 2nd element.
" a:args can be a string (like with <q-args> in commands), or a list of
" strings (like with <f-args> in commands).
function! s:range_and_args(args, bang)
	if empty(a:bang)
		return [ '%', a:args ]
	else
		if type(a:args) == v:t_string
			let [ l:range, _ , l:end ] = matchstrpos(a:args, '\S\+')
			let l:args = matchstr(a:args, '\S.*', l:end)
			return [ l:range, l:args ]
		elseif type(a:args) == v:t_list
			return [ a:args[0], a:args[1:] ]
		endif
	endif
endf


"''''''''''''''''''''     function! listtools#commands#args_range(func_name, args, bang)
" Used by commands to handle the range (for list numbers) depending on the bang.
" Calls a function with this template:
"     func(args, range, verbose)
" a:args can be a string (like with <q-args> in commands), or a list of
" strings (like with <f-args> in commands).
function! listtools#commands#args_range(func_name, args, bang)
	let [ l:range, l:args ] = s:range_and_args(a:args, a:bang)
	exe printf('call %s(%s,%s,1)', a:func_name, string(l:args), string(l:range))
endf


"''''''''''''''''''''     function! listtools#commands#range(func_name, args, bang)
" Used by commands to handle the range (for list numbers) depending on the bang.
" Calls a function with this template (no specific argument):
"    func(range, verbose)
" a:args can be a string (like with <q-args> in commands), or a list of
"    strings (like with <f-args> in commands).
function! listtools#commands#range(func_name, args, bang)
	let [ l:range, _ ] = s:range_and_args(a:args, a:bang)
	exe printf('call %s(%s,1)', a:func_name, string(l:range))
endf


"''''''''''''''''''''     function! listtools#commands#surround(func_name, fargs, mode, bang)
" Used by commands to handle surround functions, with a range for list numbers 
" depending on the bang.
" a:fargs is a list of strings (like with <f-args> in commands).
function! listtools#commands#surround(func_name, fargs, mode, bang)
	let [ l:range, l:args ] = s:range_and_args(a:fargs, a:bang)
	if a:mode == 0
		exe printf("call %s(%s, '', %s, 1)", a:func_name, string(l:args[0]), string(l:range))
	elseif a:mode == 1
		exe printf("call %s('', %s, %s, 1)", a:func_name, string(l:args[0]), string(l:range))
	else
		exe printf("call %s(%s, %s, %s, 1)", a:func_name, string(l:args[0]), string(l:args[1]), string(l:range))
	endif
endf


"''''''''''''''''''''     function! listtools#commands#match()
" Used by commands to handle match functions, with a range depending on the bang.
" a:qargs is a string (like with <q-args> in commands).
function! listtools#commands#match(func_name, line1, line2, qargs, bang)
	let [ l:range, l:args ] = s:range_and_args(a:qargs, a:bang)
	exe printf("call %s(%s, %s, %s, %s, 1)", a:func_name, a:line1, a:line2, string(l:args), string(l:range))
endf


"''''''''''''''''''''     function! listtools#commands#let(qargs, bang)
" Used by the :LTLet command to handle the listtools#let() function, with a range 
" depending on the bang.
" a:qargs is a string (like with <q-args> in commands).
function! listtools#commands#let(qargs, bang)
	let [ l:range, l:args ] = s:range_and_args(a:qargs, a:bang)
	call listtools#set(eval(l:args), l:range, 1)
endf


"''''''''''''''''''''     function! s:get_list_from_arg(arg)
" Used inside listtools#commands#list_oper() below.
" If a:arg is a number, returns the list referenced by this number (indice).
" Otherwise, tries to evaluate a:arg as a vim expression which must evaluate 
" to a vim list, then returns this list.
function! s:get_list_from_arg(arg)
	let l:list_nr = listtools#get_list_nr(a:arg)
	if l:list_nr == -1
		let l:list = eval(a:arg)
		if type(l:list) != v:t_list
			echoerr "listtools: List expected"
			return v:false
		endif
		return l:list
	endif
	return listtools#get(l:list_nr)
endf


"''''''''''''''''''''     function! listtools#commands#list_oper(func_name, oper_name, args, bang)
" Used with list operation commands (union, difference...):
" Runs a given list operation (listtools#extend(), listtools#union()...).
"
" The template function referred by the a:func_name string must have the 
" following prototype:
"    func_name(sources)
" where `sources` is a list of lists.
" This template function must return a new list which is the result of the operation.
"
" a:fargs is a list of strings (like with <f-args> in commands).
function! listtools#commands#list_oper(func_name, oper_name, fargs, bang)
	" Placed here because the number of lists may change:
	let l:initial_nb_lists = listtools#get_nb_lists()

	" If the 1st arg is '+', use a new list for the result:
	if a:fargs[0] == '+'
		call listtools#new([])
		call remove(a:fargs, 0)
	endif

	let l:dest = listtools#get()
	let l:dest_nr = listtools#cur_nr()

	" If there is no bang, adds the current list as the first source:
	let l:sources = a:bang == '!' ? [] : [l:dest]

	" Parse the arguments:
	for l:arg in a:fargs
		if l:arg == '*'
			for l:nr in range(l:initial_nb_lists)
				call add(l:sources, listtools#get(l:nr))
			endfor
		else
			let l:list = s:get_list_from_arg(l:arg)
			if type(l:list) == v:t_bool | return | endif
			call add(l:sources, l:list)
		endif
	endfor

	" Run the operation:
	let l:ret = eval(a:func_name . '(l:sources)')

	if !empty(l:dest)
		call remove(l:dest, 0, len(l:dest) - 1)
	endif
	call extend(l:dest, l:ret)
	call listtools#reset(l:dest_nr)
	call listtools#swap(l:dest_nr)

	call listtools#echo(printf("%s operation has been performed to target list %i", a:oper_name, l:dest_nr))
endf

