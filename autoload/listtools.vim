

"''''''''''''''''''''     function! s:check_list_range(n)
" Checks if the given argument is a valid list indice.
function! s:check_list_range(n)
	if type(a:n) != v:t_number
		echoerr "List number expected"
	elseif a:n < 0 || a:n >= len(g:listtools_lists)
		echoerr "List indice outside of range"
	else
		return 1
	endif
	return 0
endf


"''''''''''''''''''''     function! listtools#get_list_nr(arg)
" Returns a list number by parsing the given string (or number) argument.
" If a:arg = '%', returns the current list number.
" If a:arg = '$', returns the last list number.
" If a:arg < 0, make a reverse count from the last list.
" If a:arg is a number or a number inside a string, returns this number unless 
"    it's not a valid list number (outside of bounds).
function! listtools#get_list_nr(arg)
	if type(a:arg) == v:t_number
		let l:nr = a:arg
	elseif type(a:arg) == v:t_string
		if     a:arg == '%' | return g:listtools_cur_list_nr
		elseif a:arg == '$' | return len(g:listtools_lists)-1
		elseif a:arg == '0' | return 0
		elseif match(a:arg, '^-\?\d\+$') != -1
			let l:nr = str2nr(a:arg)
			if l:nr < 0 | let l:nr = len(g:listtools_lists) + l:nr | endif
		else | return -1
		endif
	else | return -1
	endif
	if !s:check_list_range(l:nr) | return -1 | endif
	return l:nr
endf


"''''''''''''''''''''     function! s:parse_list_range(list_pat)
" Parses a list range expression and returns a new list with the matching list indices.
" If a:list_pat is a number within a valid range, returns [ a:list_pat ].
" Expression examples:
"  '0 1 3'  -->  [0, 1, 3]
"  '%'      -->  [2]  if the current list is 2
"  ''       -->  [2]  if the current list is 2
"  '*'      -->  [0, 1, 2, 3]  if there is 4 lists actually defined
function! s:parse_list_range(list_pat)
	if type(a:list_pat) == v:t_number
		if !s:check_list_range(a:list_pat) | return [] | endif
		return [ a:list_pat ]
	elseif type(a:list_pat) == v:t_list
		for l:nr in a:list_pat
			if !s:check_list_range(l:nr) | return [] | endif
		endfor
		return a:list_pat
	endif

	let l:pat_parts = split(a:list_pat, '[, ]')
	if empty(l:pat_parts) | return [ g:listtools_cur_list_nr ] | endif

	let l:ret = []

	for l:part in l:pat_parts
		if l:part == '*' | return range(len(g:listtools_lists))
		else
			let l:nr = listtools#get_list_nr(l:part)
			if l:nr != -1
				call add(l:ret, l:nr)
			else
				echoerr printf("listtools: Invalid list position: %s", l:part)
				return []
			endif
		endif
	endfor

	return l:ret
endf


"''''''''''''''''''''     function! s:get_list_loop_info(arg_list)
" Used to get common infos for functions that expect a list pattern and a
" verbose flag as optionnal arguments.
" Returns a list containing:
"   - the list of list indices to deal with
"   - the verbosity to apply
"   - a string shortcut which contains list indices separated by commas
function! s:get_list_loop_info(arg_list)
	let l:list_pat = len(a:arg_list) > 0 ? a:arg_list[0] : g:listtools_cur_list_nr
	let l:list_indices = s:parse_list_range(l:list_pat)
	let l:verb = len(a:arg_list) > 1 && a:arg_list[1]
	let l:list_str = l:verb ? join(l:list_indices, ', ') : ''
	return [ l:list_indices, len(l:list_indices), l:verb, l:list_str ]
endf


"''''''''''''''''''''     function! listtools#gen_uniq(list)
" Removes doubloons from the vim list a:list, without disturbing its actual sort.
function! listtools#gen_uniq(list)
	let l:new_list = []
	for l:el in a:list
		if index(l:new_list, l:el) != -1 | continue | endif
		call add(l:new_list, l:el)
	endfor
	return l:new_list
endf


"''''''''''''''''''''     function! listtools#extend(sources)
" Returns a new list which is the extend of all the lists in a:sources.
" a:sources is a list of vim lists.
function! listtools#extend(sources)
	let l:list = []
	for l:source in a:sources
		call extend(l:list, l:source)
	endfor
	return l:list
endf


"''''''''''''''''''''     function! listtools#union(sources)
" Returns a new list which is the union of all the lists in a:sources.
" a:sources is a list of vim lists.
function! listtools#union(sources)
	let l:list = []
	for l:source in a:sources
		call extend(l:list, l:source)
	endfor
	return listtools#gen_uniq(l:list)
