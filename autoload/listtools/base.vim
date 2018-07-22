

"''''''''''''''''''''     function! listtools#base#get_new_list()
function! listtools#base#get_new_list()
	return { 'eaten_list' : [], 'whole_list' : [], 'last' : '' }
endf


"''''''''''''''''''''     function! listtools#base#init_lists()
" Removes all existent lists and creates an empty one.
function! listtools#base#init_lists()
	let g:listtools_lists = [ listtools#base#get_new_list() ]
	let g:listtools_cur_list = g:listtools_lists[0]
	let g:listtools_cur_list_nr = 0
endf


"''''''''''''''''''''     function! listtools#base#initialize()
" Called on plugin load.
function! listtools#base#initialize()
	call listtools#base#init_lists()
endf


