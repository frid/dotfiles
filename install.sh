#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# dotfiles installer — 在本機建立指向此 repo 的符號連結（symlink）
# 新電腦用法：git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh
#
# 特性：既有真檔/連結會先備份成 <name>.bak.<timestamp>，不會直接覆蓋。
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# link <來源(在 repo 內)> <目標(在家目錄)>
link() {
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
      echo "✓ 已連結：$dst"
      return
    fi
    local bak="$dst.bak.$STAMP"
    echo "→ 備份既有 $dst → $bak"
    mv "$dst" "$bak"
  fi
  ln -s "$src" "$dst"
  echo "✓ 建立連結：$dst → $src"
}

# ── 設定對應表：新增設定就加一行 ──────────────────────────────────────────────
link "nvim"            "$HOME/.config/nvim"
link "tmux/.tmux.conf" "$HOME/.tmux.conf"
link "zsh/.zshrc"      "$HOME/.zshrc"

echo
echo "完成。重開 shell 或 tmux（prefix + r 若有設 reload）即可套用。"