endf


"''''''''''''''''''''     function! listtools#intersect(sources)
" Returns a new list which is the intersection of all the lists in a:sources.
" a:sources is a list of vim lists.
function! listtools#intersect(sources)
	if empty(a:sources) | return [] | endif
	let l:list = []
	let l:src0 = a:sources[0]
	for l:item0 in l:src0
		let l:to_keep = 1
		for i in range(1, len(a:sources)-1)
			if index(a:sources[i], l:item0) == -1
				let l:to_keep = 0
				break
			endif
		endfor
		if l:to_keep && index(l:list, l:item0) == -1
			call add(l:list, l:item0)
		endif
	endfor
	return l:list
endf


"''''''''''''''''''''     function! listtools#difference(sources)
" Returns a new list which is the difference between the first source 
" a:sources[0], and each of all the others sources.
" a:sources is a list of vim lists.
function! listtools#difference(sources)
	if empty(a:sources) | return [] | endif
	let l:list = []
	let l:src0 = a:sources[0]
	for l:item0 in l:src0
		let l:to_keep = 1
		for i in range(1, len(a:sources)-1)
			if index(a:sources[i], l:item0) != -1
				let l:to_keep = 0
				break
			endif
		endfor
		if l:to_keep
			call add(l:list, l:item0)
		endif
	endfor
	return l:list
endf


"''''''''''''''''''''     function! listtools#init_lists()
" Removes all existent lists and creates an empty one.
function! listtools#init_lists()
	call listtools#base#init_lists()
endf


"''''''''''''''''''''     function! listtools#initialize()
function! listtools#initialize()
	call listtools#base#initialize()
endf



"'''''''''''''''''''' GETTING LISTS INFOS


"''''''''''''''''''''     function! listtools#get(...)
" Returns the current list, or the n-th list if an argument is given.
function! listtools#get(...)
	let l:list_nr = a:0 > 0 ? a:1 : g:listtools_cur_list_nr
	if !s:check_list_range(l:list_nr) | return | endif
	return g:listtools_lists[l:list_nr]['whole_list']
endf


"''''''''''''''''''''     function! listtools#get_nb_lists()
" Returns the number of lists.
function! listtools#get_nb_lists()
	return len(g:listtools_lists)
endf


"''''''''''''''''''''     function! listtools#get_eaten()
" Returns the current eaten list (without the popped items), or the n-th eaten
" list if an argument is given.
function! listtools#get_eaten(...)
	let l:list_nr = a:0 > 0 ? a:1 : g:listtools_cur_list_nr
	if !s:check_list_range(l:list_nr) | return | endif
	return g:listtools_lists[l:list_nr]['eaten_list']
endf


"''''''''''''''''''''     function! listtools#cur_nr()
" Returns the indice of the currently selected list.
function! listtools#cur_nr()
	return g:listtools_cur_list_nr
endf


"''''''''''''''''''''     function! listtools#get_all_lists()
" Returns all the lists
function! listtools#get_all_lists()
	return g:listtools_lists
endf


"''''''''''''''''''''     function! listtools#last(...)
" Returns the last popped item.
function! listtools#last(...)
	let l:list_nrs = s:parse_list_range(a:0 > 0 ? a:1 : '%')
	if empty(l:list_nrs) | return v:false
	elseif len(l:list_nrs) == 1 | return g:listtools_lists[l:list_nrs[0]]['last']
	else | return map(l:list_nrs, "g:listtools_lists[v:val]['last']")
	endif
endf



"'''''''''''''''''''' LISTING LISTS


"''''''''''''''''''''     function! listtools#list_list(list_nr)
" Lists the content of a list. When there is no arg, lists the current list.
" Otherwise, lists the list number a:1.
function! listtools#list_list(...)
	let l:list_nr = a:0 > 0 ? a:1 : g:listtools_cur_list_nr
	let l:list = g:listtools_lists[l:list_nr]

	let l:len_whole = len(l:list['whole_list'])
	let l:len_eaten = len(l:list['eaten_list'])
	let l:pos_eaten = l:len_whole - l:len_eaten

	exe 'echohl' (l:list_nr == g:listtools_cur_list_nr ? 'ListtoolsCurrentList' : 'ListtoolsNormal')

	if l:len_whole == 0
		echo printf("List %s is void", l:list_nr)
	else
		let l:details = printf('%i item#S', l:len_eaten)
		if l:len_eaten != l:len_whole | let l:details .= ' / '.l:len_whole | endif
		echo s:conjug(printf("List %s (%s) : ", l:list_nr, l:details))

		let [ l:first, l:sep ] = s:max_width(l:list['whole_list']) > 20 ? [ 0, "\n   |" ] : [ 1, ", " ]
		let j = 0

		for l:item in l:list['whole_list']
			echohl ListtoolsComment

			if l:first | let l:first = 0
			else | echon l:sep | endif

			if j < l:pos_eaten | echon l:item
			else
				echohl ListtoolsItem
				echon l:list['eaten_list'][j - l:pos_eaten]
			endif

			let j += 1
		endfor

		echohl None
	endif
