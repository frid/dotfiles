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


call plug#begin('~/.vim/plugged')

" 狀態列
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" 檔案樹
Plug 'preservim/nerdtree'

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

call plug#end()

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

" NERDTree 快捷鍵
nnoremap <F3> :NERDTreeToggle<CR>
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
let NERDTreeMapActivateNode = 'o'
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

function! FridNERDTreeSmartEnter() abort
  let l:node = g:NERDTreeFileNode.GetSelected()
  let l:path = l:node.path.str()

  if l:node.path.isDirectory
    call l:node.activate({})
    return
  endif

  if FridIsImage(l:path)
    call FridOpenExternal(l:path)
    return
  endif

  call l:node.activate({
        \ 'reuse': 'all',
        \ 'where': 'p',
        \ 'keepopen': !nerdtree#closeTreeOnOpen()
        \ })
endfunction

function! FridNERDTreeOpenExternal() abort
  let l:node = g:NERDTreeFileNode.GetSelected()
  let l:path = l:node.path.str()
  call FridOpenExternal(l:path)
endfunction

augroup FridNERDTreeExternalOpen
  autocmd!
  autocmd FileType nerdtree nnoremap <silent><buffer> <CR> :call FridNERDTreeSmartEnter()<CR>
  autocmd FileType nerdtree nnoremap <silent><buffer> gx :call FridNERDTreeOpenExternal()<CR>
  autocmd FileType nerdtree nnoremap <silent><buffer> <2-LeftMouse> <LeftMouse>:call FridNERDTreeSmartEnter()<CR>
augroup END
