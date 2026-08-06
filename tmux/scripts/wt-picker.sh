#!/usr/bin/env bash
# QMSWeb 多 worktree tmux 切換器：prefix+g 觸發
# 列出 git worktree list（含 master），選了之後：
#   - 已有對應 window 就切過去
#   - 沒有就新建（上 nvim 滿寬／下左 claude／下右 shell，皆 cd 到該 worktree）
set -euo pipefail

REPO="/mnt/d/03CodeResp/QMSWeb"

declare -A path_of
choices=()
while IFS= read -r p; do
  base="$(basename "$p")"
  [ "$p" = "$REPO" ] && base="master"
  path_of["$base"]="$p"
  choices+=("$base")
done < <(git -C "$REPO" worktree list | awk '{print $1}')

sel="$(printf '%s\n' "${choices[@]}" | fzf --prompt='worktree> ' --height=50%)"
[ -z "${sel:-}" ] && exit 0

target_path="${path_of[$sel]}"
win_name="$sel"

if tmux list-windows -F '#{window_name}' | grep -qx "$win_name"; then
  tmux select-window -t ":=$win_name"
  exit 0
fi

tmux new-window -n "$win_name" -c "$target_path"
tmux split-window -v -t "$win_name" -c "$target_path"
tmux split-window -h -t "${win_name}.1" -c "$target_path"
tmux select-pane -t "${win_name}.0"
