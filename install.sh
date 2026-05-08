#!/usr/bin/env bash
set -euo pipefail

# claude-tools インストーラー
# シンボリックリンクを作成して ~/.claude/skills/, ~/.claude/agents/ を設定

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
AGENTS_DIR="$SCRIPT_DIR/agents"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
STATUSLINE_SH="$SCRIPT_DIR/status-line.sh"

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"
LOCAL_BIN_DIR="$HOME/.local/bin"

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

    # ~/.claude/skills/ と ~/.claude/agents/ を作成
    mkdir -p "$CLAUDE_SKILLS_DIR"
    mkdir -p "$CLAUDE_AGENTS_DIR"

    # スキルのシンボリックリンク
    echo "--- Skills ---"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name="$(basename "$skill_dir")"
        local target="$CLAUDE_SKILLS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[更新] skills/$name"
            rm "$target"
        elif [ -d "$target" ]; then
            echo "[スキップ] skills/$name (実ディレクトリが存在。手動で削除してください)"
            continue
        else
            echo "[作成] skills/$name"
        fi

        ln -s "$skill_dir" "$target"
    done

    # エージェントのシンボリックリンク
    echo "--- Agents ---"
    for agent_file in "$AGENTS_DIR"/*.md; do
        [ -f "$agent_file" ] || continue
        local name
        name="$(basename "$agent_file")"
        local target="$CLAUDE_AGENTS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[更新] agents/$name"
            rm "$target"
        elif [ -f "$target" ]; then
            echo "[スキップ] agents/$name (実ファイルが存在。手動で削除してください)"
            continue
        else
            echo "[作成] agents/$name"
        fi

        ln -s "$agent_file" "$target"
    done

    # statusline.sh のシンボリックリンク
    echo "--- Status Line ---"
    local sl_target="$HOME/.claude/statusline.sh"
    if [ -L "$sl_target" ]; then
        echo "[更新] statusline.sh"
        rm "$sl_target"
    elif [ -f "$sl_target" ]; then
        echo "[バックアップ] 既存の ~/.claude/statusline.sh → ~/.claude/statusline.sh.bak"
        mv "$sl_target" "${sl_target}.bak"
    else
        echo "[作成] statusline.sh"
    fi
    ln -s "$STATUSLINE_SH" "$sl_target"

    # scripts/ のシンボリックリンク (~/.local/bin/ に配置、拡張子を除去したコマンド名)
    if [ -d "$SCRIPTS_DIR" ]; then
        echo "--- Scripts ---"
        mkdir -p "$LOCAL_BIN_DIR"
        for script_file in "$SCRIPTS_DIR"/*; do
            [ -f "$script_file" ] || continue
            [ -x "$script_file" ] || continue
            local script_basename
            script_basename="$(basename "$script_file")"
            # README などのドキュメントは除外
            case "$script_basename" in
                README*|*.md) continue ;;
            esac
            # 拡張子を除去 (claude-bash-stats.py → claude-bash-stats)
            local cmd_name="${script_basename%.*}"
            local target="$LOCAL_BIN_DIR/$cmd_name"

            if [ -L "$target" ]; then
                echo "[更新] scripts/$cmd_name"
                rm "$target"
            elif [ -e "$target" ]; then
                echo "[スキップ] scripts/$cmd_name (実ファイルが存在。手動で削除してください)"
                continue
            else
                echo "[作成] scripts/$cmd_name"
            fi

            ln -s "$script_file" "$target"
        done

        # PATH チェック
        case ":$PATH:" in
            *":$LOCAL_BIN_DIR:"*) ;;
            *) echo "[ヒント] $LOCAL_BIN_DIR が PATH にありません。~/.zshrc 等に追加してください:"
               echo "         export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
        esac
    fi

    echo ""
    echo "=== 完了 ==="
}

uninstall() {
    echo "=== claude-tools アンインストール ==="

    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name="$(basename "$skill_dir")"
        local target="$CLAUDE_SKILLS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[削除] skills/$name"
            rm "$target"
        fi
    done

    for agent_file in "$AGENTS_DIR"/*.md; do
        [ -f "$agent_file" ] || continue
        local name
        name="$(basename "$agent_file")"
        local target="$CLAUDE_AGENTS_DIR/$name"

        if [ -L "$target" ]; then
            echo "[削除] agents/$name"
            rm "$target"
        fi
    done

    local sl_target="$HOME/.claude/statusline.sh"
    if [ -L "$sl_target" ]; then
        echo "[削除] statusline.sh"
        rm "$sl_target"
    fi

    if [ -d "$SCRIPTS_DIR" ]; then
        for script_file in "$SCRIPTS_DIR"/*; do
            [ -f "$script_file" ] || continue
            local script_basename
            script_basename="$(basename "$script_file")"
            case "$script_basename" in
                README*|*.md) continue ;;
            esac
            local cmd_name="${script_basename%.*}"
            local target="$LOCAL_BIN_DIR/$cmd_name"

            if [ -L "$target" ]; then
                echo "[削除] scripts/$cmd_name"
                rm "$target"
            fi
        done
    fi

    echo ""
    echo "=== 完了 ==="
}

status() {
    echo "=== claude-tools 状態 ==="

    echo ""
    echo "--- Skills ---"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
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

    echo ""
    echo "--- Agents ---"
    for agent_file in "$AGENTS_DIR"/*.md; do
        [ -f "$agent_file" ] || continue
        local name
        name="$(basename "$agent_file" .md)"
        local target="$CLAUDE_AGENTS_DIR/$name.md"

        if [ -L "$target" ]; then
            echo "  $name: $(readlink "$target")"
        elif [ -f "$target" ]; then
            echo "  $name: 実ファイル (リンクではない)"
        else
            echo "  $name: 未インストール"
        fi
    done

    echo ""
    echo "--- Status Line ---"
    local sl_target="$HOME/.claude/statusline.sh"
    if [ -L "$sl_target" ]; then
        echo "  statusline: $(readlink "$sl_target")"
    elif [ -f "$sl_target" ]; then
        echo "  statusline: 実ファイル (リンクではない)"
    else
        echo "  statusline: 未インストール"
    fi

    if [ -d "$SCRIPTS_DIR" ]; then
        echo ""
        echo "--- Scripts ---"
        for script_file in "$SCRIPTS_DIR"/*; do
            [ -f "$script_file" ] || continue
            local script_basename
            script_basename="$(basename "$script_file")"
            case "$script_basename" in
                README*|*.md) continue ;;
            esac
            local cmd_name="${script_basename%.*}"
            local target="$LOCAL_BIN_DIR/$cmd_name"

            if [ -L "$target" ]; then
                echo "  $cmd_name: $(readlink "$target")"
            elif [ -e "$target" ]; then
                echo "  $cmd_name: 実ファイル (リンクではない)"
            else
                echo "  $cmd_name: 未インストール"
            fi
        done
    fi
}

case "${1:-}" in
    --uninstall) uninstall ;;
    --status)    status ;;
    -h|--help)   usage ;;
    "")          install ;;
    *)           echo "不明なオプション: $1"; usage; exit 1 ;;
esac
