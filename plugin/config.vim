if exists('g:loaded_termdebug_nvim') || !has("nvim") || &compatible
    finish
endif
let g:loaded_termdebug_nvim = 1

let g:hw_gdb_file_bp = get(g:, 'hw_gdb_file_bp', "./vim.gdb_bp")


" Keymap options {{{1
"
if exists('g:neobugger_leader') && !empty(g:neobugger_leader)
    let g:gdb_keymap_trigger          = g:neobugger_leader.'s'

    let g:gdb_keymap_refresh          = g:neobugger_leader.'r'
    let g:gdb_keymap_continue         = g:neobugger_leader.'c'
    let g:gdb_keymap_next             = g:neobugger_leader.'n'
    let g:gdb_keymap_step             = g:neobugger_leader.'i'
    let g:gdb_keymap_finish           = g:neobugger_leader.'N'
    let g:gdb_keymap_until            = g:neobugger_leader.'t'
    let g:gdb_keymap_toggle_break     = g:neobugger_leader.'b'
    let g:gdb_keymap_toggle_break_all = g:neobugger_leader.'a'
    let g:gdb_keymap_clear_break      = g:neobugger_leader.'C'
    let g:gdb_keymap_debug_stop       = g:neobugger_leader.'x'
    let g:gdb_keymap_frame_up         = g:neobugger_leader.'k'
    let g:gdb_keymap_frame_down       = g:neobugger_leader.'j'
else
    let g:gdb_keymap_trigger          = get(g:, 'gdb_keymap_trigger',          '<f2>')

    let g:gdb_keymap_refresh          = get(g:, 'gdb_keymap_refresh',          '<f3>')
    let g:gdb_keymap_continue         = get(g:, 'gdb_keymap_continue',         '<f4>')
    let g:gdb_keymap_debug_stop       = get(g:, 'gdb_keymap_debug_stop',       '<S-f4>')
    let g:gdb_keymap_next             = get(g:, 'gdb_keymap_next',             '<f5>')
    let g:gdb_keymap_skip             = get(g:, 'gdb_keymap_skip',             '<S-f5>')
    let g:gdb_keymap_step             = get(g:, 'gdb_keymap_step',             '<f6>')
    let g:gdb_keymap_finish           = get(g:, 'gdb_keymap_finish',           '<S-f6>')
    let g:gdb_keymap_until            = get(g:, 'gdb_keymap_until',            '<f7>')
    let g:gdb_keymap_eval             = get(g:, 'gdb_keymap_eval',             '<f8>')
    let g:gdb_keymap_watch            = get(g:, 'gdb_keymap_watch',            '<S-f8>')
    let g:gdb_keymap_toggle_break     = get(g:, 'gdb_keymap_toggle_break',     '<f9>')
    let g:gdb_keymap_remove_break     = get(g:, 'gdb_keymap_remove_break',     '<S-f9>')
    let g:gdb_keymap_toggle_break_all = get(g:, 'gdb_keymap_toggle_break_all', '<f10>')
    let g:gdb_keymap_clear_break      = get(g:, 'gdb_keymap_clear_break',      '<S-f10>')
    let g:gdb_keymap_frame_up         = get(g:, 'gdb_keymap_frame_up',         '<a-n>')
    let g:gdb_keymap_frame_down       = get(g:, 'gdb_keymap_frame_down',       '<a-p>')
endif
" }}}


