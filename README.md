termdebug.nvim
==============
Copy termdebug.vim but with more features:
- [x] enable customer define key-map
- breakpoints
  - [x] auto breakpoints save/restore base on function
  - [x] add enable/disable breakpoints
  - [x] push breakpoints to a floatterm
- [x] push backtrace to floatterm
- [x] add auto mode to: vertical, horizon
- [ ] output to floaterm

Why I copy/change termdebug.nvim:
- open to use, easy add customize keymap,
- quick, some gdb front-end using python api slow down the program,
- have gdb interact cmd shell, can't find it in `vimspector`
  - customize pretty-print

## QuickStart (default map)

Sample 1:
1. Command  :Termdebug <prog>
2. :gdb run		# start program
3. <C-u>		# Open/Toggle backtrace/breakpoints view
4. <A-.>		# Focus breakpoints
5. <A-,>		# Focus backtrace

Sample 2:
1. <F2>			# :Termdebug <prog>
...


## Require

- only work under linux(perl/gawk/echo) + neovim(ipc by `nvr`)
- require [nvr](https://github.com/mhinz/neovim-remote) to support floaterm ipc with main-gdb-window
	`$ pip3 install --user neovim-remote`
- require vim plugin [vim-floaterm](https://github.com/voldikss/vim-floaterm) to support backtrace/breakpoints float windows
	* vim-plug
		Plug 'voldikss/vim-floaterm'
	* dein.nvim
		call dein#add('voldikss/vim-floaterm')	
- remote plugin by vim command `:UpdateRemotePlugins`

## Keymap: [default]

Keymap [Enable]/disable:  g:termdebugMap
```vim
	let g:termdebugMap = 0
```
GDB-window mode:  g:termdebug_wide
	 0   horizon
	 1   vertical
	[2]  auto

## Develop

### GDB /MI interface

	$ gdb --interpreter=mi2 a.out

