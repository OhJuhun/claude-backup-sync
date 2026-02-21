# Restore Config

Restore Claude Code config from GitHub backup repository to local machine.

## Trigger

User says: "restore config", "pull config", "sync from backup", "/restore-config"

## Steps

### 1. Read backup config

```bash
CONFIG_FILE="$HOME/.claude/scripts/backup-config.json"
REPO=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))["repo"])")
BRANCH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get("branch", "main"))")
CLONE_DIR="$HOME/.claude/backup-repo"
```

### 2. Clone or pull latest from backup repo

```bash
if [ \! -d "$CLONE_DIR/.git" ]; then
  gh repo clone "$REPO" "$CLONE_DIR" -- -b "$BRANCH"
else
  git -C "$CLONE_DIR" pull --rebase origin "$BRANCH"
fi
```

### 3. Ask user what to restore

Ask the user which categories to restore using AskUserQuestion (multiSelect):

- Claude settings (settings.json, CLAUDE.md)
- MCP config (.mcp.json)
- Agents, Rules, Commands
- Skills
- HUD config
- Scripts
- Dotfiles (.zshrc, .gitconfig, .ssh/config)
- Brewfile
- All of the above

### 4. Restore selected files

Copy files from `$CLONE_DIR/claude/` back to `~/.claude/`:

- `claude/settings.json` → `~/.claude/settings.json`
- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `claude/.mcp.json` → `~/.claude/.mcp.json`
- `claude/agents/` → `~/.claude/agents/`
- `claude/rules/` → `~/.claude/rules/`
- `claude/commands/` → `~/.claude/commands/`
- `claude/skills/` → `~/.claude/skills/`
- `claude/hud/` → `~/.claude/hud/`
- `claude/scripts/` → `~/.claude/scripts/`
- `.zshrc` → `~/.zshrc`
- `.gitconfig` → `~/.gitconfig`
- `.ssh_config` → `~/.ssh/config`

For Brewfile: `brew bundle install --file="$CLONE_DIR/Brewfile"`

### 5. Warn about MCP config

IMPORTANT: `.mcp.json` contains `${ENV_VAR}` placeholders instead of real API keys.
Tell the user they need to set the actual environment variables after restore.

### 6. Report result

Report in Korean:
- Number of files restored
- Source repository
- Any warnings (e.g., MCP env vars need setup)
