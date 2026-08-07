# 多 worktree 開發環境（tmux + nvim + Claude Code）

在同一個 git repo 下同時開多個 worktree 工作時，用來解決「分不清自己在哪個
worktree」與「每次切換都要手動 cd／開 pane」的一套設定。

## 設計

每個 worktree = 一個 tmux window，window 名稱就是 worktree 目錄名。
每個 window 固定三格：

```
┌─────────────────────────────┐
│  nvim（滿寬）                │
├──────────────┬──────────────┤
│ Agent View   │ shell        │
│ (cca)        │              │
└──────────────┴──────────────┘
```

三格都 cd 到該 worktree，左下自動開該 worktree 的 Claude Code Agent View。

## 指令與快捷鍵

| 用法 | 說明 |
|------|------|
| `prefix + g` | fzf 選 worktree。已開的 window 就切過去，沒開的依上述布局新建 |
| `prefix + &` | 關掉整個 window（& = and，連著好幾格一起關）。worktree 刪除後手動收尾用 |
| `prefix + x` | 只關目前這一格 pane |
| `cca` | 只顯示目前 worktree 的 Agent View |
| `cc-where` | 依 worktree 分組列出所有 Claude Code session |

## 為什麼需要 `cca` / `cc-where`

Claude Code 的 Agent View 清單**不顯示 cwd**，只顯示 session 名稱。
它的 `Ctrl+S`（依目錄分組）是照**共用 `.git` 的專案身份**分組，
所以同一個 repo 底下不同 worktree 的 session 會被歸在一起，分不開。

但 `claude agents --json` 每筆都帶正確的 cwd，`claude agents --cwd <path>`
也能限定範圍。這兩支工具就是把這份資料補回可視層：

- `cca` = `claude agents --cwd $(git rev-parse --show-toplevel)`
  → 每個 worktree 有自己獨立的 Agent View，底下有幾個 session 一目了然
  → **限制**：在主 worktree 執行時，因 worktree 實體位於 `.claude/worktrees/`
    底下，仍會一併列出所有 worktree 的 session（過濾方向是單向的）
- `cc-where` → 一次列出全部 session，依 worktree 分組

其他辨識手段（由外而內，越內層越可靠）：
tmux window 名稱 → session 名稱（可用 Agent View 的 `Ctrl+R` 重新命名）
→ 進去後第一行顯示的 cwd（唯一保證正確的依據）

## 檔案

| 路徑 | 內容 |
|------|------|
| `tmux/scripts/wt-picker.sh` | `prefix+g` 的 worktree 選單與 window 建立邏輯 |
| `tmux/.tmux.conf` | `bind-key g`，用 `-d "#{pane_current_path}"` 傳入呼叫端目錄 |
| `bin/cc-where` | 依 worktree 分組列出 session |
| `zsh/.zshrc` | `cca` 函式、`~/dotfiles/bin` 加入 PATH |

`wt-picker.sh` 不寫死專案路徑，靠呼叫當下 pane 所在目錄判斷是哪個 repo，
所以在任何專案下按 `prefix+g` 都能用。主 worktree 在選單中一律顯示為 `master`。

## 依賴

- `fzf`（`sudo apt install -y fzf`）
- nvim 外掛 `rmagatti/auto-session`：依 cwd 自動存/還原 buffer 與分割視窗。
  tmux-resurrect 只還原 pane 與 cwd，不還原 nvim 內容，這個外掛補上缺口。

## 已知問題

- **舊版 fzf**：`--height=~50%`（自適應高度）是新版語法，fzf 0.29 會直接
  報錯退出，表現為 popup 一閃就消失。本設定用 `--height=50%` 以相容舊版。
- **tmux pane 打不進密碼／Enter 顯示成 `^M`**：該 pane 的終端行規跑掉了，
  在該 pane 執行 `stty sane` 重置；修不好就關掉重開一個 pane。
