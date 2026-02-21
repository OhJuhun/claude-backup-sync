# claude-backup-sync

A Claude Code plugin that automatically syncs your Claude Code configuration to a GitHub repository on every session end.

## Features

| Feature | Description |
|---------|-------------|
| Auto Backup | Automatically backs up config on every session end (Stop hook) |
| Manual Backup | `/backup-config` to manually push config to GitHub |
| Restore | `/restore-config` to pull config from GitHub to local |
| API Key Security | API keys in `.mcp.json` are replaced with `${ENV_VAR}` references |
| Change Detection | Only commits and pushes when changes are detected |

> **[한국어 문서](README.ko.md)**

## What Gets Synced

- **Settings**: `settings.json`, `settings.local.json`
- **Global Instructions**: `CLAUDE.md`
- **MCP Config**: `.mcp.json` (API keys auto-replaced with `${ENV_VAR}`)
- **Agents, Rules, Commands, Skills**
- **HUD Config, Helper Scripts**
- **Dotfiles**: `.zshrc`, `.gitconfig`, `.ssh/config`
- **Homebrew**: `Brewfile`

## Installation

```bash
claude plugins add OhJuhun/claude-backup-sync
```

Or add manually to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-backup-sync": {
      "source": {
        "source": "github",
        "repo": "OhJuhun/claude-backup-sync"
      }
    }
  },
  "enabledPlugins": {
    "claude-backup-sync@claude-backup-sync": true
  }
}
```

## Setup

### 1. Ensure GitHub CLI Authentication

```bash
gh auth status
```

If not authenticated:

```bash
gh auth login -h github.com --web
```

### 2. Run Setup Command

```
/backup-setup
```

Or configure manually:

```
backup_configure(repo: "your-username/backup-repo", branch: "main", gh_host: "github.com")
```

## Skills

### `/backup-config` - Push config to GitHub

Manually trigger a backup of your current Claude Code config.

```
/backup-config
/claude-backup-sync:backup-config
```

### `/restore-config` - Pull config from GitHub

Restore Claude Code config from the backup repository. Provides interactive category selection.

```
/restore-config
/claude-backup-sync:restore-config
```

**Restorable categories:**
- Claude settings (settings.json, CLAUDE.md)
- MCP config (.mcp.json)
- Agents, Rules, Commands, Skills, HUD, Scripts
- Dotfiles (.zshrc, .gitconfig, .ssh/config)
- Brewfile

> **Note:** `.mcp.json` contains `${ENV_VAR}` placeholders. Set actual environment variables after restore.

## MCP Tools

| Tool | Description |
|------|-------------|
| `backup_configure` | Configure backup repository, branch, and GitHub host |
| `backup_sync` | Manually trigger a sync to GitHub |
| `backup_status` | Check last sync time and pending changes |
| `backup_log` | View recent sync history |

## How It Works

1. **Auto Sync**: On session end (Stop hook), copies config to local clone and pushes to GitHub
2. **API Key Security**: Replaces API keys with `${ENV_VAR}` references before pushing
3. **Change Detection**: Skips commit/push if no changes detected
4. **Concurrent Run Prevention**: Lock file prevents simultaneous syncs

## Configuration

Config: `~/.claude/scripts/backup-config.json`

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "gh_host": "github.com"
}
```

Logs: `~/.claude/logs/backup-sync.log`

## Requirements

- **GitHub CLI** (`gh`): Installed and authenticated
- **Git**: Standard git CLI
- **Python 3**: For JSON processing
- **GitHub Repository**: Public or private

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not configured" | Run `/backup-setup` |
| Auth failed | `gh auth login -h github.com --web` |
| Permission error | Ensure `repo` or `public_repo` scope |
| View logs | `backup_log(lines: 100)` |

## License

MIT License. See [LICENSE](LICENSE).

## Author

Created by OhJuhun
Cg==
