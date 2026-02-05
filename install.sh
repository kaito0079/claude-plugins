#!/usr/bin/env bash
set -euo pipefail

# claude-tools インストーラー
# シンボリックリンクを作成して ~/.claude/skills/ と ~/.claude-worktrees.sh を設定

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
WORKTREES_SH="$SCRIPT_DIR/claude-worktrees.sh"

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

usage() {
    cat <<'USAGE'
claude-tools インストーラー

使用方法:
  install.sh              シンボリックリンクを作成
  install.sh --uninstall  シンボリックリンクを削除
  install.sh --status     現在の状態を表示
  install.sh -h|--help    ヘルプを表示
USAGE
}

install() {
    echo "=== claude-tools インストール ==="
    echo "ソース: $SCRIPT_DIR"
    echo ""

    # ~/.claude/skills/ を作成
    mkdir -p "$CLAUDE_SKILLS_DIR"

    # スキルのシンボリックリンク
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name="$(basename "$skill_dir")"
        local target="$CLAUDE_SKILLS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[更新] $name"
            rm "$target"
        elif [ -d "$target" ]; then
            echo "[スキップ] $name (実ディレクトリが存在。手動で削除してください)"
            continue
        else
            echo "[作成] $name"
        fi

        ln -s "$skill_dir" "$target"
    done

    # claude-worktrees.sh のシンボリックリンク
    local wt_target="$HOME/.claude-worktrees.sh"
    if [ -L "$wt_target" ]; then
        echo "[更新] claude-worktrees.sh"
        rm "$wt_target"
    elif [ -f "$wt_target" ]; then
        echo "[バックアップ] 既存の ~/.claude-worktrees.sh → ~/.claude-worktrees.sh.bak"
        mv "$wt_target" "${wt_target}.bak"
    else
        echo "[作成] claude-worktrees.sh"
    fi
    ln -s "$WORKTREES_SH" "$wt_target"

    echo ""
    echo "=== 完了 ==="
    echo ""

    # ~/.zshrc に source があるか確認
    if grep -q 'claude-worktrees.sh' "$HOME/.zshrc" 2>/dev/null; then
        echo "~/.zshrc に source 済み"
    else
        echo "以下を ~/.zshrc に追加してください:"
        echo "  source ~/.claude-worktrees.sh"
    fi
}

uninstall() {
    echo "=== claude-tools アンインストール ==="

    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name="$(basename "$skill_dir")"
        local target="$CLAUDE_SKILLS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[削除] $name"
            rm "$target"
        fi
    done

    local wt_target="$HOME/.claude-worktrees.sh"
    if [ -L "$wt_target" ]; then
        echo "[削除] claude-worktrees.sh"
        rm "$wt_target"
    fi

    echo ""
    echo "=== 完了 ==="
}

status() {
    echo "=== claude-tools 状態 ==="
    echo ""

    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name="$(basename "$skill_dir")"
        local target="$CLAUDE_SKILLS_DIR/$name"

        if [ -L "$target" ]; then
            echo "  $name: $(readlink "$target")"
        elif [ -d "$target" ]; then
            echo "  $name: 実ディレクトリ (リンクではない)"
        else
            echo "  $name: 未インストール"
        fi
    done

    local wt_target="$HOME/.claude-worktrees.sh"
    if [ -L "$wt_target" ]; then
        echo "  worktrees: $(readlink "$wt_target")"
    elif [ -f "$wt_target" ]; then
        echo "  worktrees: 実ファイル (リンクではない)"
    else
        echo "  worktrees: 未インストール"
    fi
}

case "${1:-}" in
    --uninstall) uninstall ;;
    --status)    status ;;
    -h|--help)   usage ;;
    "")          install ;;
    *)           echo "不明なオプション: $1"; usage; exit 1 ;;
esac
