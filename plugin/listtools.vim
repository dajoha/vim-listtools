

if (exists('g:loaded_listtools') || &cp) && !exists('g:listtools_dev_mode')
	finish
endif

let g:loaded_listtools = 1
let s:keepcpo = &cpo
set cpo&vim


" DEFAULT VALUES:

"''''''''''''''''''''     function! s:default(var_name, default_val)
" Sets a variable, unless it was already defined.
function! s:default(var_name, default_val)
	if !exists(a:var_name)
		execute 'let' a:var_name '=' string(a:default_val)
	endif
endf


" Default values for public parameters:

" Set the default leader key to '<leader>l':
call s:default('g:listtools_leader', '<leader>l')
" Set the default visual-mode leader key equal to the normal-mode leader:
call s:default('g:listtools_visual_leader', g:listtools_leader)
" Set the default insert-mode leader key to '<c-r><c-l>':
call s:default('g:listtools_insert_leader', '<c-r><c-l>')
" Set the default command-mode leader key equal to the insert-mode leader:
call s:default('g:listtools_command_leader', g:listtools_insert_leader)

" Enable default mappings by default:
call s:default('g:listtools_enable_mappings', 1)

" Disable command abbreviations by default:
call s:default('g:listtools_enable_cabbr', 0)
" When command abbreviations are enabled, prefix to use for each one:
call s:default('g:listtools_cabbr_prefix', 'lt')

" Enable messages by default:
call s:default('g:listtools_verbose', 1)



" ABBREVIATIONS:

if g:listtools_enable_cabbr  " Disabled by default
	" The first element of each pair is not the actual abbr, but only its suffix:
	let s:abbrs = [
		\ [ 'n'   , 'LTNew'         ], [ 'r'   , 'LTReset'     ], [ 'e'   , 'LTEmpty'     ], [ 'd'  , 'LTDelete'     ],
		\ [ 'l'   , 'LTList'        ], [ 'la'  , 'LTList'      ],
		\ [ 'p'   , 'LTPop'         ],
		\ [ 'sw'  , 'LTSwap'        ], [ 'sn'  , 'LTSwapNext'  ], [ 'sp'  , 'LTSwapPrev'  ],
		\ [ 's'   , 'LTSet'         ], [ 'set' , 'LTSet'       ], [ 'let' , 'LTLet'       ], [ 'a'  , 'LTAdd'        ],
		\ [ 'us'  , 'LTUnset'       ],
		\ [ 'um'  , 'LTUnmatch'     ], [ 'km'  , 'LTKeepmatch' ],
		\ [ 'm'   , 'LTMatch'       ], [ 'ma'  , 'LTMatchAdd'  ],
		\ [ 'f'   , 'LTFilter'      ], [ 'map' , 'LTMap'       ], [ 'u'   , 'LTUniq'      ],
		\ [ 'sur' , 'LTSurround'    ], [ 'suf' , 'LTSuffix'    ], [ 'pre' , 'LTPrefix'    ],
		\ [ 'dsur', 'LTDelSurround' ], [ 'dsuf', 'LTDelSuffix' ], [ 'dpre', 'LTDelPrefix' ],
		\ [ 'qm'  , 'LTQMatch'      ], [ 'qma' , 'LTQMatchAdd' ],
		\ [ 'lr'  , 'LTLR'          ],
		\ [ 'ext' , 'LTExtend'      ], [ 'uni' , 'LTUnion'     ], [ 'int' , 'LTIntersect' ], [ 'dif', 'LTDifference' ],
	\ ]

	for s:abbr in s:abbrs
		exe 'cabbr' g:listtools_cabbr_prefix.s:abbr[0] s:abbr[1]
	endfor
endif



" COMMANDS:

" General commands:

command! -nargs=* LTNew call listtools#new([<f-args>], 1)
command! -nargs=* LTDelete call listtools#delete(<q-args>, 1)
command! -nargs=* LTList call listtools#list(<q-args>, 1)
command! -nargs=1 LTSwap call listtools#swap(<q-args>, 1)
command! -nargs=* LTSwapNext call listtools#swap_next(empty(<q-args>) ? 1 : str2nr(<q-args>), 1)
command! -nargs=* LTSwapPrev call listtools#swap_prev(empty(<q-args>) ? 1 : str2nr(<q-args>), 1)

" Set items in lists:

command! -bang -nargs=+ LTSet call listtools#commands#args_range('listtools#set', [<f-args>], '<bang>')
command! -bang -nargs=* -range LTMatch call listtools#commands#match('listtools#set_from_match', <line1>, <line2>, <q-args>, '<bang>')
command! -bang -nargs=+ -complete=expression LTLet call listtools#commands#let(<q-args>, '<bang>')

" Add items to lists:

command! -bang -nargs=+ LTAdd call listtools#commands#args_range('listtools#add', [<f-args>], '<bang>')
command! -bang -nargs=* -range LTMatchAdd call listtools#commands#match('listtools#add_from_match', <line1>, <line2>, <q-args>, '<bang>')
command! -bang -nargs=+ -complete=expression LTExtend call listtools#commands#list_oper('listtools#extend', 'Extend', [<f-args>], '<bang>')

