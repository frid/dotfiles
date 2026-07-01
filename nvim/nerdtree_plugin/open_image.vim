" 已停用：智慧開啟（圖片外部開啟、其餘正常開啟）統一由 init.vim 的
" FridNERDTreeSmartEnter() + FileType nerdtree <CR> autocmd 處理。
"
" 先前此檔同時定義了單參數版 FridNERDTreeSmartEnter(node) 並用 NERDTreeAddKeyMap
" 註冊 <CR>，與 init.vim 的無參數版衝突，造成：
"   1. function! 覆蓋 → init.vim 的 :call FridNERDTreeSmartEnter() 報 E119（參數不足）
"   2. 移除 init.vim 版後，NERDTreeAddKeyMap 的 override 未能蓋掉預設 <CR>，
"      導致圖片被以二進位載入 buffer。
" 為避免雙重來源，整個 plugin 內容停用，保持空檔。
finish
