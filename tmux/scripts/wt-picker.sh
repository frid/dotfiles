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

# /mnt/g 這類慢速掛載上每起一個 git 就要 0.1～0.9 秒，所以除了一次 rev-list，其餘都用 bash 內建讀檔，不 fork。

# 往上找 .git 判斷是哪個 repo（代替 git rev-parse --git-common-dir）：
#   .git 是目錄 → 主 worktree；是檔案（gitdir: …）→ 連結 worktree，再讀其 commondir 回到主 repo 的 .git
common_dir=""
d="$pane_dir"
while [ -n "$d" ]; do
  if [ -d "$d/.git" ]; then
    common_dir="$d/.git"
    break
  elif [ -f "$d/.git" ]; then
    read -r _ gd < "$d/.git"
    [[ "$gd" = /* ]] || gd="$d/$gd"
    read -r cd_rel < "$gd/commondir"
    [[ "$cd_rel" = /* ]] && common_dir="$cd_rel" || common_dir="$(realpath -ms "$gd/$cd_rel")"
    break
  fi
  d="${d%/*}"
done
if [ -z "$common_dir" ]; then
  tmux display-message "wt-picker: 目前目錄不是 git repo"   # 3.2a 的 display-message -c 有 bug（不吃值），不指定 client
  exit 0
fi

# 已完成的任務分支：主 worktree 目前分支（如 dev）的 first-parent 主線上
#   1. --no-ff 合併進來的（主線 merge commit 的第二個以後的 parent），或
#   2. fast-forward 進來的（主線上不是 HEAD、且不是 merge commit 的 commit；
#      dev 上幾乎都是 merge commit，剛從 dev 開出、還沒 commit 的新 worktree 停在 merge commit 上，不會被誤判）
# 只看主線：任務分支裡「merge dev 進任務」的 merge 會把 dev 的 commit 當第二 parent，不能算。
# rev-list 丟背景跑，同時讀 worktree 清單。
list_file="$(mktemp "${TMPDIR:-/tmp}/wt-picker.XXXXXX")"
revs_file="$list_file.revs"
git -C "$common_dir" rev-list --first-parent --parents HEAD > "$revs_file" &
revs_pid=$!

# 直接讀 .git/worktrees/*/{gitdir,HEAD}，不用 git worktree list（後者會逐一檢查每個 worktree，慢）。
# gitdir 可能是相對路徑（worktree.useRelativePaths），用 realpath -ms 純字串解析，不碰檔案系統。
wt_paths=("${common_dir%/*}")
wt_branches=("")
for d in "$common_dir"/worktrees/*/; do
  [ -f "$d/gitdir" ] || continue
  read -r wt_git < "$d/gitdir"
  [[ "$wt_git" = /* ]] || wt_git="$(realpath -ms "$d/$wt_git")"
  read -r head < "$d/HEAD"
  [[ "$head" = "ref: refs/heads/"* ]] && head="${head#ref: refs/heads/}" || head=""
  wt_paths+=("${wt_git%/*}")
  wt_branches+=("$head")
done

# 分支 tip：loose ref 檔優先，沒有再查 packed-refs（不起 git for-each-ref）
declare -A packed_tip
if [ -f "$common_dir/packed-refs" ]; then
  while read -r c r; do
    [[ "$r" = refs/heads/* ]] && packed_tip["${r#refs/heads/}"]="$c"
  done < "$common_dir/packed-refs"
fi

wait "$revs_pid" || true
declare -A done_commit
first_line=1
while read -r c p1 rest; do
  if [ -n "$rest" ]; then
    for x in $rest; do done_commit["$x"]=1; done
  elif [ "$first_line" = 0 ]; then
    done_commit["$c"]=1
  fi
  first_line=0
done < "$revs_file"
rm -f "$revs_file"

n=0
for i in "${!wt_paths[@]}"; do
  p="${wt_paths[$i]}"
  b="${wt_branches[$i]}"
  if [ "$i" = 0 ]; then
    name="master"   # 清單第一筆固定是主 worktree，統一顯示為 master，方便跨專案辨識
  else
    tip=""
    if [ -n "$b" ]; then
      if [ -f "$common_dir/refs/heads/$b" ]; then
        read -r tip < "$common_dir/refs/heads/$b"
      else
        tip="${packed_tip[$b]:-}"
      fi
    fi
    [ -n "$tip" ] && [ -n "${done_commit[$tip]:-}" ] && continue
    name="${p##*/}"
  fi
  printf '%s\t%s\n' "$name" "$p" >> "$list_file"
  n=$((n + 1))
done

# popup 高度＝清單筆數＋ fzf 資訊列與提示列（2）＋上下框線（2），最多到畫面 80%
max_h=$((client_h * 80 / 100))
h=$((n + 4))
[ "$h" -gt "$max_h" ] && h="$max_h"

tmux display-popup ${client:+-c "$client"} -E -d "$pane_dir" -w 40% -h "$h" \
  "$(printf '%q --pick %q' "$0" "$list_file")"