endf


"''''''''''''''''''''     function! listtools#list(...)
" Lists all the lists.
function! listtools#list(...)
	for l:nr in s:parse_list_range(a:0 > 0 ? a:1 : '*')
		call listtools#list_list(l:nr)
	endfor
endf



"'''''''''''''''''''' MODIFYING LISTS


"''''''''''''''''''''     function! listtools#add(n, list)
" Adds item(s) to the list a:n.
" a:list must be a list of strings.
function! listtools#add_n(n, list)
	for l:item in a:list
		if type(l:item) != v:t_string | echoerr "Invalid item to add" | return | endif
	endfor
	call extend(g:listtools_lists[a:n]['eaten_list'], a:list)
	call extend(g:listtools_lists[a:n]['whole_list'], a:list)
endf


"''''''''''''''''''''     function! listtools#add(expr, ...)
" Adds item(s) to some lists.
" a:expr can be either a string or a list of strings.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#add(expr, ...)
	let l:expr_list = type(a:expr) != v:t_list ? [ a:expr ] : a:expr

	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	for l:nr in l:list_indices
		call listtools#add_n(l:nr, l:expr_list)
	endfor
	if l:verb
		let l:expr_str = join(map(deepcopy(l:expr_list), "string(v:val)"), ', ')
		let l:msg = printf("Added %s to list#S %s", l:expr_str, l:list_str)
		call listtools#echo_conjug(l:msg, l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#add_cword(...)
" Adds the word under the cursor to the current list.
" Optionnal arg:
"    - 1st arg: if =1, displays an info message. Defaults to 0.
function! listtools#add_cword(...)
	let l:verb = a:0 > 0 && a:1
	call listtools#add(expand('<cword>'), '%', l:verb)
endf


"''''''''''''''''''''     function! listtools#add_selection(...)
" Adds the currently selected text to the current list.
" Optionnal arg:
"    - 1st arg: if =1, displays an info message. Defaults to 0.
function! listtools#add_selection(...)
	let l:old_reg = @"
	let l:verb = a:0 > 0 && a:1

	normal gvy
	call listtools#add(@", '%', l:verb)

	let @" = l:old_reg
endf


"''''''''''''''''''''     function! s:add_motion(type, ...)
" Used for adding text given a vim motion.
" Optionnal arg:
"    - 1st arg: if =1, displays an info message. Defaults to 0.
function! s:add_motion(type, ...)
	let sel_save = &selection
	let &selection = "inclusive"
	let reg_save = @@

	let l:com = a:type=='line' ? "'[V']y" : "`[v`]y"
	silent exe 'normal!' l:com

	let l:verb = a:0 > 0 && a:1
	call listtools#add(@@, '%', l:verb)

	let &selection = sel_save
	let @@ = reg_save
endf

"''''''''''''''''''''     function! listtools#add_motion(type)
" Used for adding text given a vim motion.
" Displays an info message.
function! listtools#add_motion(type)
	call s:add_motion(a:type, 1)
endf

"''''''''''''''''''''     function! listtools#add_motion_quiet(type)
" Used for adding text given a vim motion, quiet version.
function! listtools#add_motion_quiet(type)
	call s:add_motion(a:type, 0)
endf


"''''''''''''''''''''     function! listtools#reset_n(n)
" Resets the list a:n to its initial state.
function! listtools#reset_n(n)
	if !s:check_list_range(a:n) | return | endif
	let g:listtools_lists[a:n]['eaten_list'] = copy(g:listtools_lists[a:n]['whole_list'])
	let g:listtools_lists[a:n]['last'] = ''
endf


"''''''''''''''''''''     function! listtools#reset(...)
" Resets some lists to their initial state.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#reset(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	for l:nr in l:list_indices
		call listtools#reset_n(l:nr)
	endfor
	if l:verb
		if l:nb_lists == 1
			let l:nr = l:list_indices[0]
			let l:eaten_str = string(g:listtools_lists[l:nr]['eaten_list'])
			let l:msg = printf("List %i has been initialized to %s", l:nr, l:eaten_str)
		else
			let l:msg = printf("Lists %s have been initialized to their initial state", l:list_str)
		endif
		call listtools#echo(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#empty(n)
