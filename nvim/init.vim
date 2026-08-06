set nocompatible
set encoding=utf-8
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set clipboard=unnamedplus
set mouse=a
set termguicolors
set cursorline
syntax on
filetype plugin indent on
set signcolumn=yes

" nvim-tree 取代 netrw，必須在載入任何外掛之前關掉
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" fix esc delay
" 降低 Esc delay
set timeout
set timeoutlen=300
set ttimeout
set ttimeoutlen=10



" markdown 
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:tex_conceal = ""
set conceallevel=0


" ── vim-plug 自動 bootstrap ──────────────────────────────────────────────
" 新電腦上若 plug.vim 不存在，自動下載並在啟動後執行 :PlugInstall。
let s:plug_path = stdpath('data') . '/site/autoload/plug.vim'
if empty(glob(s:plug_path))
  silent execute '!curl -fLo ' . s:plug_path . ' --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" 狀態列
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" 檔案樹（2026-08-06 由 NERDTree 換成 nvim-tree；NERDTree 已進入維護模式）
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
" vim-devicons 保留：只供 airline 的 filetype glyph，nvim-tree 不吃它
Plug 'ryanoasis/vim-devicons'

" 模糊搜尋
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" 註解
Plug 'preservim/nerdcommenter'

" 括號補全
Plug 'jiangmiao/auto-pairs'

" 語法與縮排
Plug 'sheerun/vim-polyglot'

" LSP / 補全
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Markdown plugin
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
Plug 'godlygeek/tabular'
Plug 'jiangmiao/auto-pairs'
Plug 'HakonHarnes/img-clip.nvim'

" Color
Plug 'morhetz/gruvbox'
Plug 'jacoborus/tender.vim'
Plug 'bluz71/vim-moonfly-colors', { 'as': 'moonfly' }
Plug 'shaunsingh/nord.nvim'

" Tab
Plug 'akinsho/bufferline.nvim', { 'tag': '*' }
Plug 'nvim-mini/mini.bufremove'

" Session（依 cwd 自動記/還原 buffer 與分割視窗；配合多 worktree tmux window 切換）
Plug 'rmagatti/auto-session'

call plug#end()

" ── auto-session：依 cwd 自動存/還原 ──────────────────────────────────────
lua << EOF
local ok, auto_session = pcall(require, 'auto-session')
if ok then
  auto_session.setup({
    auto_session_enable_last_session = false,
    auto_session_root_dir = vim.fn.stdpath('data') .. '/sessions/',
  })
end
EOF

" Markdown fold
" Markdown Tree-sitter folding
augroup markdown_folding
  autocmd!
  autocmd FileType markdown lua vim.treesitter.start()
  autocmd FileType markdown setlocal foldmethod=expr
  autocmd FileType markdown setlocal foldexpr=v:lua.vim.treesitter.foldexpr()
  autocmd FileType markdown setlocal foldenable
  autocmd FileType markdown setlocal foldlevel=99
augroup END

set foldlevelstart=99

" ── icon（vim-devicons，僅供 airline）───────────────────────────────────
" 需終端機使用 Nerd Font 字型，否則會顯示成豆腐方框
let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 0
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
" airline 用 powerline 字元（Nerd Font 已含）
let g:airline_powerline_fonts = 1

" 檔案樹快捷鍵（nvim-tree）
nnoremap <F3> <Cmd>NvimTreeToggle<CR>
nnoremap <leader>tf <Cmd>NvimTreeFindFile<CR>
"
" fzf 快捷鍵
nnoremap <F4> :Files<CR>
nnoremap <C-f> :Rg<CR>

" configure file reload
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>ev :edit $MYVIMRC<CR>

" file manipulation
nnoremap <C-s> :w<CR>

" copy paste
vnoremap <C-c> "+y
nnoremap <C-v> "+p

" MD: Paste image
lua << EOF
require("img-clip").setup({
  default = {
    dir_path = "assets",
    relative_to_current_file = true,
    prompt_for_file_name = false,
    file_name = "%Y%m%d_%H%M%S",

    -- WSL / ImageMagick 6: BMP 轉 PNG
    extension = "png",
    process_cmd = "convert bmp:- png:-",
  },
})

vim.keymap.set("n", "<leader>p", "<cmd>PasteImage<cr>", {
  desc = "Paste screenshot"
})
EOF


" color schemev
colorscheme gruvbox

