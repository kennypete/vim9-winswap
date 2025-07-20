vim9script

var markedWinNum: list<number>

def SetMarkedWindowNum(tab: number, win: number): void
  markedWinNum = [tab, win]
enddef

def ClearMarkedWindowNum(): void
  markedWinNum = null_list
enddef

def MarkWindowSwap(): void
  SetMarkedWindowNum(tabpagenr(), winnr())
enddef

def SaveWindowSettings(): dict<any>
  final SETTINGS: dict<any> = {}
  const LOCAL_SETTINGS: list<string> = ['arabic',
    'breakindent', 'breakindentopt', 'colorcolumn', 'concealcursor',
    'conceallevel', 'cursorbind', 'cursorcolumn', 'cursorline',
    'cursorlineopt', 'diff', 'foldcolumn', 'foldenable', 'foldexpr',
    'foldignore', 'foldlevel', 'foldmarker', 'foldmethod', 'foldminlines',
    'foldnestmax', 'foldtext', 'linebreak', 'list', 'number', 'numberwidth',
    'previewwindow', 'relativenumber', 'rightleft', 'rightleftcmd',
    'scroll', 'scrollbind', 'signcolumn', 'smoothscroll', 'spell',
    'termwinkey', 'termwinsize', 'wincolor', 'winfixbuf',
    'winfixheight', 'winfixwidth', 'wrap']
  for setting in LOCAL_SETTINGS
    try
      SETTINGS[setting] = eval($"&{setting}")
    catch
      # Silently skip settings that don't exist in this Vim version
      # echo v:exception
    endtry
  endfor
  return SETTINGS
enddef

def RestoreWindowSettings(settings: dict<any>): void
  for [setting, value] in items(settings)
    try
      if type(value) == v:t_string
        execute $"vim9 &{setting} = '{value}'"
      else
        execute $"vim9 &{setting} = {value}"
      endif
    catch
      # Silently skip settings that can't be restored
      # echo v:exception
    endtry
  endfor
enddef

def DoWindowSwap(): void
  # Save the current window context
  const CUR_TAB: number = tabpagenr()
  const CUR_WIN_NUM: number = winnr()
  const CUR_VIEW: dict<number> = winsaveview()
  const CUR_BUF: number = bufnr("%")
  const CUR_SETTINGS: dict<any> = SaveWindowSettings()
  const TARGET_WIN: list<number> = markedWinNum
  # Go to the marked window and save its window context
  execute $"tabn {TARGET_WIN[0]}"
  execute $":{TARGET_WIN[1]}wincmd w"
  const MARKED_VIEW: dict<number> = winsaveview()
  const MARKED_BUF: number = bufnr("%")
  const MARKED_SETTINGS: dict<any> = SaveWindowSettings()
  # Place current buffer, with its settings, into the marked window
  execute $"hide buf {CUR_BUF}"
  winrestview(CUR_VIEW)
  RestoreWindowSettings(CUR_SETTINGS)
  # Go to the current window
  execute $"tabn {CUR_TAB}"
  execute $":{CUR_WIN_NUM}wincmd w"
  # Place the marked buffer, with its settings, into the current window
  execute $"hide buf {MARKED_BUF}"
  winrestview(MARKED_VIEW)
  RestoreWindowSettings(MARKED_SETTINGS)
  ClearMarkedWindowNum()
enddef

def DoWindowPut(): void
  # Save the current window context
  const CUR_TAB: number = tabpagenr()
  const CUR_WIN_NUM: number = winnr()
  const TARGET_WIN: list<number> = markedWinNum
  # Go to the marked window and save its buffer and settings
  execute $"tabn {TARGET_WIN[0]}"
  execute $":{TARGET_WIN[1]}wincmd w"
  const MARKED_VIEW: dict<number> = winsaveview()
  const MARKED_BUF: number = bufnr("%")
  const MARKED_SETTINGS: dict<any> = SaveWindowSettings()
  # Return to the current window and place marked buffer there
  execute $"tabn {CUR_TAB}"
  execute $":{CUR_WIN_NUM}wincmd w"
  execute $"hide buf {MARKED_BUF}"
  winrestview(MARKED_VIEW)
  RestoreWindowSettings(MARKED_SETTINGS)
  ClearMarkedWindowNum()
enddef

# Stat ... do the mark, swap, or put (clone)
export def Stat(arg: string = 'swap'): void
  if markedWinNum == null_list
    MarkWindowSwap()
  elseif arg == 'swap'
    DoWindowSwap()
  else
    DoWindowPut()
  endif
enddef

# Swap two windows by their window numbers
export def SwapByWinNums(win1: string, win2: string): void
  if win1 == win2
    echo "Cannot swap window with itself"
    return
  endif
  const W1: number = str2nr(win1)
  const W2: number = str2nr(win2)
  const TOTAL_WINDOWS: number = winnr('$')
  if W1 < 1 || W1 > TOTAL_WINDOWS || W2 < 1 || W2 > TOTAL_WINDOWS
    echo $"Invalid window numbers. Valid range: 1-{TOTAL_WINDOWS}"
    return
  endif
  # Clear any existing marked window
  ClearMarkedWindowNum()
  # Go to first window and mark it
  execute $":{W1}wincmd w"
  MarkWindowSwap()
  # Go to second window and swap
  execute $":{W2}wincmd w"
  DoWindowSwap()
enddef

# vim: ts=2 sts=2 et ft=vim nowrap