" Empties the list a:n.
function! listtools#empty_n(n)
	let g:listtools_lists[a:n] = listtools#base#get_new_list()
	if a:n == g:listtools_cur_list_nr
		let g:listtools_cur_list = g:listtools_lists[a:n]
	endif
endf


"''''''''''''''''''''     function! listtools#empty(...)
" Empties some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#empty(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	for l:nr in l:list_indices
		call listtools#empty_n(l:nr)
	endfor
	if l:verb
		call listtools#echo_conjug(printf("List#S %s has#S been emptied", l:list_str), l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#delete_n(n)
" Deletes the list a:n.
function! listtools#delete_n(n)
	if !s:check_list_range(a:n) | return | endif
	call remove(g:listtools_lists, a:n)

	if empty(g:listtools_lists) " If there is no other list, create at least an empty list:
		call listtools#init_lists()
	elseif g:listtools_cur_list_nr >= a:n
		call listtools#swap_prev()
	endif
endf


"''''''''''''''''''''     function! listtools#delete(...)
" Deletes some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#delete(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	" Reverse sort items so that delete_n() doesn't invalidate the next indices:
	call reverse(sort(l:list_indices, 'n'))

	for l:nr in l:list_indices
		call listtools#delete_n(l:nr)
	endfor
	if l:verb
		call listtools#echo_conjug(printf("List#S %s has#S been deleted", l:list_str), l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#set_n(n, list)
" Sets item(s) for list a:n
" a:list must be a list of strings.
function! listtools#set_n(n, list)
	if !s:check_list_range(a:n) | return | endif
	let g:listtools_lists[a:n]['whole_list'] = copy(a:list)
	call listtools#reset_n(a:n)
endf


"''''''''''''''''''''     function! listtools#set(list, ...)
" Sets item(s) for some lists.
" a:list must be a list of strings.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#set(list, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	for l:nr in l:list_indices
		call listtools#set_n(l:nr, a:list)
	endfor
	if l:verb
		let l:expr_str = join(map(deepcopy(a:list), "string(v:val)"), ', ')
		let l:msg = printf("Set list#S %s to %s", l:list_str, l:expr_str)
		call listtools#echo_conjug(l:msg, l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#unset_n(n, list)
" Removes items listed in a:list from the list a:n.
" Returns the number of deleted items.
function! listtools#unset_n(n, list)
	if !s:check_list_range(a:n) | return 0 | endif
	let l:list = g:listtools_lists[a:n]
	let l:old_len = len(l:list['whole_list'])
	call filter(l:list['whole_list'], "index(a:list, v:val) == -1")
	call listtools#reset_n(a:n)
	return l:old_len - len(l:list['whole_list'])
endf


"''''''''''''''''''''     function! listtools#unset(list, ...)
" Removes items listed in a:list from some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#unset(list, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	for l:nr in l:list_indices
		let l:this_count = listtools#unset_n(l:nr, a:list)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("%i item#S has#S been deleted in %i list#S", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#pop_n(n)
" Pops an item in the list a:n. The initial list is kept saved and
" can be initialized with listtools#reset().
function! listtools#pop_n(n)
	if !s:check_list_range(a:n) | return '' | endif
	if empty(g:listtools_lists[a:n]['eaten_list']) | return '' | endif

	let g:listtools_lists[a:n]['last'] = remove(g:listtools_lists[a:n]['eaten_list'], 0)
	return g:listtools_lists[a:n]['last']
endf


"''''''''''''''''''''     function! listtools#pop(...)
" Pops an item in some lists. The initial lists are kept saved and
" can be initialized with listtools#reset().
function! listtools#pop(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let l:pop_items = []

	for l:nr in l:list_indices
		if !empty(g:listtools_lists[l:nr]['eaten_list'])
			let l:item = listtools#pop_n(l:nr)
			call add(l:pop_items, l:item)
		endif
	endfor
	if l:verb
		if len(l:pop_items) == 0
			call listtools#echo('No item to pop')
		else
			let l:list_msg = s:conjug(printf('list#S %s', l:list_str), l:nb_lists)
			let l:pop_items_str = join(map(copy(l:pop_items), "string(v:val)"), ', ')
			let l:msg = printf("Item#S %s has#S been popped in %s", l:pop_items_str, l:list_msg)
			call listtools#echo_conjug(l:msg, len(l:pop_items))
		endif
	endif

	if l:nb_lists == 1 | return len(l:pop_items)>0 ? l:pop_items[0] : v:false
	else | return l:pop_items
	endif
endf



"'''''''''''''''''''' FILTERING LISTS


