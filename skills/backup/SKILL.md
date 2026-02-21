# Backup

Manually sync Claude Code config to GitHub backup repository.

## Trigger

User says: "backup", "sync config", "push config", "/backup"

## Steps

Run the backup sync script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/backup-sync.sh"
```

Report the result to the user in Korean.

If successful, show:
- Number of files synced
- Target repository name

If no changes detected, tell the user there are no changes to sync.
