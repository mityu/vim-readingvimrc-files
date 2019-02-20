"Plugin Name: readingvimrc-files
"Author: mityu
"Last Change: 17-Feb-2019.
"License: MIT lisence

if exists('g:loaded_readingvimrc_files')
	finish
endif
let g:loaded_readingvimrc_files = 1

let s:cpo_save = &cpo
set cpo&vim

command! -bar ReadingVimrcFiles call readingvimrc_files#start()

let &cpo = s:cpo_save
unlet s:cpo_save