"''''''''''''''''''''     function! listtools#uniq_n(n)
" Removes doubloons from the list a:n, without disturbing its actual sort.
function! listtools#uniq_n(n)
	if !s:check_list_range(a:n) | return | endif
	let l:old_len = len(g:listtools_lists[a:n]['whole_list'])
	call listtools#set_n(a:n, listtools#gen_uniq(g:listtools_lists[a:n]['whole_list']))
	return l:old_len - len(g:listtools_lists[a:n]['whole_list'])
endf


"''''''''''''''''''''     function! listtools#uniq(...)
" Removes doubloons from some lists, without disturbing its actual sort.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#uniq(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	for l:nr in l:list_indices
		let l:this_count = listtools#uniq_n(l:nr)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("Doubloons have been deleted (%i item#S has#S been deleted in %i list#S)", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#filter_n(n, filter_expr)
" Filters the list a:n like with filter().
function! listtools#filter_n(n, filter_expr)
	if !s:check_list_range(a:n) | return | endif
	call filter(g:listtools_lists[a:n]['whole_list'], a:filter_expr)
	call listtools#reset_n(a:n)
endf


"''''''''''''''''''''     function! listtools#filter(filter_expr, ...)
" Filters some lists like with filter().
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#filter(filter_expr, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	for l:nr in l:list_indices
		let l:this_count = listtools#filter_n(l:nr, a:filter_expr)
	endfor
	if l:verb
		call listtools#echo_conjug(printf("List#S %s has#S been filtered", l:list_str), l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#map_n(n, map_expr)
" Maps the list a:n like with map().
function! listtools#map_n(n, map_expr)
	if !s:check_list_range(a:n) | return | endif
	call map(g:listtools_lists[a:n]['whole_list'], a:map_expr)
	call listtools#reset_n(a:n)
endf


"''''''''''''''''''''     function! listtools#map(map_expr, ...)
" Maps some lists like with map().
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#map(map_expr, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	for l:nr in l:list_indices
		let l:this_count = listtools#map_n(l:nr, a:map_expr)
	endfor
	if l:verb
		call listtools#echo_conjug(printf("List#S %s has#S been mapped", l:list_str), l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#keepmatch_n(n, regex, negate)
" Keeps only items which match a given regex from the list a:n.
" If a:negate=1, then removes items instead of keeping them.
" Returns the number of deleted items.
function! listtools#keepmatch_n(n, regex, negate)
	if !s:check_list_range(a:n) | return | endif
	let l:list = g:listtools_lists[a:n]
	let l:old_len = len(l:list['whole_list'])
	let l:equal_op = a:negate ? '==' : '!='
	call filter(l:list['whole_list'], 'match(v:val, a:regex) '.l:equal_op.' -1')
	call listtools#reset_n(a:n)
	return l:old_len - len(l:list['whole_list'])
endf


"''''''''''''''''''''     function! listtools#keepmatch(regex, ...)
" Keeps only items which match a given regex for some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#keepmatch(regex, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	for l:nr in l:list_indices
		let l:this_count = listtools#keepmatch_n(l:nr, a:regex, 0)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("%i item#S has#S been deleted in %i list#S", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#unmatch(regex, ...)
" Removes items which match a given regex for some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#unmatch(regex, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	for l:nr in l:list_indices
		let l:this_count = listtools#keepmatch_n(l:nr, a:regex, 1)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("%i item#S has#S been deleted in %i list#S", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf



"'''''''''''''''''''' WORKING WITH SURROUNDINGS


"''''''''''''''''''''     function! listtools#join(glue)
" Joins (not popped) items using the given glue.
function! listtools#join(glue)
	return join(g:listtools_cur_list['eaten_list'], a:glue)
endf


"''''''''''''''''''''     function! listtools#surround_join(before, after, glue)
" Returns the join of (not popped) items of the current list using the given
" glue, and adds some in/out surroundings.
function! listtools#surround_join(before, after, glue)
	let l:list = deepcopy(g:listtools_cur_list['eaten_list'])
	call map(l:list, 'a:before . v:val . a:after')
	return join(l:list, a:glue)
endf


"''''''''''''''''''''     function! listtools#ask_join()
" Asks for a glue and returns the join of (not popped) items of the current list.
function! listtools#ask_join()
	let l:ask = input("Listtools: glue : ")
	let l:glue = eval(printf('"%s"', l:ask))
	return listtools#join(l:glue)
endf


"''''''''''''''''''''     function! listtools#add_surround(n, in, out)
" Adds the given surroundings to each item in the list a:n.
function! listtools#add_surround_n(n, in, out)
	if !s:check_list_range(a:n) | return | endif
	call map(g:listtools_lists[a:n]['eaten_list'], 'a:in . v:val . a:out')
	call map(g:listtools_lists[a:n]['whole_list'], 'a:in . v:val . a:out')
