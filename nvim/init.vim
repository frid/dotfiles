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

" 模糊搜尋（2026-08-10 由 fzf.vim 換成 fzf-lua：原生支援 devicons、鍵位可重綁）
" junegunn/fzf 保留：fzf-lua 仍需要 fzf 本體執行檔
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'ibhagwan/fzf-lua'

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

" ── fzf-lua ──────────────────────────────────────────────────────────────
" 圖示走 nvim-web-devicons（與 nvim-tree 共用，不需額外裝東西）
lua << EOF
local ok, fzf = pcall(require, 'fzf-lua')
if ok then
  -- 系統的 /usr/bin/fzf 是 0.29（apt 套件過舊），fzf-lua 需要 >= 0.36
  -- 改用 vim-plug 裝的 junegunn/fzf 本體，避免撞到 PATH 上的舊版
  local bundled = vim.fn.expand('~/.vim/plugged/fzf/bin/fzf')
  fzf.setup({
    fzf_bin = vim.fn.executable(bundled) == 1 and bundled or nil,
    defaults = {
      file_icons  = true,   -- 檔案類型圖示
      color_icons = true,   -- 圖示依副檔名上色
      -- 圖示與檔名間補一格（預設為空字串，會黏在一起）
      file_icon_padding = ' ',
      -- git_icons 關閉：每開一次 picker 就跑一次 git status，在 /mnt/d（DrvFs +
      -- Google Drive）上要 1 秒以上，開選單會明顯卡住。要看 git 狀態用 \gs。
      git_icons   = false,
    },
    winopts = {
      height  = 0.85,
      width   = 0.85,
      preview = { layout = 'flex', scrollbar = 'float' },
    },
    keymap = {
      builtin = {
        ['<C-d>'] = 'preview-page-down',
        ['<C-u>'] = 'preview-page-up',
      },
    },
    actions = {
      files = {
        ['enter']  = fzf.actions.file_edit_or_qf,
        ['ctrl-x'] = fzf.actions.file_split,
        ['ctrl-s'] = fzf.actions.file_vsplit,   -- 原本是 ctrl-v，避開終端貼上
        ['ctrl-t'] = fzf.actions.file_tabedit,
        ['ctrl-v'] = false,                     -- 讓 ctrl-v 留給 Windows Terminal 貼上
        ['alt-q']  = fzf.actions.file_sel_to_qf,
      },
    },
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
" fzf-lua 快捷鍵
nnoremap <leader>b <Cmd>FzfLua buffers<CR>
nnoremap <leader>h <Cmd>FzfLua oldfiles<CR>
nnoremap <leader>f <Cmd>FzfLua files<CR>
nnoremap <leader>r <Cmd>FzfLua live_grep<CR>
nnoremap <leader>l <Cmd>FzfLua blines<CR>
nnoremap <leader>gs <Cmd>FzfLua git_status<CR>
nnoremap <leader>gf <Cmd>FzfLua git_files<CR>

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
-- ── devicons glyph 降級（Nerd Fonts v2 字型相容）─────────────────────────
-- nvim-web-devicons 已升到 NF v3 字碼，全表 785 項中有 126 項落在
-- U+F0000+（Material Design Icons）區段。NF v2 patch 的字型沒有該區段，
-- .txt／.log／.xlsx 等就顯示成豆腐字（2026-08-07 於 Sarasa Term TC NF 實證：
-- 解該 ttf 的 cmap，U+F0219/F0331/F021B 皆缺，而 U+F48A/E60B 在）。
--
-- 跨機器策略：**預設降級**（v2 與 v3 字型都有的字，任何機器都不會豆腐）；
-- 某台機器確定用 NF v3 字型、想要原生圖示 → 該機器設 `NVIM_NF_V3=1`
-- 環境變數（寫在機器本地的 shell rc，不進 dotfile）即跳過本段。
-- 不確定某台機器的字型是哪一版 → `:NFProbe` 目視比對。
vim.api.nvim_create_user_command("NFProbe", function()
  local n = vim.fn.nr2char
  vim.notify(table.concat({
    "NF v2 區段（應正常）： " .. n(0xF15C) .. " " .. n(0xF1C3) .. " " .. n(0xE60B),
    "NF v3 區段（豆腐＝v2 字型）： " .. n(0xF0219) .. " " .. n(0xF021B) .. " " .. n(0xF0331),
    "上排看得到、下排是空box → 保持預設降級；兩排都正常 → 可設 NVIM_NF_V3=1",
  }, "\n"))
end, { desc = "目視檢查終端機字型是否含 Nerd Fonts v3 字碼" })

if vim.env.NVIM_NF_V3 ~= "1" then
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    -- 用字碼指定，避免私用區字元在編輯／複製時被吃掉
    local g = function(cp) return vim.fn.nr2char(cp) end
    local FILE      = g(0xF15B)  -- nf-fa-file
    local TEXT      = g(0xF15C)  -- nf-fa-file_text
    local CODE      = g(0xF1C9)  -- nf-fa-file_code_o
    local WORD      = g(0xF1C2)  -- nf-fa-file_word_o
    local EXCEL     = g(0xF1C3)  -- nf-fa-file_excel_o
    local PPT       = g(0xF1C4)  -- nf-fa-file_powerpoint_o
    local BOOK      = g(0xF02D)  -- nf-fa-book
    local KEY       = g(0xF084)  -- nf-fa-key（雜湊／簽章）
    local TERMINAL  = g(0xF120)  -- nf-fa-terminal
    local DOCKER    = g(0xF308)  -- nf-linux-docker
    local subs = {
      txt = TEXT, log = TEXT, lrc = TEXT, srt = TEXT, sub = TEXT,
      ssa = TEXT, ass = TEXT, bak = TEXT, m3u = TEXT, ["m3u8"] = TEXT, pls = TEXT,
      doc = WORD, docx = WORD,
      xls = EXCEL, xlsx = EXCEL,
      ppt = PPT,  pptx = PPT,
      xml = CODE, xslt = CODE, xaml = CODE, razor = CODE, cshtml = CODE,
      svg = CODE, svgz = CODE, cs = CODE, csproj = CODE,
      readme = BOOK, ["readme.md"] = BOOK, security = BOOK, ["security.md"] = BOOK,
      md5 = KEY, sha1 = KEY, sha224 = KEY, sha256 = KEY, sha384 = KEY, sha512 = KEY,
      asc = KEY, sig = KEY, signature = KEY, pub = KEY, kbx = KEY,
      ps1 = TERMINAL, psm1 = TERMINAL, psd1 = TERMINAL, tcl = TERMINAL, tbc = TERMINAL,
      Dockerfile = DOCKER, dockerfile = DOCKER, containerfile = DOCKER,
      dockerignore = DOCKER, [".dockerignore"] = DOCKER,
      ["compose.yaml"] = DOCKER, ["compose.yml"] = DOCKER,
      ["docker-compose.yaml"] = DOCKER, ["docker-compose.yml"] = DOCKER,
    }
    local patched = {}
    for name, def in pairs(devicons.get_icons()) do
      if def.icon and vim.fn.char2nr(def.icon) > 0xF0000 then
        patched[name] = vim.tbl_extend("force", {}, def, { icon = subs[name] or FILE })
      end
    end
    if next(patched) then devicons.set_icon(patched) end
  end
end

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
    width = 38,
    preserve_window_proportions = true,
  },
  renderer = {
    group_empty = true,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      git_placement = "after",
      -- icon 與檔名之間留白（預設 " " 太擠，不易閱讀）
      padding = { icon = "  " },
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
        -- 圖示與檔名之間補一格（bufferline 沒有專門的 padding 選項，
        -- 只能從檔名前綴一個空白達成）
        name_formatter = function(buf)
            return " " .. vim.fn.fnamemodify(buf.name, ":t")
        end,
        show_buffer_close_icons = true,
        show_close_icon = true,
        always_show_bufferline = true,
        separator_style = "thin",

        -- icon 與檔名之間多留一格（NF glyph 貼太緊）
        -- bufferline 無獨立間距選項，改在 icon 字串尾端補空白
        get_element_icon = function(element)
            local devicons = require("nvim-web-devicons")
            local icon, hl = devicons.get_icon_by_filetype(
                element.filetype, { default = false })
            if not icon then
                icon, hl = devicons.get_icon(
                    element.path or "", element.extension, { default = true })
            end
            if not icon then return nil end
            return icon .. " ", hl
        end,

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
