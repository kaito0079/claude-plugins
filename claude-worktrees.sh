#!/usr/bin/env bash
# Claude Code Worktree マネージャー
# 複数プロジェクトの worktree をワンキーで切り替え
#
# セットアップ:
#   echo 'source ~/.claude-worktrees.sh' >> ~/.zshrc
#
# 使い方:
#   claude-worktree              ヘルプ表示
#   claude-worktree init         現在のプロジェクトに worktree を作成
#   claude-worktree register     現在のプロジェクトを wtuse に登録
#   claude-worktree remove       worktree を削除
#   claude-worktree status       worktree の状態を表示
#
#   wtuse               登録済みプロジェクト一覧
#   wtuse <project>     プロジェクトを切り替え
#   wt1 / wt2 / wt3     各 worktree に移動
#   wt0                 プロジェクトルートに移動

CLAUDE_WT_CONFIG_DIR="$HOME/.claude-worktrees.d"
mkdir -p "$CLAUDE_WT_CONFIG_DIR"

# --- 状態変数 ---
export CLAUDE_WT_ACTIVE=""
export CLAUDE_WT_ROOT=""
export CLAUDE_WT_1=""
export CLAUDE_WT_2=""
export CLAUDE_WT_3=""

# --- セットアップ: claude-worktree コマンド ---
claude-worktree() {
    local subcmd="${1:-help}"

    # 現在のディレクトリから git プロジェクトを検出
    local project_root project_name work_base
    project_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"

    if [ -z "$project_root" ] && [ "$subcmd" != "help" ]; then
        echo "エラー: git リポジトリ内で実行してください"
        return 1
    fi

    if [ -n "$project_root" ]; then
        project_name="$(basename "$project_root")"
        work_base="$(dirname "$project_root")"
    fi

    case "$subcmd" in
        init)
            echo "=== Worktree 作成: $project_name ==="
            echo "プロジェクト: $project_root"
            echo "作成先: $work_base/"
            echo ""

            local suffixes=("1" "2" "3")
            for s in "${suffixes[@]}"; do
                local dir="${project_name}-wt${s}"
                local branch="${project_name}/wt${s}"
                local wt_path="$work_base/$dir"

                if [ -d "$wt_path" ]; then
                    echo "[スキップ] $dir は既に存在します"
                    continue
                fi

                echo "[作成中] $dir -> $wt_path"

                if ! git -C "$project_root" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
                    git -C "$project_root" branch "$branch" HEAD
                fi

                git -C "$project_root" worktree add "$wt_path" "$branch"
                echo "[完了] $dir"
            done

            echo ""
            read -p "wtuse に登録しますか？ [Y/n]: " answer
            if [[ "$answer" != "n" && "$answer" != "N" ]]; then
                claude-worktree register
            else
                echo "後で登録する場合: claude-worktree register"
            fi
            ;;

        register)
            local config="$CLAUDE_WT_CONFIG_DIR/$project_name.sh"
            cat > "$config" <<EOF
export CLAUDE_WT_ROOT="$project_root"
export CLAUDE_WT_1="$work_base/${project_name}-wt1"
export CLAUDE_WT_2="$work_base/${project_name}-wt2"
export CLAUDE_WT_3="$work_base/${project_name}-wt3"
EOF
            echo "$project_name" > "$CLAUDE_WT_CONFIG_DIR/.last"
            echo "'$project_name' を登録しました"
            echo "使い方: wtuse $project_name"
            ;;

        remove)
            echo "=== Worktree 削除: $project_name ==="
            local suffixes=("1" "2" "3")
            for s in "${suffixes[@]}"; do
                local dir="${project_name}-wt${s}"
                local wt_path="$work_base/$dir"
                if [ -d "$wt_path" ]; then
                    echo "[削除中] $dir"
                    git -C "$project_root" worktree remove "$wt_path" --force
                    echo "[完了]"
                else
                    echo "[スキップ] $dir は存在しません"
                fi
            done
            ;;

        status)
            echo "=== $project_name ==="
            git -C "$project_root" worktree list
            echo ""
            local suffixes=("1" "2" "3")
            for s in "${suffixes[@]}"; do
                local dir="${project_name}-wt${s}"
                local wt_path="$work_base/$dir"
                if [ -d "$wt_path" ]; then
                    local br
                    br=$(git -C "$wt_path" branch --show-current 2>/dev/null || echo "detached")
                    echo "  wt$s ($dir): $br"
                else
                    echo "  wt$s ($dir): 未作成"
                fi
            done
            ;;

        help|*)
            cat <<'HELP'
claude-worktree - Git Worktree セットアップ

使い方（プロジェクトディレクトリ内で実行）:
  claude-worktree init       worktree を作成（1/2/3 の3つ）
  claude-worktree register   プロジェクトを wtuse に登録
  claude-worktree remove     worktree を削除
  claude-worktree status     worktree の状態を表示

初回セットアップ:
  cd /path/to/project
  claude-worktree init
  claude-worktree register

以降:
  wtuse <project>    プロジェクトを切り替え
  wt1 / wt2 / wt3    各 worktree に移動
  wt0                プロジェクトルートに移動
HELP
            ;;
    esac
}