endf


"''''''''''''''''''''     function! listtools#add_surround(in, out, ...)
" Adds the given surroundings to each item in some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#add_surround(in, out, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	for l:nr in l:list_indices
		call listtools#add_surround_n(l:nr, a:in, a:out)
	endfor
	if l:verb
		let l:msg = printf("Surrounds have been added in list#S %s", l:list_str)
		call listtools#echo_conjug(l:msg, l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! listtools#ask_add_surround(...)
" Asks for surroundings, and adds them to each item in some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#ask_add_surround(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)

	let l:in = input('Prefix: ')
	let l:out = input('Suffix: ')

	for l:nr in l:list_indices
		call listtools#add_surround_n(l:nr, l:in, l:out)
	endfor

	if l:verb
		let l:msg = printf("Surrounds have been added in list#S %s", l:list_str)
		call listtools#echo_conjug(l:msg, l:nb_lists)
	endif
endf


"''''''''''''''''''''     function! s:str_del_surround(str, in, out)
" Deletes surroundings in a:str, removing a:in at the beginning and a:out at
" the end.
" Returns a list like this: [ newstring , is_success ]
function! s:str_del_surround(str, in, out)
	let l:new_start = a:in == ' '
		\ ? match(a:str, '\S\|$')
		\ : strpart(a:str, 0, len(a:in)) == a:in ? len(a:in) : 0

	let l:new_end = a:out == ' '
		\ ? match(a:str, '\s*$')
		\ : strpart(a:str, len(a:str) - len(a:out)) == a:out ?
			\ len(a:str) - len(a:out) : len(a:str)

	if l:new_start != 0 || l:new_end != len(a:str)
		return [ strpart(a:str, l:new_start, l:new_end - l:new_start), 1 ]
	else
		return [ a:str, 0 ]
	endif
endf


"''''''''''''''''''''     function! s:list_del_surround(list, in, out)
" Deletes surroundings in-place for each item in a:list.
" Returns the number of modified items.
function! s:list_del_surround(list, in, out)
	let l:nb_modified = 0
	for i in range(len(a:list))
		let [ a:list[i], l:modified ] = s:str_del_surround(a:list[i], a:in, a:out)
		let l:nb_modified += l:modified
	endfor
	return l:nb_modified
endf


"''''''''''''''''''''     function! listtools#del_surround(n, in, out)
" If found, deletes the strings a:in and a:out respectively from the beginning and the
" end of each item in the list a:n.
" Returns the number of modified items.
function! listtools#del_surround_n(n, in, out)
	if !s:check_list_range(a:n) | return 0 | endif
	call s:list_del_surround(g:listtools_lists[a:n]['eaten_list'], a:in, a:out)
	return s:list_del_surround(g:listtools_lists[a:n]['whole_list'], a:in, a:out)
endf


"''''''''''''''''''''     function! listtools#del_surround(in, out, ...)
" If found, deletes the strings a:in and a:out respectively from the beginning and the
" end of each item in some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#del_surround(in, out, ...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	for l:nr in l:list_indices
		let l:this_count = listtools#del_surround_n(l:nr, a:in, a:out)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("%i surround#S has#S been deleted in %i list#S", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#ask_del_surround(...)
" Asks for surroundings to be deleted for each item in some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#ask_del_surround(...)
	let [ l:list_indices, l:nb_lists, l:verb, l:list_str ] = s:get_list_loop_info(a:000)
	let [ l:item_count, l:list_count ] = [ 0, 0 ]

	let l:in = input('Remove prefix: ')
	let l:out = input('Remove suffix: ')

	for l:nr in l:list_indices
		let l:this_count = listtools#del_surround_n(l:nr, l:in, l:out)
		let l:item_count += l:this_count
		if l:this_count != 0 | let l:list_count += 1 | endif
	endfor
	if l:verb
		let l:msg = printf("%i surround#S has#S been deleted in %i list#S", l:item_count, l:list_count)
		call listtools#echo_conjug(l:msg)
	endif
endf



"'''''''''''''''''''' MANAGING LISTS


"''''''''''''''''''''     function! listtools#new(initial_items, ...)
" Creates a new list, initialized with the string list a:initial_items.
" Optionnal arg:
"    - 1st arg: if =1, displays an info message. Defaults to 0.
function! listtools#new(initial_items, ...)
	let g:listtools_cur_list = listtools#base#get_new_list()
	call add(g:listtools_lists, g:listtools_cur_list)
	let g:listtools_cur_list_nr = len(g:listtools_lists) - 1
	call listtools#set(a:initial_items)

	if a:0 > 0 && a:1
		let l:msg = printf("Added new list (%i)", g:listtools_cur_list_nr)
		if !empty(a:initial_items)
			let l:msg .= ': '.string(a:initial_items)
		endif
		call listtools#echo(l:msg)
	endif
