
"''''''''''''''''''''     function! s:map(map_command, map, rhs)
" Maps a key
function! s:map(map_command, leader, map, rhs)
	let l:whole_mapping = a:leader . a:map
	execute  a:map_command  '<silent>'  l:whole_mapping  a:rhs
endf


"''''''''''''''''''''     function! s:install_mappings(map_command, leader, mappings)
" Installs a list of mapping definitions given as argument
function! s:install_mappings(map_command, leader, mappings)
	for l:map in a:mappings
		call s:map(a:map_command, a:leader, l:map[0], l:map[1])
	endfor
endf


"''''''''''''''''''''     function! s:list_edit_surround_mappings(open, close)
" Returns a list of mapping definitions which deal about a cetain block pair.
" For example, if a:open='(' and a:close=')', returns the four following
" mapping definitions:
"   <leader>(    (add parenthesis surroundings)
"   <leader>)    (idem)
"   <leader>d(   (remove parenthesis surroundings)
"   <leader>d)   (idem)
function! s:list_edit_surround_mappings(open, close)
	let l:add_cmd = printf(":call listtools#add_surround(%s, %s, '%%', 1)<cr>", string(a:open), string(a:close))
	let l:del_cmd = printf(":call listtools#del_surround(%s, %s, '%%', 1)<cr>", string(a:open), string(a:close))

	let l:mappings = [
		\ [ a:open,      l:add_cmd ],
		\ [ 'd'.a:open,  l:del_cmd ],
	\ ]
	if a:open != a:close
		call extend(l:mappings, [
			\ [ a:close,     l:add_cmd ],
			\ [ 'd'.a:close, l:del_cmd ],
		\ ])
	endif

	return l:mappings
endf


"''''''''''''''''''''     function! s:insert_map(map, vimexpr)
" Returns a mapping definition which will insert the result of the evalution of the string
" a:vimexpr.
function! s:insert_map(map, vimexpr)
	" s:cur_paste_command is set to '<c-r><c-p>', or '<c-r>' depending on what
	" kind (mode) of mappings are currently added:
	return [ a:map, printf('%s=%s<cr>', s:cur_paste_command, a:vimexpr) ]
endf


"''''''''''''''''''''     function! s:insert_join_map(map, glue)
" Returns a mapping definition which will insert the result of list join, with a given
" glue string given as an argument.
function! s:insert_join_map(map, glue)
	let l:vimexpr = printf('listtools#join(%s)', string(a:glue))
	return s:insert_map(a:map, l:vimexpr)
endf


"''''''''''''''''''''     function! s:insert_surround_map(map, prefix, suffix, before, after, glue)
" Returns a mapping definition which will insert the result of list join, with:
"   a:map : the mapping (without leader) to use
"   a:prefix : a prefix for the whole result
"   a:suffix : a suffix for the whole result
"   a:before : a prefix for each element
"   a:after  : a suffix for each element
"   a:glue : the glue string between each element
"
function! s:insert_surround_map(map, prefix, suffix, before, after, glue)
	let l:vimexpr = printf('%s.listtools#surround_join(%s,%s,%s).%s',
		\ string(a:prefix), string(a:before), string(a:after), string(a:glue), string(a:suffix))
	return s:insert_map(a:map, l:vimexpr)
endf


