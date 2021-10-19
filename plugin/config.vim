if exists('g:loaded_termdebug_nvim') || !has("nvim") || &compatible
    finish
endif
let g:loaded_termdebug_nvim = 1
let g:termdebugMap = get(g:, 'termdebugMap', 1)

let g:termdebugListBpoint = get(g:, 'termdebugListBpoint', "vim.gdb_bp")
" The file name of backend file + floaterm's name
let g:termdebugFileBpoint = get(g:, 'termdebugFileBpoint', "vim.gdb_bpoint")
let g:termdebugFileBtrace = get(g:, 'termdebugFileBtrace', "vim.gdb_btrace")

" exec 'FloatermNew! --wintype=float --name=tbtrace --height=0.3 --width=0.3 --position=right --title="breakpoints" vi -c ":echom wilson" ~/.vimrc'
" let s:views.backtrace = 'tbtrace'

" Keymap options {{{1
"
if exists('g:termdebugMapleader') && !empty(g:termdebugMapleader)
    let g:termdebugMapTrigger        = g:termdebugMapleader.'s'

    let g:termdebugMapRefresh        = g:termdebugMapleader.'r'
    let g:termdebugMapContinue       = g:termdebugMapleader.'c'
    let g:termdebugMapNext           = g:termdebugMapleader.'n'
    let g:termdebugMapStep           = g:termdebugMapleader.'i'
    let g:termdebugMapFinish         = g:termdebugMapleader.'N'
    let g:termdebugMapUntil          = g:termdebugMapleader.'t'
    let g:termdebugMapToggleBreak    = g:termdebugMapleader.'b'
    let g:termdebugMapToggleBreakAll = g:termdebugMapleader.'a'
    let g:termdebugMapClearBreak     = g:termdebugMapleader.'C'
    let g:termdebugMapDebugStop      = g:termdebugMapleader.'x'
    let g:termdebugMapFrameUp        = g:termdebugMapleader.'k'
    let g:termdebugMapFrameDown      = g:termdebugMapleader.'j'
else
    let g:termdebugMapTrigger        = get(g:, 'termdebugMapTrigger',        '<f2>')

    let g:termdebugMapRefresh        = get(g:, 'termdebugMapRefresh',        '<f3>')
    let g:termdebugMapContinue       = get(g:, 'termdebugMapContinue',       '<f4>')
    let g:termdebugMapDebugStop      = get(g:, 'termdebugMapDebugStop',      '<S-f4>')
    let g:termdebugMapNext           = get(g:, 'termdebugMapNext',           '<f5>')
    let g:termdebugMapSkip           = get(g:, 'termdebugMapSkip',           '<S-f5>')
    let g:termdebugMapStep           = get(g:, 'termdebugMapStep',           '<f6>')
    let g:termdebugMapFinish         = get(g:, 'termdebugMapFinish',         '<S-f6>')
    let g:termdebugMapUntil          = get(g:, 'termdebugMapUntil',          '<f7>')
    let g:termdebugMapEval           = get(g:, 'termdebugMapEval',           '<f8>')
    let g:termdebugMapWatch          = get(g:, 'termdebugMapWatch',          '<S-f8>')
    let g:termdebugMapToggleBreak    = get(g:, 'termdebugMapToggleBreak',    '<f9>')
    let g:termdebugMapRemoveBreak    = get(g:, 'termdebugMapRemoveBreak',    '<S-f9>')
    let g:termdebugMapToggleBreakAll = get(g:, 'termdebugMapToggleBreakAll', '<f10>')
    let g:termdebugMapClearBreak     = get(g:, 'termdebugMapClearBreak',     '<S-f10>')

    let g:termdebugMapFrameUp        = get(g:, 'termdebugMapFrameUp',        '<a-n>')
    let g:termdebugMapFrameDown      = get(g:, 'termdebugMapFrameDown',      '<a-p>')

    let g:termdebugMapViewToggle     = get(g:, 'termdebugMapViewToggle',     '<c-u>')
    let g:termdebugMapViewBpoint     = get(g:, 'termdebugMapViewBpoint',     '<a-.>')
    let g:termdebugMapViewBtrace     = get(g:, 'termdebugMapViewBtrace',     '<a-,>')
endif
" }}}


" Customization options {{{1
    let g:termdebug_auto_bp                = get(g:, 'termdebug_auto_bp',                1)

    let g:termdebug_sign_currentline       = get(g:, 'termdebug_sign_currentline',       '☛')
    let g:termdebug_sign_currentline_color = get(g:, 'termdebug_sign_currentline_color', 'Error')
    let g:termdebug_sign_breakpoints       = get(g:, 'termdebug_sign_breakpoints',       ['●', '●', '●²', '●³', '●⁴', '●⁵', '●⁶', '●⁷', '●⁸', '●⁹', '●ⁿ'])
    let g:termdebug_sign_breakp_color_en   = get(g:, 'termdebug_sign_breakp_color_en',   'Search')
    let g:termdebug_sign_breakp_color_dis  = get(g:, 'termdebug_sign_breakp_color_dis',  'Function')
" }}}


fun! s:SaveVariable(var, file)
    call writefile([string(a:var)], a:file)
endf

fun! s:ReadVariable(varname, file)
    let recover = readfile(a:file)[0]
    execute "let ".a:varname." = " . recover
endf


