#!/usr/bin/env bash
# 多 worktree tmux 切換器：prefix+g 觸發
# 用呼叫時所在 pane 的目錄判斷是哪個 git repo（不寫死路徑，誰在哪個專案按都能用）。
# 列出該 repo 的 git worktree（含主 worktree，顯示為 master），選了之後：
#   - 已有對應 window 就切過去
#   - 沒有就新建（上 nvim 滿寬／下右 shell，cd 到該 worktree；下左 claude 開主控台 Agent View）
set -euo pipefail

if ! common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
  tmux display-message "wt-picker: 目前目錄不是 git repo"
  exit 1
fi

# 直接讀 .git/worktrees/*/gitdir 列出 worktree，不用 git worktree list：
# 後者會逐一檢查每個 worktree，在 /mnt/g 這類慢速掛載上一次就要約 0.7 秒。
# gitdir 可能是相對路徑（worktree.useRelativePaths），用 realpath -ms 純字串解析，不碰檔案系統。
list_worktrees() {
  dirname "$common_dir"
  local f wt_git
  for f in "$common_dir"/worktrees/*/gitdir; do
    [ -f "$f" ] || continue
    wt_git="$(<"$f")"
    [[ "$wt_git" = /* ]] || wt_git="$(realpath -ms "$(dirname "$f")/$wt_git")"
    dirname "$wt_git"
  done
}

declare -A path_of
choices=()
main_path=""
while IFS= read -r p; do
  [ -z "$main_path" ] && main_path="$p"
  base="$(basename "$p")"
  choices+=("$base")
  path_of["$base"]="$p"
done < <(list_worktrees)

# 清單第一筆固定是主 worktree，統一顯示為 master，方便跨專案辨識
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

# 先找本 session 裡已有 pane 停在該 worktree 路徑的 window（例如主 worktree 的 0:claude），有就切過去
existing="$(tmux list-panes -s -F '#{window_index}	#{pane_current_path}' \
  | awk -F '\t' -v p="$target_path" '$2 == p {print $1; exit}')"
if [ -n "$existing" ]; then
  tmux select-window -t ":$existing"
  exit 0
fi

if tmux list-windows -F '#{window_name}' | grep -qx "$win_name"; then
  tmux select-window -t ":=$win_name"
  exit 0
fi

tmux new-window -n "$win_name" -c "$target_path"
tmux split-window -v -t "$win_name" -c "$target_path"
tmux split-window -h -t "${win_name}.1" -c "$target_path"

# 左下 claude pane 開主 repo 的 Agent View（主控台，與 0:claude 相同，看得到所有 session）。
# cca 為 .zshrc 定義的函式，故用 send-keys 讓互動 shell 執行；離開 TUI 後仍是可用的 shell
tmux send-keys -t "${win_name}.1" 'cca' C-m

tmux select-pane -t "${win_name}.0"
