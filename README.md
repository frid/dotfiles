# dotfiles

個人設定檔（neovim + tmux），用符號連結集中管理，跨機同步。

## 內容

| 設定 | repo 路徑 | 連結目標 |
|---|---|---|
| Neovim | `nvim/` | `~/.config/nvim` |
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |

## 新電腦安裝

```bash
git clone https://github.com/frid/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh          # 建立 symlink，既有檔會先備份成 .bak.<timestamp>
```

## 日常同步

設定即真檔在 repo 內，改完直接提交：

```bash
cd ~/dotfiles
git add -A && git commit -m "update: <說明>" && git push
```

其他電腦拉更新：`cd ~/dotfiles && git pull`（symlink 已存在，無需重跑 install）。

## 新增一項設定

1. 把檔案搬進 repo（如 `mv ~/.gitconfig ~/dotfiles/git/.gitconfig`）
2. 在 `install.sh` 加一行 `link "git/.gitconfig" "$HOME/.gitconfig"`
3. 重跑 `./install.sh`