endf


"''''''''''''''''''''     function! listtools#swap(n, ...)
" Swaps to another list.
" a:n is the indice of the list to swap.
" Optionnal arg:
"    - 1st arg: if =1, displays an info message. Defaults to 0.
function! listtools#swap(n, ...)
	let l:nr = listtools#get_list_nr(a:n)
	if l:nr == -1 | return | endif

	let l:verb = a:0 > 0 && a:1
	if l:nr != g:listtools_cur_list_nr
		let g:listtools_cur_list_nr = l:nr
		let g:listtools_cur_list = g:listtools_lists[l:nr]
		if l:verb
			call listtools#echo(printf("Swap to list %i", l:nr))
		endif
	elseif l:verb
		call listtools#echo(printf("Already in list %i", l:nr))
	endif
endf


"''''''''''''''''''''     function! s:swap_inc(inc, verb)
function! s:swap_inc(inc, verb)
	let l:len = len(g:listtools_lists)
	let l:new_pos = ((g:listtools_cur_list_nr + a:inc) % l:len + l:len) % l:len
	call listtools#swap(l:new_pos, a:verb)
endf


"''''''''''''''''''''     function! listtools#swap_next(...)
" Selects the next list (cycle enabled).
" Optionnal arg:
"    - 1st arg: give a count: go to the n-th next list (defaults to 1)
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#swap_next(...)
	call s:swap_inc(a:0 > 0 ? a:1 : 1, a:0 > 1 && a:2)
endf


"''''''''''''''''''''     function! listtools#swap_prev(...)
" Selects the previous list (cycle enabled).
" Optionnal arg:
"    - 1st arg: give a count: go to the n-th previous list (defaults to 1)
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#swap_prev(...)
	call s:swap_inc(a:0 > 0 ? -a:1 : -1, a:0 > 1 && a:2)
endf



"'''''''''''''''''''' MATCH FUNCTIONS


"''''''''''''''''''''     function! s:get_all_matches(lines, pat)
" Returns all the unique matches of a given pattern found inside a list of lines.
function! s:get_all_matches(lines, pat)
	let l:matches = []
	for l:expr in a:lines
		let l:index = 0
		while l:index < len(l:expr)
			let [ l:str, l:start, l:end ] = matchstrpos(l:expr, a:pat, l:index)
			if l:start == -1 | break | endif
			let l:empty = empty(l:str)

			if !l:empty && index(l:matches, l:str) == -1
				call add(l:matches, l:str)
			endif

			let l:index = l:end + l:empty
		endw
	endfor
	return l:matches
endf


"''''''''''''''''''''     function! s:get_qmatches(lines, pat)
" Get matches with the help of the qpatterns plugin.
function! s:get_qmatches(lines, pat)
	let l:all_qmatches = []
	for l:line in a:lines
		let l:qmatches = QSearchStr(l:line, a:pat)
		if !empty(l:qmatches)
			call extend(l:all_qmatches, l:qmatches)
		endif
	endfor
	return l:all_qmatches
endf


"''''''''''''''''''''     function! listtools#set_from_match(line1, line2, pat, ...)
" Sets some lists to the list of matches of the given pattern between
" a:line1 and a:line2 (both inclusive).
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#set_from_match(line1, line2, pat, ...)
	let [ l:list_indices, _ , l:verb, _ ] = s:get_list_loop_info(a:000)
	call listtools#set(s:get_all_matches(getline(a:line1, a:line2), a:pat), l:list_indices, l:verb)
endf


"''''''''''''''''''''     function! listtools#add_from_match(line1, line2, pat, ...)
" Adds the matches of the given pattern between a:line1 and a:line2 (both
" inclusive) to some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#add_from_match(line1, line2, pat, ...)
	let [ l:list_indices, _ , l:verb, _ ] = s:get_list_loop_info(a:000)
	call listtools#add(s:get_all_matches(getline(a:line1, a:line2), a:pat), l:list_indices, l:verb)
endf


"''''''''''''''''''''     function! s:check_loaded_qpatterns()
" Checks if qpattern plugin is available.
function! s:check_loaded_qpatterns()
	let l:loaded = exists('g:loaded_qpatterns') && g:loaded_qpatterns
	if !l:loaded
		echoerr "listtools: qpatterns plugin is not available"
	endif
	return l:loaded
endf