" Customization options {{{1
    let g:neogdb_gdbserver              = get(g:, 'neogdb_gdbserver',              'gdbserver')
    let g:neogdb_attach_remote_str      = get(g:, 'neogdb_attach_remote_str',      't1 127.0.0.1:9999')
    let g:gdb_auto_run                  = get(g:, 'gdb_auto_run',                  1)
    let g:gdb_auto_bp                   = get(g:, 'gdb_auto_bp',                   1)
    let g:restart_app_if_gdb_running    = get(g:, 'restart_app_if_gdb_running',    1)
    let g:neobugger_smart_eval          = get(g:, 'neobugger_smart_eval',          0)

    let g:neobugger_local_breakpoint    = get(g:, 'neobugger_local_breakpoint',    0)
    let g:neobugger_local_backtrace     = get(g:, 'neobugger_local_backtrace',     0)

    let g:neobugger_server_breakpoint   = get(g:, 'neobugger_server_breakpoint',   1)
    let g:neobugger_server_backtrace    = get(g:, 'neobugger_server_backtrace',    1)

    let g:vimgdb_sign_currentline       = get(g:, 'vimgdb_sign_currentline',       '☛')
    let g:vimgdb_sign_currentline_color = get(g:, 'vimgdb_sign_currentline_color', 'Error')
    let g:vimgdb_sign_breakpoints       = get(g:, 'vimgdb_sign_breakpoints', ['●', '●', '●', '●²', '●³', '●⁴', '●⁵', '●⁶', '●⁷', '●⁸', '●⁹', '●ⁿ'])
    let g:vimgdb_sign_breakp_color_en   = get(g:, 'vimgdb_sign_breakp_color_en',   'Search')
    let g:vimgdb_sign_breakp_color_dis  = get(g:, 'vimgdb_sign_breakp_color_dis',  'Function')
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
        exe 'unmap '  . g:gdb_keymap_refresh
        exe 'unmap '  . g:gdb_keymap_continue
        exe 'unmap '  . g:gdb_keymap_next
        exe 'unmap '  . g:gdb_keymap_step
        exe 'unmap '  . g:gdb_keymap_finish
        exe 'unmap '  . g:gdb_keymap_clear_break
        exe 'unmap '  . g:gdb_keymap_debug_stop
        exe 'unmap '  . g:gdb_keymap_until
        exe 'unmap '  . g:gdb_keymap_toggle_break
        exe 'unmap '  . g:gdb_keymap_toggle_break_all
        exe 'vunmap ' . g:gdb_keymap_toggle_break
        exe 'cunmap ' . g:gdb_keymap_toggle_break
        exe 'unmap '  . g:gdb_keymap_frame_up
        exe 'unmap '  . g:gdb_keymap_frame_down
    elseif a:type ==# "nmap"
        "if exists(":Termdebug")
            nnoremap <RightMouse> :Evaluate<CR>

            exe 'nnoremap <silent> ' . g:gdb_keymap_refresh          . ' :call TermDebugSendCommand("info local")<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_continue         . ' :Continue<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_next             . ' :Over<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_step             . ' :Step<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_skip             . ' :Skip<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_finish           . ' :Finish<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_until            . ' :GdbUntil<cr>'

            let toggle_break_binding = 'nnoremap <silent> '  . g:gdb_keymap_toggle_break . ' :Break<cr>'
            " if !g:gdb_require_enter_after_toggling_breakpoint
            "     let toggle_break_binding = toggle_break_binding . '<cr>'
            " endif
            exe toggle_break_binding
            exe 'cnoremap <silent> ' . g:gdb_keymap_toggle_break     . ' <cr>'

            exe 'nnoremap <silent> ' . g:gdb_keymap_toggle_break_all . ' :Clear<cr>'

            exe 'nnoremap <silent> ' . g:gdb_keymap_eval             . ' :Evaluate<cr>'
            exe 'vnoremap <silent> ' . g:gdb_keymap_eval             . ' :Evaluate<cr>'

            exe 'nnoremap <silent> ' . g:gdb_keymap_watch            . ' :GdbWatchWord<cr>'
            exe 'vnoremap <silent> ' . g:gdb_keymap_watch            . ' :GdbWatchRange<cr>'

            exe 'nnoremap <silent> ' . g:gdb_keymap_clear_break      . ' :Clear<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_debug_stop       . ' :Stop<cr>'

            exe 'nnoremap <silent> ' . g:gdb_keymap_frame_up         . ' :call TermDebugSendCommand("up")<cr>'
            exe 'nnoremap <silent> ' . g:gdb_keymap_frame_down       . ' :call TermDebugSendCommand("down")<cr>'
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
        let g:termdebug_wide = 1
        let g:termdebugger = 'gdb'

        "hi debugPC term=reverse ctermbg=darkyellow guibg=darkyellow
        hi debugPC cterm=NONE ctermbg=darkgreen ctermfg=white guibg=darkgreen guifg=white

        call s:Map('nmap')
        "call s:Breaks2Qf(g:hw_gdb_file_bp)

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

exec 'nnoremap '..g:gdb_keymap_trigger..' :<c-u><C-\>e VimGdbCommandStr()<cr>'
exec 'cnoremap '..g:gdb_keymap_trigger..' :<c-u><C-\>e VimGdbCommandStr()<cr>'
"}}}
