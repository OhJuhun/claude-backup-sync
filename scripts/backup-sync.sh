#!/bin/bash
# backup-sync.sh - Auto-sync Claude Code config to backup repository
# Triggered by Stop hook or backup_sync MCP tool

set -euo pipefail

BACKUP_DIR="$HOME/.claude/backup-sync"
CONFIG_FILE="$BACKUP_DIR/config.json"
LOG_FILE="$BACKUP_DIR/sync.log"
LOCK_FILE="$BACKUP_DIR/sync.lock"

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Prevent concurrent runs
if [[ -f "$LOCK_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0) ))
  else
    LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  fi
  if [[ $LOCK_AGE -lt 120 ]]; then
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

# Check config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  cat <<'MSG'
[backup-sync] Backup repository not configured.

To configure, use the backup_configure MCP tool or run:
  mkdir -p ~/.claude/backup-sync
  cat > ~/.claude/backup-sync/config.json << 'EOF'
  {
    "repo": "your-username/your-backup-repo",
    "branch": "main",
    "gh_host": "github.com"
  }
  EOF

Or in Claude Code: "/backup-setup"
MSG
  exit 0
fi

# Read config
REPO=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['repo'])" 2>/dev/null)
BRANCH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('branch', 'main'))" 2>/dev/null)
GH_HOST=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('gh_host', 'github.com'))" 2>/dev/null)

if [[ -z "$REPO" ]]; then
  log "ERROR: repo not set in config"
  exit 1
fi

CLONE_DIR="$BACKUP_DIR/repo"

# Clone if not exists
if [[ ! -d "$CLONE_DIR/.git" ]]; then
  log "Cloning $REPO..."
  GH_HOST="$GH_HOST" gh repo clone "$REPO" "$CLONE_DIR" -- -b "$BRANCH" 2>> "$LOG_FILE"
  if [[ $? -ne 0 ]]; then
    log "ERROR: Failed to clone $REPO"
    exit 1
  fi
  log "Cloned successfully"
fi

# Pull latest
git -C "$CLONE_DIR" pull --rebase origin "$BRANCH" >> "$LOG_FILE" 2>&1 || true

# --- Sync files ---

CLAUDE_DIR="$HOME/.claude"

# Ensure target directories exist
mkdir -p "$CLONE_DIR/claude"

# Claude Code config files
cp "$CLAUDE_DIR/settings.json" "$CLONE_DIR/claude/settings.json" 2>/dev/null || true
cp "$CLAUDE_DIR/settings.local.json" "$CLONE_DIR/claude/settings.local.json" 2>/dev/null || true
cp "$CLAUDE_DIR/CLAUDE.md" "$CLONE_DIR/claude/CLAUDE.md" 2>/dev/null || true

# MCP config - replace hardcoded API keys with env var references
if [[ -f "$CLAUDE_DIR/.mcp.json" ]]; then
  python3 -c "
import json, re, os

with open('$CLAUDE_DIR/.mcp.json') as f:
    data = json.load(f)

# Walk through all env values and replace hardcoded keys with env var refs
for server in data.get('mcpServers', {}).values():
    env = server.get('env', {})
    for key, val in env.items():
        if not val.startswith('\${') and len(val) > 20:
            env[key] = '\${' + key + '}'

with open('$CLONE_DIR/claude/.mcp.json', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>> "$LOG_FILE"
fi

# Agents, rules, commands
for dir in agents rules commands; do
  if [[ -d "$CLAUDE_DIR/$dir" ]]; then
    mkdir -p "$CLONE_DIR/claude/$dir"
    cp "$CLAUDE_DIR/$dir/"*.md "$CLONE_DIR/claude/$dir/" 2>/dev/null || true
  fi
done

# Skills (recursive)
if [[ -d "$CLAUDE_DIR/skills" ]]; then
  mkdir -p "$CLONE_DIR/claude/skills"
  cp -r "$CLAUDE_DIR/skills/"* "$CLONE_DIR/claude/skills/" 2>/dev/null || true
fi

# HUD
if [[ -d "$CLAUDE_DIR/hud" ]]; then
  mkdir -p "$CLONE_DIR/claude/hud"
  cp "$CLAUDE_DIR/hud/"* "$CLONE_DIR/claude/hud/" 2>/dev/null || true
fi

# Scripts (exclude backup-config.json which is now in backup-sync dir)
if [[ -d "$CLAUDE_DIR/scripts" ]]; then
  mkdir -p "$CLONE_DIR/claude/scripts"
  for f in "$CLAUDE_DIR/scripts/"*; do
    fname=$(basename "$f")
    [[ "$fname" == "backup-config.json" ]] && continue
    cp "$f" "$CLONE_DIR/claude/scripts/$fname" 2>/dev/null || true
  done
fi

# Dotfiles
cp "$HOME/.zshrc" "$CLONE_DIR/.zshrc" 2>/dev/null || true
cp "$HOME/.gitconfig" "$CLONE_DIR/.gitconfig" 2>/dev/null || true
cp "$HOME/.ssh/config" "$CLONE_DIR/.ssh_config" 2>/dev/null || true

# Brewfile
brew bundle dump --file="$CLONE_DIR/Brewfile" --force 2>/dev/null || true

# --- Check for changes ---

cd "$CLONE_DIR"

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  log "No changes detected. Skipping push."
  exit 0
fi

# --- Commit and push ---

CHANGED_FILES=$(git diff --name-only; git ls-files --others --exclude-standard)
CHANGE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

log "Detected ${CHANGE_COUNT} changed file(s)"

git add -A
git commit -m "$(cat <<EOF
chore: auto-sync config ($(date '+%Y-%m-%d %H:%M'))

Changed files:
$(echo "$CHANGED_FILES" | head -10)
$([ "$CHANGE_COUNT" -gt 10 ] && echo "... and $((CHANGE_COUNT - 10)) more")
EOF
)" >> "$LOG_FILE" 2>&1

GH_HOST="$GH_HOST" git push origin "$BRANCH" >> "$LOG_FILE" 2>&1

if [[ $? -eq 0 ]]; then
  log "Successfully pushed ${CHANGE_COUNT} file(s) to $REPO"
  echo "[backup-sync] ${CHANGE_COUNT} file(s) synced to ${REPO}."
else
  log "ERROR: Push failed"
  echo "[backup-sync] Push failed. Check log: $LOG_FILE"
fi