"''''''''''''''''''''     function! s:insert_block_mappings(block_open, block_close, cmd_mode)
" Returns a list of mappings related to a given block pair, such parenthesis,
" brackets...
function! s:insert_block_mappings(block_open, block_close, cmd_mode)
	"''''''''''''''''''''     function! s:get_block_mapping(map, template, vimexpr, open, close)
	function! s:get_block_mapping(map, template, vimexpr, open, close)
		let l:printf_fmt = printf(a:template, a:open, '%s', a:close)
		" Using listtools#utils#stringify() instead of string() permits to use carriage returns
		" inside the template, i.e. multiline insertions:
		let l:full_vimexpr = printf("printf(%s,%s)", listtools#utils#stringify(l:printf_fmt), a:vimexpr)
		return s:insert_map(a:map, l:full_vimexpr)
	endf


	let l:o = a:block_open
	let l:c = a:block_close

	let l:mappings = []

	call extend(l:mappings, [
		\ s:get_block_mapping(l:o.'j', '%s %s %s', "listtools#ask_join()", l:o, l:c),
		\ s:get_block_mapping(l:o.l:o, '%s %s %s', "listtools#join(', ')", l:o, l:c),
		\ s:get_block_mapping(l:o.',', '%s %s %s', "listtools#join(', ')", l:o, l:c),
		\ s:get_block_mapping(l:o.';', '%s %s %s', "listtools#join('; ')", l:o, l:c),
		\ s:insert_surround_map(l:o."'", l:o.' ', ' '.l:c, "'", "'", ', '),
		\ s:insert_surround_map(l:o.'"', l:o.' ', ' '.l:c, '"', '"', ', '),
		\ s:insert_surround_map(l:o.'`', l:o.' ', ' '.l:c, '`', '`', ', '),
	\ ])

	call extend(l:mappings, [
		\ s:get_block_mapping(l:c.'j', '%s%s%s', "listtools#ask_join()", l:o, l:c),
		\ s:get_block_mapping(l:c.l:c, '%s%s%s', "listtools#join(', ')", l:o, l:c),
		\ s:get_block_mapping(l:c.',', '%s%s%s', "listtools#join(', ')", l:o, l:c),
		\ s:get_block_mapping(l:c.';', '%s%s%s', "listtools#join('; ')", l:o, l:c),
		\ s:insert_surround_map(l:c."'", l:o, l:c, "'", "'", ', '),
		\ s:insert_surround_map(l:c.'"', l:o, l:c, '"', '"', ', '),
		\ s:insert_surround_map(l:c.'`', l:o, l:c, '`', '`', ', '),
	\ ])

	" If a:cmd_mode != 1, add multiline insertion mappings:
	if a:cmd_mode != 1
		call extend(l:mappings, [
			\ s:get_block_mapping(l:o.'<cr>' , "%s\n\t%s\n%s\n", 'listtools#join(",\n\t")', l:o, l:c),
			\ s:get_block_mapping(l:c.'<cr>' , "%s\n\t%s\n%s\n", 'listtools#join(",\n\t")', l:o, l:c),
		\ ])
	endif

	return l:mappings
endf



"''''''''''''''''''''     function! listtools#mappings#install_all_mappings()
" Installs all the mappings, with leaders defined from the following
" variables:
"   g:listtools_leader
"   g:listtools_visual_leader (defaults to g:listtools_leader)
"   g:listtools_insert_leader
"   g:listtools_command_leader (defaults to g:listtools_insert_leader)
function! listtools#mappings#install_all_mappings()

	" NORMAL MAPPINGS:

	" Mappings like  <leader>l , <leader>r ...
	let s:normal_plug_mappings = [
            \ ['r', '<Plug>ListtoolsResetCur' ],
            \ ['R', '<Plug>ListtoolsResetAll' ],
            \ ['l', '<Plug>ListtoolsListAll' ],
            \ ['L', '<Plug>ListtoolsListCur' ],
            \ ['p', '<Plug>ListtoolsPop' ],
            \ ['e', '<Plug>ListtoolsEmptyCur' ],
            \ ['E', '<Plug>ListtoolsEmptyAll' ],
            \ ['x', '<Plug>ListtoolsDeleteCur' ],
            \ ['X', '<Plug>ListtoolsDeleteAll' ],
            \ ['w', '<Plug>ListtoolsSwapNext' ],
            \ ['W', '<Plug>ListtoolsSwapPrev' ],
            \ ['n', '<Plug>ListtoolsNewList' ],
            \ ['u', '<Plug>ListtoolsUniqCur' ],
            \ ['U', '<Plug>ListtoolsUniqAll' ],
            \ ['aw', '<Plug>ListtoolsAddCWord' ],
	\ ]


	" Add or remove surrounds:

	let s:normal_mappings = []

	" <nleader>a  (expect a motion in order to add an element)
	call add(s:normal_mappings, [ 'a', ':set opfunc=listtools#add_motion<cr>g@' ])

	" <nleader>s , <nleader>ds : add or remove custom surroundings
	call extend(s:normal_mappings, [
		\ ['s', ':call listtools#ask_add_surround("%", 1)<cr>' ],
		\ ['ds', ':call listtools#ask_del_surround("%", 1)<cr>' ],
	\ ])

	" <nleader>0, <nleader>1, <nleader>2... : swap quickly to the n-th list
	for i in range(10)
		call extend(s:normal_mappings, [
			\ [ string(i), printf(':call listtools#swap(%i, 1)<cr>', i) ],
			\ [ printf('<k%i>', i), printf(':call listtools#swap(%i, 1)<cr>', i) ],
		\ ])
	endfor

	" <nleader>d<space> : trim white spaces
	call add(s:normal_mappings, [ 'd<space>', ":call listtools#del_surround(' ', ' ', '%', 1)<cr>" ])


	" Mappings to add/remove common surroundings in the current list:
	call extend(s:normal_mappings, s:list_edit_surround_mappings("'", "'")) " <nleader>' , <nleader>d'
	call extend(s:normal_mappings, s:list_edit_surround_mappings('"', '"'))
	call extend(s:normal_mappings, s:list_edit_surround_mappings('`', '`'))
	call extend(s:normal_mappings, s:list_edit_surround_mappings('(', ')')) " <nleader>( , <nleader>d( ...
	call extend(s:normal_mappings, s:list_edit_surround_mappings('<', '>'))
	call extend(s:normal_mappings, s:list_edit_surround_mappings('[', ']'))
	call extend(s:normal_mappings, s:list_edit_surround_mappings('{', '}'))


	" VISUAL MAPPINGS:

	" Add the visually selected text as a new element:
	let s:visual_plug_mappings = [
		\ [ 'a', '<Plug>ListtoolsAddSelection' ],
	\ ]


	" INSERT MAPPINGS:

	let s:insert_mappings = []

	" Vim insert command to use to insert text for insert-mode mappings, used
	" by the s:insert_map() function:
	let s:cur_paste_command = '<c-r><c-p>'

	" <ileader><c-x> , <ileader>x ... swap to other lists in insert mode:
	call extend(s:insert_mappings, [
		\ [ '<c-w>', "<c-o>:call listtools#swap_next()<cr>" ],
		\ [ 'w'    , "<c-o>:call listtools#swap_next()<cr>" ],
		\ [ 'W'    , "<c-o>:call listtools#swap_prev()<cr>" ],
	\ ])

	" <ileader>p ,  <ileader>l  : insert next or current element from the
	" list:
	call extend(s:insert_mappings, [
		\ s:insert_map('<c-p>', 'listtools#pop()'),
		\ s:insert_map('p'    , 'listtools#pop()'),
		\ s:insert_map('<c-l>', 'listtools#last()'),
		\ s:insert_map('l'    , 'listtools#last()'),
	\ ])

	" <ileader>j  : insert the current list joined with a custom glue string:
	call extend(s:insert_mappings, [
		\ s:insert_map('<c-j>', 'listtools#ask_join()'),
		\ s:insert_map('j'    , 'listtools#ask_join()'),
	\ ])

	" <ileader>j  : insert the current list joined with a commonly used glue string:
	call extend(s:insert_mappings, [
		\ s:insert_join_map('<space>', ' '),
		\ s:insert_join_map(',', ', '),
		\ s:insert_join_map(';', '; '),
		\ s:insert_map('<cr>', 'listtools#join("\n")'),
	\ ])

	" <ileader>"  , <ileader>'  : insert this kind of join:
	"   "element1", "element2", "element3"
	call extend(s:insert_mappings, [
		\ s:insert_surround_map('"', '', '', '"', '"', ', '),
		\ s:insert_surround_map("'", '', '', "'", "'", ', '),
		\ s:insert_surround_map('`', '', '', '`', '`', ', '),
		\ s:insert_surround_map('<bar>', '\v', '', '<', '>', '<bar>'),
	\ ])

	" <ileader>(,  ,  <ileader>};  ... : many common joins like:
	"  (element1, element2, ...)
	"  {element1; element2, ...}
	call extend(s:insert_mappings, s:insert_block_mappings('(', ')', 0))
	call extend(s:insert_mappings, s:insert_block_mappings('[', ']', 0))
	call extend(s:insert_mappings, s:insert_block_mappings('{', '}', 0))



	" COMMAND MAPPINGS:
	" These mappings are very similar to insert-mode mappings:

	let s:command_mappings = []

	" Vim insert command to use to insert text for command-mode mappings, used
	" by the s:insert_map() function:
	let s:cur_paste_command = '<c-r>'

	call extend(s:command_mappings, [
		\ s:insert_map('<c-p>', 'listtools#pop()'),
		\ s:insert_map('p'    , 'listtools#pop()'),
		\ s:insert_map('<c-l>', "listtools#last()"),
		\ s:insert_map('l'    , "listtools#last()"),
		\
		\ s:insert_map('<c-j>', "listtools#ask_join()"),
		\ s:insert_map('j'    , "listtools#ask_join()"),
		\
		\ s:insert_join_map('<space>', ' '),
		\ s:insert_join_map(',', ', '),
		\ s:insert_join_map(';', '; '),
		\
		\ s:insert_surround_map("'", '', '', "'", "'", ', '),
		\ s:insert_surround_map('"', '', '', '"', '"', ', '),
		\ s:insert_surround_map('`', '', '', '`', '`', ', '),
		\ s:insert_surround_map("<bar>", '\v', ''  , "<", ">", "<bar>"),
	\ ])

	call extend(s:command_mappings, s:insert_block_mappings('(', ')', 1))
	call extend(s:command_mappings, s:insert_block_mappings('[', ']', 1))
	call extend(s:command_mappings, s:insert_block_mappings('{', '}', 1))


	" Install all the mappings:
	call s:install_mappings('noremap', g:listtools_leader, s:normal_mappings)
	call s:install_mappings('inoremap', g:listtools_insert_leader, s:insert_mappings)
	call s:install_mappings('cnoremap', g:listtools_command_leader, s:command_mappings)
	call s:install_mappings('nmap', g:listtools_leader, s:normal_plug_mappings)
	call s:install_mappings('vmap', g:listtools_visual_leader, s:visual_plug_mappings)
endf


"''''''''''''''''''''     function! s:show_mapping(leader, map, lhs_align)
function! s:show_mapping(leader, map, lhs_align)
	let [l:lhs, l:rhs] = a:map
	let l:whole_mapping = a:leader . l:lhs
	if len(l:whole_mapping) < a:lhs_align
		let l:whole_mapping .= repeat(' ', a:lhs_align - len(l:whole_mapping))
	endif
	echo printf("%s  %s", l:whole_mapping, l:rhs)
endf


"''''''''''''''''''''     function! s:show_mappings(com, leader, mappings)
function! s:show_mappings(com, leader, mappings)
	echo a:com . ":"
	let l:max_lhs = 0
	for l:map in a:mappings
		if len(l:map[0]) > l:max_lhs
			let l:max_lhs = len(l:map[0])
		endif
	endfor
	let l:max_lhs += len(a:leader)
	for l:map in a:mappings
		call s:show_mapping(a:leader, l:map, l:max_lhs)
	endfor
endf


"''''''''''''''''''''     function! listtools#mappings#show()
function! listtools#mappings#show()
	call s:show_mappings('noremap', g:listtools_leader, s:normal_mappings)
	call s:show_mappings('inoremap', g:listtools_insert_leader, s:insert_mappings)
	call s:show_mappings('cnoremap', g:listtools_command_leader, s:command_mappings)
	call s:show_mappings('nmap', g:listtools_leader, s:normal_plug_mappings)
	call s:show_mappings('vmap', g:listtools_visual_leader, s:visual_plug_mappings)
endf

