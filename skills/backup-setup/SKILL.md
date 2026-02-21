# Backup Setup

Initial setup guide for claude-backup-sync plugin.

## Trigger

User says: "backup setup", "setup backup", "configure backup", "/backup-setup"

## Steps

### 1. Check Git CLI Authentication

```bash
gh auth status
```

If not authenticated, guide the user:
```bash
gh auth login -h github.com --web
```

For GitLab, guide the user to configure git credentials instead.

### 2. Ask for Backup Repository

Ask the user for:
- **Repository** (e.g., `username/backup-repo`)
- **Host** (default: `github.com`, or `gitlab.com`, etc.)
- **Branch** (default: `main`)

If the repository doesn't exist and host is github.com, offer to create it:
```bash
gh repo create <repo-name> --private --description "Claude Code config backup"
```

### 3. Create Config File

Create the config file at `~/.claude/scripts/backup-config.json`:

```bash
mkdir -p ~/.claude/scripts
cat > ~/.claude/scripts/backup-config.json << EOF
{
  "repo": "<user's repo>",
  "branch": "main",
  "host": "<user's host>"
}
EOF
```

### 4. Run First Sync

Run the backup sync script to test:

```bash
bash ~/.claude/scripts/backup-sync.sh
```

Or if running from the plugin:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/backup-sync.sh"
```

### 5. Verify

Check that the sync was successful by reading the log:

```bash
tail -5 ~/.claude/logs/backup-sync.log
```

Show the user the result and confirm setup is complete.

## What Gets Synced

- `~/.claude/settings.json` - Claude Code settings
- `~/.claude/settings.local.json` - Local settings
- `~/.claude/CLAUDE.md` - Global instructions
- `~/.claude/.mcp.json` - MCP config (API keys replaced with `${ENV_VAR}` references)
- `~/.claude/agents/` - Agent definitions
- `~/.claude/rules/` - Rule files
- `~/.claude/commands/` - Custom commands
- `~/.claude/skills/` - Skills
- `~/.claude/hud/` - HUD config
- `~/.claude/scripts/` - Helper scripts
- `~/.zshrc` - Shell config
- `~/.gitconfig` - Git config
- `~/.ssh/config` - SSH config (as `.ssh_config`)
- `Brewfile` - Homebrew packages

## Supported Hosts

| Host | Example |
|------|---------|
| GitHub | `"host": "github.com"` |
| GitLab | `"host": "gitlab.com"` |
| Self-hosted | `"host": "git.mycompany.com"` |

## Notes

- Sync runs automatically on every session end (Stop hook)
- API keys in `.mcp.json` are automatically replaced with `${ENV_VAR}` references
- Use `/backup-config` for manual sync anytime
- Use `/restore-config` to restore from backup
