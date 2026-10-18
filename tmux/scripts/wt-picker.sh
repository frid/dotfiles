#!/usr/bin/env bash
# 多 worktree tmux 切換器：prefix+g 觸發
# 用呼叫時所在 pane 的目錄判斷是哪個 git repo（不寫死路徑，誰在哪個專案按都能用）。
# 列出該 repo 的 git worktree（含主 worktree，顯示為 master；已合併完成的任務 worktree 不列），選了之後：
#   - 已有對應 window 就切過去
#   - 沒有就新建（上 nvim 滿寬／下右 shell，cd 到該 worktree；下左 claude 開主控台 Agent View）
#
# 分兩段跑：
#   wt-picker.sh <pane 目錄> <client> <client 高度>   由 run-shell 呼叫，算出清單後開「剛好容納清單高度」的 popup
#   wt-picker.sh --pick <清單檔>         在 popup 裡跑 fzf 並切換／建立 window
set -euo pipefail

if [ "${1:-}" = "--pick" ]; then
  list_file="$2"
  trap 'rm -f "$list_file"' EXIT

  sel="$(cut -f1 "$list_file" | fzf --prompt='worktree> ' --no-scrollbar)" || exit 0
  [ -z "$sel" ] && exit 0
  target_path="$(awk -F '\t' -v s="$sel" '$1 == s {print $2; exit}' "$list_file")"
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
  exit 0
fi

pane_dir="${1:-$PWD}"
client="${2:-}"
client_h="${3:-40}"
cd "$pane_dir"

if ! common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
  tmux display-message "wt-picker: 目前目錄不是 git repo"   # 3.2a 的 display-message -c 有 bug（不吃值），不指定 client
  exit 0
fi

# 直接讀 .git/worktrees/*/gitdir 列出 worktree，不用 git worktree list：
# 後者會逐一檢查每個 worktree，在 /mnt/g 這類慢速掛載上一次就要約 0.7 秒。
# gitdir 可能是相對路徑（worktree.useRelativePaths），用 realpath -ms 純字串解析，不碰檔案系統。
# 輸出「路徑<TAB>分支」，主 worktree 排第一。
list_worktrees() {
  printf '%s\t\n' "$(dirname "$common_dir")"
  local d wt_git head
  for d in "$common_dir"/worktrees/*/; do
    [ -f "$d/gitdir" ] || continue
    wt_git="$(<"$d/gitdir")"
    [[ "$wt_git" = /* ]] || wt_git="$(realpath -ms "$d/$wt_git")"
    head="$(<"$d/HEAD")"
    [[ "$head" = "ref: refs/heads/"* ]] && head="${head#ref: refs/heads/}" || head=""
    printf '%s\t%s\n' "$(dirname "$wt_git")" "$head"
  done
}

# 已完成的任務分支：主 worktree 目前分支（如 dev）上
#   1. --no-ff 合併進來的（merge commit 的第二個以後的 parent），或
#   2. fast-forward 進來的（落在 first-parent 主線上、不是 HEAD、且不是 merge commit；
#      dev 上幾乎都是 merge commit，剛從 dev 開出、還沒 commit 的新 worktree 停在 merge commit 上，不會被誤判）
declare -A done_commit branch_tip
while read -r _ _ rest; do
  for c in $rest; do done_commit["$c"]=1; done
done < <(git -C "$common_dir" rev-list --merges --parents HEAD)
main_head="$(git -C "$common_dir" rev-parse HEAD)"
while read -r c; do
  [ "$c" != "$main_head" ] && done_commit["$c"]=1
done < <(git -C "$common_dir" rev-list --first-parent --no-merges HEAD)
while read -r b c; do branch_tip["$b"]="$c"; done \
  < <(git -C "$common_dir" for-each-ref --format='%(refname:short) %(objectname)' refs/heads)

list_file="$(mktemp "${TMPDIR:-/tmp}/wt-picker.XXXXXX")"
n=0
first=1
while IFS=$'\t' read -r p b; do
  if [ "$first" = 1 ]; then
    name="master"   # 清單第一筆固定是主 worktree，統一顯示為 master，方便跨專案辨識
    first=0
  else
    tip="${branch_tip[$b]:-}"
    [ -n "$tip" ] && [ -n "${done_commit[$tip]:-}" ] && continue
    name="$(basename "$p")"
  fi
  printf '%s\t%s\n' "$name" "$p" >> "$list_file"
  n=$((n + 1))
done < <(list_worktrees)

# popup 高度＝清單筆數＋ fzf 資訊列與提示列（2）＋上下框線（2），最多到畫面 80%
max_h=$((client_h * 80 / 100))
h=$((n + 4))
[ "$h" -gt "$max_h" ] && h="$max_h"

tmux display-popup ${client:+-c "$client"} -E -d "$pane_dir" -w 40% -h "$h" \
  "$(printf '%q --pick %q' "$0" "$list_file")"
