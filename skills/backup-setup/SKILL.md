# Backup Setup

Initial setup guide for claude-backup-sync plugin.

## Trigger

User says: "backup setup", "setup backup", "configure backup", "/backup-setup"

## Steps

### 1. Check GitHub CLI Authentication

```bash
gh auth status
```

If not authenticated, guide the user:
```bash
gh auth login -h github.com --web
```

### 2. Ask for Backup Repository

Ask the user for their backup repository name (e.g., `username/backup-repo`).

If the repository doesn't exist, offer to create it:
```bash
gh repo create <repo-name> --public --description "Claude Code config backup"
```

### 3. Configure the Plugin

Use the `backup_configure` MCP tool:

```
backup_configure(repo: "<user's repo>", branch: "main", gh_host: "github.com")
```

### 4. Run First Sync

Use the `backup_sync` MCP tool to test:

```
backup_sync()
```

### 5. Verify

Use the `backup_status` MCP tool to confirm everything is working:

```
backup_status()
```

Show the user the result and confirm setup is complete.

## What Gets Synced

- `~/.claude/settings.json` - Claude Code settings
- `~/.claude/settings.local.json` - Local settings
- `~/.claude/CLAUDE.md` - Global instructions
- `~/.claude/.mcp.json` - MCP config (API keys replaced with env var references)
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

## Notes

- Sync runs automatically on every session end (Stop hook)
- API keys in `.mcp.json` are automatically replaced with `${ENV_VAR}` references
- Use `backup_sync` tool for manual sync anytime
- Use `backup_log` tool to check sync history