"''''''''''''''''''''     function! listtools#set_from_qmatch(line1, line2, pat, ...)
" Note: Requires the plugin qpatterns
" Sets some lists to the list of matches of the given qpattern between a:line1 
" and a:line2 (both inclusive).
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#set_from_qmatch(line1, line2, pat, ...)
	if s:check_loaded_qpatterns()
		let [ l:list_indices, _ , l:verb, _ ] = s:get_list_loop_info(a:000)
		call listtools#set(s:get_qmatches(getline(a:line1, a:line2), a:pat), l:list_indices, l:verb)
	endif
endf


"''''''''''''''''''''     function! listtools#add_from_qmatch(line1, line2, pat, ...)
" Note: Requires the plugin qpatterns
" Adds the matches of the given qpattern between a:line1 and a:line2 (both
" inclusive) to some lists.
" Optionnal args:
"    - 1st arg: a list indice or pattern. Defaults to the current list ('%').
"    - 2nd arg: if =1, displays an info message. Defaults to 0.
function! listtools#add_from_qmatch(line1, line2, pat, ...)
	if s:check_loaded_qpatterns()
		let [ l:list_indices, _ , l:verb, _ ] = s:get_list_loop_info(a:000)
		call listtools#add(s:get_qmatches(getline(a:line1, a:line2), a:pat), l:list_indices, l:verb)
	endif
endf



"'''''''''''''''''''' UTILITY FUNCTIONS


"''''''''''''''''''''     function! s:max_width(list)
" Returns the length of the largest element in a list.
function! s:max_width(list)
	return max(map(copy(a:list), 'len(v:val)'))
endf


"''''''''''''''''''''     function! listtools#echo(msg)
" Displays a message, unless g:listtools_verbose is set to 0.
function! listtools#echo(msg)
	if !exists('g:listtools_verbose') || g:listtools_verbose
		echo 'listtools:' a:msg
	endif
endf


"''''''''''''''''''''     function! s:split_delim(str, delim)
" Splits a string like this example:
" s:split_delim('#hello##world', '#\+')  -->  ['', '#', 'hello', '##', 'world']
function! s:split_delim(str, delim)
	let [ l:ret, l:last_match ] = [ [], ['', 0, 0] ]
	while 1
		let l:match = matchstrpos(a:str, a:delim, l:last_match[2])
		if l:match[1] == -1 | break | endif
		call extend(l:ret, [ strpart(a:str, l:last_match[2], l:match[1]-l:last_match[2]), match[0] ])
		let l:last_match = l:match
	endw
	return add(l:ret, strpart(a:str, l:last_match[2], len(a:str)-l:last_match[2]))
endf


"''''''''''''''''''''     function! s:conjug(msg)
" Make sentence conjugation easier by taking the last found number to give an
" 's' to certain words. The places to conjugate inside a:msg are marked with the tag
" '#S'.
" If an optionnal number parameter is given, this number is used instead of the
" numbers found in the a:msg string.
" The dictionnary s:conjug_list (defined below) let define the conjugation for particular
" words.
" Example:
" s:conjug('0 time#S is#S none, 1 time#S is#S few, 2 time#S is#S better, 100 time#S is#S huge')
"   gives: '0 time is none, 1 time is few, 2 times are better, 100 times are huge'
function! s:conjug(msg, ...)
	"The following words can automatically be conjugued when they are directly
	"followed by '#S', ex: 'was#S':
	let s:conjug_list = { 'is': 'are', 'was': 'were', 'has': 'have' }

	let l:item = '#S'
	if a:0 > 0
		let l:pattern = '\V\w\*'.l:item
		let l:last_number = a:1
	else
		let l:pattern = '\V\d\+\|\w\*'.l:item
		let l:last_number = 0
	endif
	let l:split = s:split_delim(a:msg, l:pattern)

	let l:output = l:split[0]
	for i in range(1, len(l:split)-1, 2)
		if strpart(l:split[i], len(l:split[i])-2) == l:item
			let l:word = strpart(l:split[i], 0, len(l:split[i])-2)
			let l:output .= l:last_number>1 ?
				\ (has_key(s:conjug_list, l:word) ? s:conjug_list[l:word] : l:word.'s') : l:word
		elseif a:0 == 0
			let l:last_number = str2nr(l:split[i])
			let l:output .= l:split[i]
		endif
		let l:output .= l:split[i+1]
	endfor
	return l:output
endf


"''''''''''''''''''''     function! listtools#echo_conjug()
" Echoes a conjugued message.
function! listtools#echo_conjug(msg, ...)
	if a:0 == 0 | call listtools#echo(s:conjug(a:msg))
	else | call listtools#echo(s:conjug(a:msg, a:1))
	endif
endf


