#!/usr/bin/env bash
set -euo pipefail

# claude-tools インストーラー
# シンボリックリンクを作成して ~/.claude/skills/, ~/.claude/agents/ を設定

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
AGENTS_DIR="$SCRIPT_DIR/agents"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
HOOKS_DIR="$SCRIPT_DIR/hooks"
STATUSLINE_SH="$SCRIPT_DIR/status-line.sh"

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
LOCAL_BIN_DIR="$HOME/.local/bin"

usage() {
    cat <<'USAGE'
claude-tools インストーラー

使用方法:
  install.sh                  シンボリックリンクを作成
  install.sh --enable-hooks   ~/.claude/settings.json に自動改善 hook を登録
  install.sh --disable-hooks  上記 hook を settings.json から削除
  install.sh --uninstall      シンボリックリンクを削除
  install.sh --status         現在の状態を表示
  install.sh -h|--help        ヘルプを表示
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

    # フックスクリプトのシンボリックリンク
    if [ -d "$HOOKS_DIR" ]; then
        echo "--- Hooks ---"
        mkdir -p "$CLAUDE_HOOKS_DIR"
        for hook_file in "$HOOKS_DIR"/*.py; do
            [ -f "$hook_file" ] || continue
            local hook_name
            hook_name="$(basename "$hook_file")"
            local target="$CLAUDE_HOOKS_DIR/$hook_name"

            if [ -L "$target" ]; then
                echo "[更新] hooks/$hook_name"
                rm "$target"
            elif [ -f "$target" ]; then
                echo "[スキップ] hooks/$hook_name (実ファイルが存在。手動で削除してください)"
                continue
            else
                echo "[作成] hooks/$hook_name"
            fi

            ln -s "$hook_file" "$target"
        done
        echo "[ヒント] settings.json への hook 登録は './install.sh --enable-hooks' で実行可能"
    fi

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

enable_hooks() {
    echo "=== auto-improvement hook 登録 ==="
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        echo "[作成] $CLAUDE_SETTINGS"
        echo "{}" > "$CLAUDE_SETTINGS"
    fi

    local backup="${CLAUDE_SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$CLAUDE_SETTINGS" "$backup"
    echo "[バックアップ] $backup"

    SETTINGS="$CLAUDE_SETTINGS" python3 - <<'PY'
import json, os, sys, pathlib
path = pathlib.Path(os.environ["SETTINGS"])
data = json.loads(path.read_text() or "{}")
hooks = data.setdefault("hooks", {})

def ensure_matcher(event_name, command):
    arr = hooks.setdefault(event_name, [])
    for grp in arr:
        for h in grp.get("hooks", []):
            if h.get("type") == "command" and h.get("command") == command:
                return False
    arr.append({"hooks": [{"type": "command", "command": command}]})
    return True

added = []
if ensure_matcher("Stop", "python3 ~/.claude/hooks/session_end_transcript_mirror.py"):
    added.append("Stop -> session_end_transcript_mirror.py")

path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
if added:
    print("[追加] " + "\n[追加] ".join(added))
else:
    print("[既存] hook は既に登録済み")
PY
    echo "=== 完了 ==="
}

disable_hooks() {
    echo "=== auto-improvement hook 削除 ==="
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        echo "settings.json なし"
        return
    fi
    local backup="${CLAUDE_SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$CLAUDE_SETTINGS" "$backup"
    echo "[バックアップ] $backup"

    SETTINGS="$CLAUDE_SETTINGS" python3 - <<'PY'
import json, os, pathlib
path = pathlib.Path(os.environ["SETTINGS"])
data = json.loads(path.read_text() or "{}")
hooks = data.get("hooks", {})
removed = []
for event, command in [
    ("Stop", "python3 ~/.claude/hooks/session_end_transcript_mirror.py"),
]:
    arr = hooks.get(event, [])
    new = []
    for grp in arr:
        kept = [h for h in grp.get("hooks", []) if not (h.get("type") == "command" and h.get("command") == command)]
        if kept:
            grp["hooks"] = kept
            new.append(grp)
        else:
            removed.append(f"{event} -> {command.split('/')[-1]}")
    if new:
        hooks[event] = new
    elif event in hooks:
        del hooks[event]
data["hooks"] = hooks
if not data["hooks"]:
    del data["hooks"]
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print("[削除] " + ", ".join(removed) if removed else "[該当なし]")
PY
    echo "=== 完了 ==="
}

uninstall() {
    echo "=== claude-tools アンインストール ==="

    if [ -d "$CLAUDE_HOOKS_DIR" ]; then
        for hook_file in "$HOOKS_DIR"/*.py; do
            [ -f "$hook_file" ] || continue
            local hook_name
            hook_name="$(basename "$hook_file")"
            local target="$CLAUDE_HOOKS_DIR/$hook_name"
            if [ -L "$target" ]; then
                echo "[削除] hooks/$hook_name"
                rm "$target"
            fi
        done
    fi

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

    if [ -d "$HOOKS_DIR" ]; then
        echo ""
        echo "--- Hooks ---"
        for hook_file in "$HOOKS_DIR"/*.py; do
            [ -f "$hook_file" ] || continue
            local hook_name
            hook_name="$(basename "$hook_file")"
            local target="$CLAUDE_HOOKS_DIR/$hook_name"

            if [ -L "$target" ]; then
                echo "  $hook_name: $(readlink "$target")"
            elif [ -f "$target" ]; then
                echo "  $hook_name: 実ファイル (リンクではない)"
            else
                echo "  $hook_name: 未インストール"
            fi
        done
        if [ -f "$CLAUDE_SETTINGS" ]; then
            local hook_count
            hook_count=$(SETTINGS="$CLAUDE_SETTINGS" python3 -c "
import json,os
d=json.loads(open(os.environ['SETTINGS']).read() or '{}')
n=0
for ev,arr in (d.get('hooks') or {}).items():
    for g in arr:
        for h in g.get('hooks',[]):
            cmd=h.get('command','')
            if 'session_end_transcript_mirror.py' in cmd:
                n+=1
print(n)" 2>/dev/null || echo 0)
            echo "  (settings.json 登録済み: $hook_count 件)"
        fi
    fi

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
    --uninstall)      uninstall ;;
    --enable-hooks)   enable_hooks ;;
    --disable-hooks)  disable_hooks ;;
    --status)         status ;;
    -h|--help)        usage ;;
    "")               install ;;
    *)                echo "不明なオプション: $1"; usage; exit 1 ;;
esac