fun! s:Breaks2Qf()
    let list2 = []
    let i = 0
    for [next_key, next_val] in items(s:breakpoints)
        if !empty(next_val['cmd'])
            let i += 1
            call add(list2, printf('#%d  %d in    %s    at %s:%d',
                        \ i, next_val['state'], next_val['cmd'],
                        \ next_val['file'], next_val['line']))
        endif
    endfor

    call writefile(split(join(list2, "\n"), "\n"), s:vimqf_breakpoint)
    if self._show_breakpoint && filereadable(s:vimqf_breakpoint)
        exec "silent lgetfile " . s:vimqf_breakpoint
    endif
endf


fun! s:Map(type)
    silent! call s:log.debug(l:__func__, " type=", a:type)

    if a:type ==# "unmap"
        exe 'unmap '  . g:termdebugMapRefresh
        exe 'unmap '  . g:termdebugMapContinue
        exe 'unmap '  . g:termdebugMapNext
        exe 'unmap '  . g:termdebugMapStep
        exe 'unmap '  . g:termdebugMapFinish
        exe 'unmap '  . g:termdebugMapClearBreak
        exe 'unmap '  . g:termdebugMapDebugStop
        exe 'unmap '  . g:termdebugMapUntil
        exe 'unmap '  . g:termdebugMapToggleBreak
        exe 'unmap '  . g:termdebugMapRemoveBreak
        exe 'unmap '  . g:termdebugMapToggleBreakAll
        exe 'vunmap ' . g:termdebugMapToggleBreak
        exe 'cunmap ' . g:termdebugMapToggleBreak
        exe 'unmap '  . g:termdebugMapFrameUp
        exe 'unmap '  . g:termdebugMapFrameDown
        exe 'unmap '  . g:termdebugMapViewToggle
        exe 'vunmap ' . g:termdebugMapViewToggle
        exe 'unmap '  . g:termdebugMapViewBpoint
        exe 'unmap '  . g:termdebugMapViewBtrace
    elseif a:type ==# "nmap"
        "if exists(":Termdebug")
            nnoremap <RightMouse> :Evaluate<CR>

            exe 'nnoremap <silent> ' . g:termdebugMapRefresh          . ' :call TermDebugSendCommand("info local")<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapContinue         . ' :Continue<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapNext             . ' :Over<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapStep             . ' :Step<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapSkip             . ' :Skip<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapFinish           . ' :Finish<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapUntil            . ' :GdbUntil<cr>'

            let toggle_break_binding = 'nnoremap <silent> '  . g:termdebugMapToggleBreak . ' :Break<cr>'
            " if !g:gdb_require_enter_after_toggling_breakpoint
            "     let toggle_break_binding = toggle_break_binding . '<cr>'
            " endif
            exe toggle_break_binding
            exe 'cnoremap <silent> ' . g:termdebugMapToggleBreak      . ' <cr>'

            exe 'nnoremap <silent> ' . g:termdebugMapRemoveBreak      . ' :Clear<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapToggleBreakAll   . ' :ToggleAll<cr>'

            exe 'nnoremap <silent> ' . g:termdebugMapEval             . ' :Evaluate<cr>'
            exe 'vnoremap <silent> ' . g:termdebugMapEval             . ' :Evaluate<cr>'

            exe 'nnoremap <silent> ' . g:termdebugMapWatch            . ' :GdbWatchWord<cr>'
            exe 'vnoremap <silent> ' . g:termdebugMapWatch            . ' :GdbWatchRange<cr>'

            exe 'nnoremap <silent> ' . g:termdebugMapClearBreak       . ' :ClearAll<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapDebugStop        . ' :Stop<cr>'

            exe 'nnoremap <silent> ' . g:termdebugMapFrameUp          . ' :call TermDebugSendCommand("up")<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapFrameDown        . ' :call TermDebugSendCommand("down")<cr>'

            exe 'vnoremap <silent> ' . g:termdebugMapViewToggle       . ' :call TermDebugView("all")<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapViewBpoint       . ' :call TermDebugView("tbpoint")<cr>'
            exe 'nnoremap <silent> ' . g:termdebugMapViewBtrace       . ' :call TermDebugView("tbtrace")<cr>'
        "endif
    endif
endf

" Helper options {{{1
" call VimGdb('local', 't1')
" call VimGdb('remote', 'sysinit/init')
"let s:enum_dbg_type = local
function! VimGdbCommandStr()
    " https://chmanie.com/post/2020/07/18/debugging-arm-based-microcontrollers-in-neovim-with-gdb/
    " See https://neovim.io/doc/user/nvim_terminal_emulator.html
    "let s:enum_dbg_type = s:enum_dbg_t_local
    if exists(":Termdebug")
        "let g:termdebugger_program = "pio device monitor -b 38400"
        "let g:termdebug_useFloatingHover = 0
        let g:termdebug_wide = get(g:, 'termdebug_wide', 2)
        let g:termdebugger = 'gdb'

        "hi debugPC term=reverse ctermbg=darkyellow guibg=darkyellow
        hi debugPC cterm=NONE ctermbg=darkgreen ctermfg=white guibg=darkgreen guifg=white

        if g:termdebugMap
            call s:Map('nmap')
        endif
        "call s:Breaks2Qf(g:termdebugListBpoint)

        if filereadable('./sysinit/init')
            return "Termdebug sysinit/init"
        elseif filereadable('./CMakeLists.txt')
            return "Termdebug build/". expand('%:t:r')
        else
            return "Termdebug ". expand('%:t:r')
        endif
    else
        echomsg "No command :Termdebug"
    endif
endfunction


if g:termdebugMap
    exec 'nnoremap '..g:termdebugMapTrigger..' :<c-u><C-\>e VimGdbCommandStr()<cr>'
    exec 'cnoremap '..g:termdebugMapTrigger..' :<c-u><C-\>e VimGdbCommandStr()<cr>'
endif
"}}}