# --- プロジェクト切り替え ---
wtuse() {
    local project="$1"

    if [ -z "$project" ]; then
        echo "=== 登録済みプロジェクト ==="
        local found=0
        for f in "$CLAUDE_WT_CONFIG_DIR"/*.sh; do
            [ -f "$f" ] || continue
            found=1
            local name
            name="$(basename "$f" .sh)"
            if [ "$name" = "$CLAUDE_WT_ACTIVE" ]; then
                echo "  * $name (active)"
            else
                echo "    $name"
            fi
        done
        if [ "$found" -eq 0 ]; then
            echo "  (なし)"
            echo "  cd /path/to/project && claude-worktree init && claude-worktree register"
        fi
        return
    fi

    local config="$CLAUDE_WT_CONFIG_DIR/$project.sh"
    if [ ! -f "$config" ]; then
        echo "未登録: '$project'"
        echo "cd /path/to/$project && claude-worktree init && claude-worktree register"
        return 1
    fi

    source "$config"
    export CLAUDE_WT_ACTIVE="$project"
    echo "$project" > "$CLAUDE_WT_CONFIG_DIR/.last"
    echo "=> $project"
    wtinfo
}

# --- ナビゲーション ---
wt1() { [ -n "$CLAUDE_WT_1" ] && cd "$CLAUDE_WT_1" || echo "wtuse <project> を先に実行"; }
wt2() { [ -n "$CLAUDE_WT_2" ] && cd "$CLAUDE_WT_2" || echo "wtuse <project> を先に実行"; }
wt3() { [ -n "$CLAUDE_WT_3" ] && cd "$CLAUDE_WT_3" || echo "wtuse <project> を先に実行"; }
wt0() { [ -n "$CLAUDE_WT_ROOT" ] && cd "$CLAUDE_WT_ROOT" || echo "wtuse <project> を先に実行"; }

# --- Claude Code 起動 ---
c1() { wt1 && claude; }
c2() { wt2 && claude; }
c3() { wt3 && claude; }

# --- ユーティリティ ---
wts() {
    [ -n "$CLAUDE_WT_ROOT" ] && git -C "$CLAUDE_WT_ROOT" worktree list || echo "wtuse <project> を先に実行"
}

wtswitch() {
    local target="$1" branch="$2"
    if [ -z "$target" ] || [ -z "$branch" ]; then
        echo "Usage: wtswitch <1|2|3> <branch>"
        return 1
    fi
    case "$target" in
        1) [ -n "$CLAUDE_WT_1" ] && (cd "$CLAUDE_WT_1" && git checkout "$branch") ;;
        2) [ -n "$CLAUDE_WT_2" ] && (cd "$CLAUDE_WT_2" && git checkout "$branch") ;;
        3) [ -n "$CLAUDE_WT_3" ] && (cd "$CLAUDE_WT_3" && git checkout "$branch") ;;
        *) echo "Usage: wtswitch <1|2|3> <branch>"; return 1 ;;
    esac
}

wtinfo() {
    if [ -z "$CLAUDE_WT_ACTIVE" ]; then
        echo "wtuse <project> を先に実行"
        return
    fi
    echo "=== $CLAUDE_WT_ACTIVE ==="
    echo "  wt0 : $CLAUDE_WT_ROOT"
    local d k
    for k in wt1 wt2 wt3; do
        case "$k" in
            wt1) d="$CLAUDE_WT_1" ;;
            wt2) d="$CLAUDE_WT_2" ;;
            wt3) d="$CLAUDE_WT_3" ;;
        esac
        if [ -d "$d" ]; then
            echo "  $k : $d ($(git -C "$d" branch --show-current 2>/dev/null || echo 'detached'))"
        else
            echo "  $k : 未作成"
        fi
    done
}

# --- 補完 ---
_claude_worktree_completions() {
    local subcmds="init register remove status help"
    if [ -n "$ZSH_VERSION" ]; then
        _arguments '1:subcommand:(init register remove status help)'
    elif [ -n "$BASH_VERSION" ]; then
        local cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "$subcmds" -- "$cur"))
    fi
}

_wtuse_completions() {
    local projects=()
    for f in "$CLAUDE_WT_CONFIG_DIR"/*.sh; do
        [ -f "$f" ] || continue
        projects+=("$(basename "$f" .sh)")
    done
    if [ -n "$ZSH_VERSION" ]; then
        _arguments "1:project:(${projects[*]})"
    elif [ -n "$BASH_VERSION" ]; then
        local cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "${projects[*]}" -- "$cur"))
    fi
}

_wtswitch_completions() {
    if [ -n "$ZSH_VERSION" ]; then
        case "$((CURRENT - 1))" in
            1) _arguments '1:worktree:(1 2 3)' ;;
            2) local branches; branches=($(git -C "$CLAUDE_WT_ROOT" branch --format='%(refname:short)' 2>/dev/null))
               _arguments "2:branch:(${branches[*]})" ;;
        esac
    elif [ -n "$BASH_VERSION" ]; then
        local cur="${COMP_WORDS[COMP_CWORD]}"
        case "$COMP_CWORD" in
            1) COMPREPLY=($(compgen -W "1 2 3" -- "$cur")) ;;
            2) local branches; branches=$(git -C "$CLAUDE_WT_ROOT" branch --format='%(refname:short)' 2>/dev/null)
               COMPREPLY=($(compgen -W "$branches" -- "$cur")) ;;
        esac
    fi
}

if [ -n "$ZSH_VERSION" ]; then
    compdef _claude_worktree_completions claude-worktree
    compdef _wtuse_completions wtuse
    compdef _wtswitch_completions wtswitch
elif [ -n "$BASH_VERSION" ]; then
    complete -F _claude_worktree_completions claude-worktree
    complete -F _wtuse_completions wtuse
    complete -F _wtswitch_completions wtswitch
fi

# --- 起動時: 最後のプロジェクトを復元 ---
if [ -f "$CLAUDE_WT_CONFIG_DIR/.last" ]; then
    _last="$(cat "$CLAUDE_WT_CONFIG_DIR/.last")"
    if [ -f "$CLAUDE_WT_CONFIG_DIR/$_last.sh" ]; then
        source "$CLAUDE_WT_CONFIG_DIR/$_last.sh"
        export CLAUDE_WT_ACTIVE="$_last"
    fi
    unset _last
fi
