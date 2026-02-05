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
#   claude-worktree register     現在のプロジェクトを zuse に登録
#   claude-worktree remove       worktree を削除
#   claude-worktree status       worktree の状態を表示
#
#   zuse                登録済みプロジェクト一覧
#   zuse <project>      プロジェクトを切り替え
#   za / zb / zc        各 worktree に移動
#   z0                  プロジェクトルートに移動

CLAUDE_WT_CONFIG_DIR="$HOME/.claude-worktrees.d"
mkdir -p "$CLAUDE_WT_CONFIG_DIR"

# --- 状態変数 ---
export CLAUDE_WT_ACTIVE=""
export CLAUDE_WT_ROOT=""
export CLAUDE_WT_A=""
export CLAUDE_WT_B=""
export CLAUDE_WT_C=""

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
        work_base="$project_root/.worktrees"
    fi

    case "$subcmd" in
        init)
            echo "=== Worktree 作成: $project_name ==="
            echo "プロジェクト: $project_root"
            echo "作成先: $work_base/"
            echo ""

            # .worktrees ディレクトリを作成
            mkdir -p "$work_base"

            # .gitignore に .worktrees/ を追加
            local gitignore="$project_root/.gitignore"
            if [ ! -f "$gitignore" ] || ! grep -qx '\.worktrees/' "$gitignore" 2>/dev/null; then
                echo '.worktrees/' >> "$gitignore"
                echo "[.gitignore] .worktrees/ を追加しました"
            fi

            local suffixes=("a" "b" "c")
            for s in "${suffixes[@]}"; do
                local dir="wt-${s}"
                local branch="${project_name}/wt-${s}"
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
            read -p "zuse に登録しますか？ [Y/n]: " answer
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
export CLAUDE_WT_A="$work_base/wt-a"
export CLAUDE_WT_B="$work_base/wt-b"
export CLAUDE_WT_C="$work_base/wt-c"
EOF
            echo "$project_name" > "$CLAUDE_WT_CONFIG_DIR/.last"
            echo "'$project_name' を登録しました"
            echo "使い方: zuse $project_name"
            ;;

        remove)
            echo "=== Worktree 削除: $project_name ==="
            local suffixes=("a" "b" "c")
            for s in "${suffixes[@]}"; do
                local dir="wt-${s}"
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
            local suffixes=("a" "b" "c")
            for s in "${suffixes[@]}"; do
                local dir="wt-${s}"
                local wt_path="$work_base/$dir"
                if [ -d "$wt_path" ]; then
                    local br
                    br=$(git -C "$wt_path" branch --show-current 2>/dev/null || echo "detached")
                    echo "  z$s ($dir): $br"
                else
                    echo "  z$s ($dir): 未作成"
                fi
            done
            ;;

        help|*)
            cat <<'HELP'
claude-worktree - Git Worktree セットアップ

使い方（プロジェクトディレクトリ内で実行）:
  claude-worktree init       worktree を作成（a/b/c の3つ）
  claude-worktree register   プロジェクトを zuse に登録
  claude-worktree remove     worktree を削除
  claude-worktree status     worktree の状態を表示

初回セットアップ:
  cd /path/to/project
  claude-worktree init
  claude-worktree register

以降:
  zuse <project>   プロジェクトを切り替え
  za / zb / zc     各 worktree に移動
HELP
            ;;
    esac
}

# --- プロジェクト切り替え ---
zuse() {
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
    zinfo
}

# --- ナビゲーション ---
za() { [ -n "$CLAUDE_WT_A" ] && cd "$CLAUDE_WT_A" || echo "zuse <project> を先に実行"; }
zb() { [ -n "$CLAUDE_WT_B" ] && cd "$CLAUDE_WT_B" || echo "zuse <project> を先に実行"; }
zc() { [ -n "$CLAUDE_WT_C" ] && cd "$CLAUDE_WT_C" || echo "zuse <project> を先に実行"; }
z0() { [ -n "$CLAUDE_WT_ROOT" ] && cd "$CLAUDE_WT_ROOT" || echo "zuse <project> を先に実行"; }

# --- Claude Code 起動 ---
cdev() { za && claude; }
crev() { zb && claude; }
cana() { zc && claude; }

# --- ユーティリティ ---
zs() {
    [ -n "$CLAUDE_WT_ROOT" ] && git -C "$CLAUDE_WT_ROOT" worktree list || echo "zuse <project> を先に実行"
}

zswitch() {
    local target="$1" branch="$2"
    if [ -z "$target" ] || [ -z "$branch" ]; then
        echo "Usage: zswitch <a|b|c> <branch>"
        return 1
    fi
    case "$target" in
        a) [ -n "$CLAUDE_WT_A" ] && (cd "$CLAUDE_WT_A" && git checkout "$branch") ;;
        b) [ -n "$CLAUDE_WT_B" ] && (cd "$CLAUDE_WT_B" && git checkout "$branch") ;;
        c) [ -n "$CLAUDE_WT_C" ] && (cd "$CLAUDE_WT_C" && git checkout "$branch") ;;
        *) echo "Usage: zswitch <a|b|c> <branch>"; return 1 ;;
    esac
}

zinfo() {
    if [ -z "$CLAUDE_WT_ACTIVE" ]; then
        echo "zuse <project> を先に実行"
        return
    fi
    echo "=== $CLAUDE_WT_ACTIVE ==="
    echo "  z0 : $CLAUDE_WT_ROOT"
    local d k
    for k in za zb zc; do
        case "$k" in
            za) d="$CLAUDE_WT_A" ;;
            zb) d="$CLAUDE_WT_B" ;;
            zc) d="$CLAUDE_WT_C" ;;
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

_zuse_completions() {
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

_zswitch_completions() {
    if [ -n "$ZSH_VERSION" ]; then
        case "$((CURRENT - 1))" in
            1) _arguments '1:worktree:(a b c)' ;;
            2) local branches; branches=($(git -C "$CLAUDE_WT_ROOT" branch --format='%(refname:short)' 2>/dev/null))
               _arguments "2:branch:(${branches[*]})" ;;
        esac
    elif [ -n "$BASH_VERSION" ]; then
        local cur="${COMP_WORDS[COMP_CWORD]}"
        case "$COMP_CWORD" in
            1) COMPREPLY=($(compgen -W "a b c" -- "$cur")) ;;
            2) local branches; branches=$(git -C "$CLAUDE_WT_ROOT" branch --format='%(refname:short)' 2>/dev/null)
               COMPREPLY=($(compgen -W "$branches" -- "$cur")) ;;
        esac
    fi
}

if [ -n "$ZSH_VERSION" ]; then
    compdef _claude_worktree_completions claude-worktree
    compdef _zuse_completions zuse
    compdef _zswitch_completions zswitch
elif [ -n "$BASH_VERSION" ]; then
    complete -F _claude_worktree_completions claude-worktree
    complete -F _zuse_completions zuse
    complete -F _zswitch_completions zswitch
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
