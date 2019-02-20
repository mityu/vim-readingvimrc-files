"Plugin Name: readingvimrc-files
"Author: mityu
"Last Change: 20-Feb-2019.
"License: MIT lisence

let s:cpo_save = &cpo
set cpo&vim

let s:V = vital#readingvimrc_files#new()
let s:http = s:V.import('Web.HTTP')
let s:next_files_info_url = 'https://raw.githubusercontent.com/vim-jp/reading-vimrc/gh-pages/_data/next.yml'
let s:default_config = {
            \ 'listing_window_open_command': 'topleft split',
            \ 'viewing_window_open_command': 'belowright split',
            \ 'no_default_key_mappings': 0,
            \ 'auto_expand_viewing_window': 1,
            \ 'auto_resize_listing_window': 1,
            \ }
augroup readingvimrc_files
    autocmd!
    autocmd User ReadingVimrcFilesOpenList call s:define_default_mapping_on_OpenList()
    autocmd User ReadingVimrcFilesOpenFile call s:define_default_mapping_on_OpenFile()
augroup END

function! readingvimrc_files#start() abort "{{{
    let buffer_name = 'readingvimrc-files://file-list'
    if s:move_to_buffer_if_exists(buffer_name) | return | endif

    let open_command = printf('%s %s',
                \ s:get_config('listing_window_open_command'),
                \ buffer_name)
    call s:list_files_info()
    call s:open_new_window({
                \ 'filetype': 'readingvimrc_files',
                \ 'contents': keys(s:files.url),
                \ 'open_command': open_command,
                \ })
    nnoremap <silent> <buffer> <Plug>(readingvimrc-files-view-file)
                \ :<C-u>call <SID>view_file()<CR>
    nnoremap <silent> <buffer> <Plug>(readingvimrc-files-quit)
                \ :<C-u><C-r>=(winnr('$') == 1) ? 'bdelete' : 'quit'<CR><CR>
    call s:fit_listing_window_size()
    augroup readingvimrc_files_list
        autocmd! WinEnter <buffer>
        autocmd WinEnter <buffer> call s:fit_listing_window_size()
    augroup END
    doautocmd User ReadingVimrcFilesOpenList
endfunc "}}}
function! s:fit_listing_window_size() abort "{{{
    if winnr('$') == 1 || !s:get_config('auto_resize_listing_window')
        return
    endif
    execute 'resize' (line('$') + 1)
endfunction "}}}
function! s:list_files_info() abort "{{{
    " NOTE: next.yml's structure{{{
    "   {Infomation about Nth, date, author, etc}
    "   - vimrcs:
    "       - url: >-
    "           {URL}
    "       name: {File Name}
    "       hash: {Hash}
    "        .
    "        .
    "        .
    "   {Other infomation}
    "}}}
    let s:files = {}
    let s:files.author = ''
    let s:files.url = {}
    let contents = split(s:http.get(s:next_files_info_url, {}, {}).content, "\n")
    call map(contents,'trim(v:val)')

    " Get author's name.
    while !empty(contents)
        let item = remove(contents, 0)
        if item ==# 'author:'
            " 6 is strlen('name: ')
            let s:files.author = strpart(remove(contents, 0), 6)
            break
        endif
    endwhile

    let [url, name] = ['', '']
    while !empty(contents)
        let item = remove(contents, 0)

        " Get file viewing page's url, and convert to raw file's url.
        if item ==# '- url: >-'
            let url = remove(contents, 0)
        else
            let url = matchstr(item, '\m-\surl:\s''\zs.*\ze''')
            if url ==# '' | continue | endif
        endif
        let url = substitute(url, '\m\<github\ze\.com\>', 'raw.githubusercontent', 'g')
        let url = substitute(url, '\m\<blob/', '', 'g')

        " Get file name.
        let name = strpart(remove(contents, 0), 6) " 6 is strlen('name: ')

        " Register file url.
        let s:files.url[name] = url
    endwhile
endfunc "}}}
function! s:view_file() abort "{{{
    let file_name = getline('.')
    let buffer_name = printf('readingvimrc-files://%s/%s', s:files.author, file_name)
    if !s:move_to_buffer_if_exists(buffer_name)
        let file_contents = split(s:http.get(s:files.url[file_name], {}, {}).content, "\n")
        let open_command = printf('%s %s',
                    \ s:get_config('viewing_window_open_command'),
                    \ buffer_name)
        call s:open_new_window({
                    \ 'filetype': 'vim',
                    \ 'contents': file_contents,
                    \ 'open_command': open_command,
                    \ })
        nnoremap <silent> <buffer> <Plug>(readingvimrc-files-quit)
                    \ :<C-u><C-r>=(winnr('$') == 1) ? 'bdelete' : 'quit'<CR><CR>
        doautocmd User ReadingVimrcFilesOpenFile
    endif
    if s:get_config('auto_expand_viewing_window')
        wincmd _
        wincmd |
    endif
endfunction "}}}
function! s:open_new_window(config) abort "{{{
    " NOTE: a:config's elements{{{
    "  - filetype : New window's filetype.
    "  - contents : New window's contents.
    "  - open_command : A command which is used to open a new window.
    "}}}
    execute a:config.open_command
    setlocal noreadonly modifiable
    silent % delete _
    call setline(1, a:config.contents)
    setlocal readonly nomodifiable buftype=nofile
    let &l:filetype = a:config.filetype
endfunction "}}}
function! s:move_to_buffer_if_exists(buffer_name) abort "{{{
    " This function returns winnr if moving to window is succeeded; Otherwise
    " returns 0.
    let winnr = bufwinnr(s:escape_file_pattern(a:buffer_name))
    if winnr != -1
        execute winnr 'wincmd w'
        return winnr
    endif
    return 0
endfunction "}}}
function! s:escape_file_pattern(file_name) abort "{{{
    return escape(a:file_name, '*?.~,{}\')
endfunction "}}}
function! s:get_config(kind) abort "{{{
    return get(g:, 'readingvimrc_files_' . a:kind, s:default_config[a:kind])
endfunction "}}}
function! s:define_default_mapping_on_OpenList() abort "{{{
    if !s:get_config('no_default_key_mappings')
        call s:default_mapping('<CR>', '<Plug>(readingvimrc-files-view-file)')
        call s:default_mapping('q', '<Plug>(readingvimrc-files-quit)')
    endif
endfunction "}}}
function! s:define_default_mapping_on_OpenFile() abort "{{{
    if !s:get_config('no_default_key_mappings')
        call s:default_mapping('q', '<Plug>(readingvimrc-files-quit)')
    endif
endfunction "}}}
function! s:default_mapping(lhs, rhs) abort "{{{
    if !hasmapto(a:rhs)
        execute 'nmap <buffer>' a:lhs a:rhs
    endif
endfunction "}}}

let &cpo = s:cpo_save
unlet s:cpo_save
