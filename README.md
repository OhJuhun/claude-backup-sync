# claude-backup-sync

A Claude Code plugin that automatically syncs your Claude Code configuration to a GitHub/GitLab repository on every session end.

## Features

| Feature | Description |
|---------|-------------|
| Auto Backup | Automatically backs up config on every session end (Stop hook) |
| Manual Backup | `/backup-config` to manually push config |
| Restore | `/restore-config` to pull config from backup to local |
| API Key Security | API keys in `.mcp.json` are replaced with `${ENV_VAR}` references |
| Change Detection | Only commits and pushes when changes are detected |
| Multi-Host | Supports GitHub, GitLab, and any self-hosted git server |

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

### 1. Ensure Git Authentication

For GitHub:
```bash
gh auth status
```

For GitLab or other hosts, ensure git credentials are configured.

### 2. Run Setup Command

```
/backup-setup
```

This will guide you through repository selection, config creation, and first sync test.

### 3. Manual Configuration (Alternative)

Create `~/.claude/scripts/backup-config.json`:

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "host": "github.com"
}
```

## Skills

### `/backup-config` - Push config to remote

Manually trigger a backup of your current Claude Code config.

```
/backup-config
/claude-backup-sync:backup-config
```

### `/restore-config` - Pull config from remote

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

### `/backup-setup` - Initial setup

Interactive setup wizard for first-time configuration.

## Supported Hosts

| Host | Config Example |
|------|---------------|
| GitHub | `"host": "github.com"` |
| GitLab | `"host": "gitlab.com"` |
| Self-hosted | `"host": "git.mycompany.com"` |

## How It Works

1. **Auto Sync**: On session end (Stop hook), copies config to local clone and pushes
2. **API Key Security**: Replaces API keys with `${ENV_VAR}` references before pushing
3. **Change Detection**: Skips commit/push if no changes detected
4. **Concurrent Run Prevention**: Lock file prevents simultaneous syncs

## Configuration

Config: `~/.claude/scripts/backup-config.json`

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "host": "github.com"
}
```

Logs: `~/.claude/logs/backup-sync.log`

## Requirements

- **Git**: Standard git CLI
- **Python 3**: For JSON processing
- **GitHub CLI** (`gh`): Only needed for GitHub setup (optional for GitLab)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not configured" | Run `/backup-setup` |
| Auth failed | Check git credentials for your host |
| Permission error | Ensure token has repo access |
| View logs | `cat ~/.claude/logs/backup-sync.log` |

## License

MIT License. See [LICENSE](LICENSE).

## Author

Created by OhJuhun
