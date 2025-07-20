if (v:version < 802 || (v:version == 802 && !has('patch4883')))
  " Vim 8.2 < patch 4883 handling:
  echo "vim9-winswap requires Vim9 (or 8.2 with patch 4833)"
  finish
endif

vim9script

if exists('g:loaded_winswap')
  finish
endif

import autoload '../autoload/winswap.vim'

g:winswap_opt_maps = exists('g:winswap_opt_maps') ? g:winswap_opt_maps : false

nnoremap <silent> <Plug>(Winswap_ww) <ScriptCmd>winswap.Stat()<CR>
nnoremap <silent> <Plug>(Winswap_wp) <ScriptCmd>winswap.Stat('put')<CR>

# Optional 'default' mappings, which are 'opt-in' only
if g:winswap_opt_maps
  # Mark when there is no window marked; swaps if there is a window marked
  nnoremap <silent> <Leader>ww <Plug>(Winswap_ww)
  # Put/clone (provided there is already a marked window)
  nnoremap <silent> <Leader>wp <Plug>(Winswap_wp)
endif

# Command to swap two windows by their window numbers
command! -nargs=+ Winswap winswap.SwapByWinNums(<f-args>)
cnoreabbrev Ws Winswap

g:loaded_winswap = true

# vim: ts=2 sts=2 et ft=vim nowrap
