#!/usr/bin/env bash
# 多 worktree tmux 切換器：prefix+g 觸發
# 用呼叫時所在 pane 的目錄判斷是哪個 git repo（不寫死路徑，誰在哪個專案按都能用）。
# 列出該 repo 的 git worktree（含主 worktree，顯示為 master），選了之後：
#   - 已有對應 window 就切過去
#   - 沒有就新建（上 nvim 滿寬／下左 claude／下右 shell，皆 cd 到該 worktree）
set -euo pipefail

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  tmux display-message "wt-picker: 目前目錄不是 git repo"
  exit 1
fi

declare -A path_of
choices=()
while IFS= read -r p; do
  base="$(basename "$p")"
  choices+=("$base")
  path_of["$base"]="$p"
done < <(git worktree list --porcelain | awk '/^worktree /{print $2}')

# 清單第一筆固定是主 worktree，統一顯示為 master，方便跨專案辨識
main_path="$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
main_base="$(basename "$main_path")"
if [ "$main_base" != "master" ] && [ -n "${path_of[$main_base]:-}" ]; then
  path_of["master"]="${path_of[$main_base]}"
  unset "path_of[$main_base]"
  for i in "${!choices[@]}"; do
    [ "${choices[$i]}" = "$main_base" ] && choices[$i]="master"
  done
fi

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