" 下面開始加
function! FridOpenExternal(path) abort
  let l:path = fnamemodify(a:path, ':p')

  if filereadable('/proc/version') && readfile('/proc/version')[0] =~? 'microsoft\|wsl'
    let l:winpath = substitute(system('wslpath -w ' . shellescape(l:path)), '\n$', '', '')
    call jobstart(['explorer.exe', l:winpath], {'detach': v:true})
    return
  endif

  if executable('explorer.exe')
    let l:winpath = substitute(system('wslpath -w ' . shellescape(l:path)), '\n$', '', '')
    call jobstart(['explorer.exe', l:winpath], {'detach': v:true})
    return
  endif

  if has('macunix')
    call jobstart(['open', l:path], {'detach': v:true})
  else
    call jobstart(['xdg-open', l:path], {'detach': v:true})
  endif
endfunction

function! FridIsImage(path) abort
  return a:path =~? '\v\.(png|jpg|jpeg|gif|webp|bmp|svg)$'
endfunction

" ── nvim-tree 設定 ───────────────────────────────────────────────────────
" 智慧開啟：目錄展開／圖片交給 Windows 外部程式／其餘正常開啟。
" 沿用上面 VimScript 的 FridOpenExternal()、FridIsImage()（WSL explorer.exe 邏輯已驗證）。
lua << EOF
local api = require("nvim-tree.api")

local function smart_enter()
  local node = api.tree.get_node_under_cursor()
  if not node then return end
  -- 根目錄列與 ".." 上層列交回預設行為
  if node.name == ".." or node.absolute_path == nil then
    api.node.open.edit()
    return
  end
  if node.type == "directory" then
    api.node.open.edit()
    return
  end
  if vim.fn.FridIsImage(node.absolute_path) == 1 then
    vim.fn.FridOpenExternal(node.absolute_path)
    return
  end
  api.node.open.edit()
end

local function open_external()
  local node = api.tree.get_node_under_cursor()
  if not node or not node.absolute_path then return end
  vim.fn.FridOpenExternal(node.absolute_path)
end

local function on_attach(bufnr)
  api.config.mappings.default_on_attach(bufnr)
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr,
             noremap = true, silent = true, nowait = true }
  end
  vim.keymap.set("n", "<CR>",           smart_enter,  opts("智慧開啟"))
  vim.keymap.set("n", "o",              smart_enter,  opts("智慧開啟"))
  vim.keymap.set("n", "<2-LeftMouse>",  smart_enter,  opts("智慧開啟"))
  vim.keymap.set("n", "gx",             open_external, opts("以外部程式開啟"))
end

require("nvim-tree").setup({
  on_attach = on_attach,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  respect_buf_cwd = true,
  update_focused_file = { enable = true, update_root = false },
  view = {
    width = 36,
    preserve_window_proportions = true,
  },
  renderer = {
    group_empty = true,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      git_placement = "after",
      show = { file = true, folder = true, folder_arrow = true, git = true },
    },
  },
  -- 隱藏 .git（dotfiles 本身仍顯示）
  filters = { dotfiles = false, custom = { "^.git$" } },
  git = { enable = true, ignore = false, timeout = 1000 },
  actions = {
    open_file = {
      quit_on_open = false,
      resize_window = false,
      window_picker = { enable = false },
    },
  },
})
EOF

" reload file on changed externally
"
set autoread

augroup auto_reload_file
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * checktime
augroup END


" bufferline (Tab)
" bufferline（Tab）
lua << EOF
local bufremove = require("mini.bufremove")

bufremove.setup()

require("bufferline").setup({
    options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",

        -- 使用 mini.bufremove 關閉 buffer，避免破壞視窗配置
        close_command = function(bufnr)
            bufremove.delete(bufnr, false)
        end,

        right_mouse_command = function(bufnr)
            bufremove.delete(bufnr, false)
        end,

        middle_mouse_command = function(bufnr)
            bufremove.delete(bufnr, false)
        end,

        -- 顯示設定
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        always_show_bufferline = true,
        separator_style = "thin",

        -- 讓 bufferline 避開左側 nvim-tree
        offsets = {
            {
                filetype = "NvimTree",
                text = "File Explorer",
                text_align = "center",
                separator = true,
            },
        },
    },
})
EOF


" Tab：下一個 buffer
nnoremap <Tab> :BufferLineCycleNext<CR>

" Shift+Tab：上一個 buffer
nnoremap <S-Tab> :BufferLineCyclePrev<CR>

" 關閉目前 buffer
nnoremap <silent> <leader>x <Cmd>lua MiniBufremove.delete(0, false)<CR>

" 移動 buffer 順序
nnoremap <leader>> :BufferLineMoveNext<CR>
nnoremap <leader>< :BufferLineMovePrev<CR>