" Remove items from lists:

command! -nargs=* LTEmpty call listtools#empty(<q-args>, 1)
command! -bang -nargs=+ LTUnset call listtools#commands#args_range('listtools#unset', [<f-args>], '<bang>')
command! -bang -nargs=* LTUnmatch call listtools#commands#args_range('listtools#unmatch', <q-args>, '<bang>')
command! -bang -nargs=* LTKeepmatch call listtools#commands#args_range('listtools#keepmatch', <q-args>, '<bang>')
command! -bang -nargs=+ -complete=expression LTFilter call listtools#commands#args_range('listtools#filter', <q-args>, '<bang>')
command! -bang -nargs=* LTUniq call listtools#commands#range('listtools#uniq', <q-args>, '<bang>')

" Operations on lists:

command! -bang -nargs=+ -complete=expression LTUnion call listtools#commands#list_oper('listtools#union', 'Union', [<f-args>], '<bang>')
command! -bang -nargs=+ -complete=expression LTIntersect call listtools#commands#list_oper('listtools#intersect', 'Intersection', [<f-args>], '<bang>')
command! -bang -nargs=+ -complete=expression LTDifference call listtools#commands#list_oper('listtools#difference', 'Difference', [<f-args>], '<bang>')

" Filter content, surrounds commands:

command! -bang -nargs=+ -complete=expression LTMap call listtools#commands#args_range('listtools#map', <q-args>, '<bang>')
command! -bang -nargs=* LTPrefix call listtools#commands#surround('listtools#add_surround', [<f-args>], 0, '<bang>')
command! -bang -nargs=* LTSuffix call listtools#commands#surround('listtools#add_surround', [<f-args>], 1, '<bang>')
command! -bang -nargs=* LTSurround call listtools#commands#surround('listtools#add_surround', [<f-args>], 2, '<bang>')
command! -bang -nargs=* LTDelPrefix call listtools#commands#surround('listtools#del_surround', [<f-args>], 0, '<bang>')
command! -bang -nargs=* LTDelSuffix call listtools#commands#surround('listtools#del_surround', [<f-args>], 1, '<bang>')
command! -bang -nargs=* LTDelSurround call listtools#commands#surround('listtools#del_surround', [<f-args>], 2, '<bang>')

" Stack commands:

command! -nargs=* LTReset call listtools#reset(<q-args>, 1)
command! -nargs=* LTPop call listtools#commands#range('listtools#pop', <q-args>, 1)

" Commands for the qpatterns plugin:

command! -bang -nargs=1 -range LTQMatch call listtools#commands#match('listtools#set_from_qmatch', <line1>, <line2>, <q-args>, '<bang>')
command! -bang -nargs=1 -range LTQMatchAdd call listtools#commands#match('listtools#add_from_qmatch', <line1>, <line2>, <q-args>, '<bang>')



" MAPPINGS:

if g:listtools_enable_mappings
	call listtools#mappings#install_all_mappings()
endif

" Plug mappings:

nnoremap <silent> <Plug>ListtoolsAddCWord :call listtools#add_cword(1)<cr>
vnoremap <silent> <Plug>ListtoolsAddSelection :<c-u>call listtools#add_selection(1)<cr>
nnoremap <silent> <Plug>ListtoolsResetCur :call listtools#reset('%',1)<cr>
nnoremap <silent> <Plug>ListtoolsResetAll :call listtools#reset('*',1)<cr>
nnoremap <silent> <Plug>ListtoolsEmptyCur :call listtools#empty('%',1)<cr>
nnoremap <silent> <Plug>ListtoolsEmptyAll :call listtools#empty('*',1)<cr>
nnoremap <silent> <Plug>ListtoolsDeleteCur :call listtools#delete('%',1)<cr>
nnoremap <silent> <Plug>ListtoolsDeleteAll :call listtools#delete('*',1)<cr>
nnoremap <silent> <Plug>ListtoolsListCur :call listtools#list('%')<cr>
nnoremap <silent> <Plug>ListtoolsListAll :call listtools#list()<cr>
nnoremap <silent> <Plug>ListtoolsPop :call listtools#pop('%', 1)<cr>
nnoremap <silent> <Plug>ListtoolsSwapNext :<c-u>call listtools#swap_next(v:count==0 ? 1 : v:count, 1)<cr>
nnoremap <silent> <Plug>ListtoolsSwapPrev :<c-u>call listtools#swap_prev(v:count==0 ? 1 : v:count, 1)<cr>
nnoremap <silent> <Plug>ListtoolsNewList :call listtools#new([], 1)<cr>
nnoremap <silent> <Plug>ListtoolsUniqCur :call listtools#uniq('%', 1)<cr>
nnoremap <silent> <Plug>ListtoolsUniqAll :call listtools#uniq('*', 1)<cr>



" HIGHLIGHTING:

" Used for non-important text:
hi link ListtoolsComment Comment
" Used to highlight the current list inside listings:
hi link ListtoolsCurrentList ModeMsg
" Used to highlight items inside listings:
hi link ListtoolsItem Special



" INITIALIZATION:

call listtools#base#initialize()



let &cpo= s:keepcpo
unlet s:keepcpo

