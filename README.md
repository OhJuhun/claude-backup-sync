# claude-backup-sync

A Claude Code plugin that automatically syncs your Claude Code configuration to a GitHub repository on every session end.

## What Gets Synced

The plugin backs up all your Claude Code settings and configuration:

- **Settings**: `settings.json`, `settings.local.json`
- **Global Instructions**: `CLAUDE.md`
- **MCP Config**: `.mcp.json` (with API keys automatically replaced with `${ENV_VAR}` references)
- **Agents**: Custom agent definitions
- **Rules**: Custom rule files
- **Commands**: Custom command definitions
- **Skills**: Custom skill definitions
- **HUD Config**: HUD statusline configuration
- **Helper Scripts**: Custom scripts in `~/.claude/scripts/`
- **Dotfiles**: `.zshrc`, `.gitconfig`, `.ssh/config`
- **Homebrew**: `Brewfile` (Homebrew packages list)

## Installation

Install the plugin using the Claude Code plugin manager:

```bash
claude plugin install --source github --url https://github.com/OhJuhun/claude-backup-sync
```

## Setup

After installing, configure the plugin with these steps:

### 1. Ensure GitHub CLI Authentication

Verify that the GitHub CLI is authenticated:

```bash
gh auth status
```

If not authenticated, authenticate with:

```bash
gh auth login -h github.com --web
```

### 2. Run Setup Command

In Claude Code, run the setup command:

```
/backup-setup
```

This will guide you through:
- Checking GitHub CLI authentication
- Specifying your backup repository (format: `owner/repo`)
- Creating the repository if it doesn't exist
- Configuring the plugin
- Running the first sync test
- Verifying the setup

### 3. Manual Configuration (Alternative)

If you prefer manual setup, use the MCP tools directly:

```
backup_configure(repo: "your-username/backup-repo", branch: "main", gh_host: "github.com")
```

Then test with:

```
backup_sync()
```

## MCP Tools

The plugin exposes the following MCP tools for manual control:

| Tool | Description |
|------|-------------|
| `backup_configure` | Configure the backup repository, branch, and GitHub host |
| `backup_sync` | Manually trigger a sync to GitHub |
| `backup_status` | Check the last sync time and pending changes |
| `backup_log` | View recent sync history (last 20 lines by default) |

### Tool Examples

**Configure the plugin:**
```
backup_configure(repo: "my-username/my-backup", branch: "main")
```

**Manually sync:**
```
backup_sync()
```

**Check status:**
```
backup_status()
```

**View logs:**
```
backup_log(lines: 50)
```

## How It Works

1. **Automatic Sync on Session End**: Every time you end a Claude Code session (Stop hook), the plugin automatically runs the sync script.

2. **Local Clone**: The plugin maintains a local clone of your backup repository at `~/.claude/backup-sync/repo/`.

3. **Change Detection**: On each sync, the plugin:
   - Copies your Claude Code configuration to the local clone
   - Detects changes using `git diff`
   - Commits changes with a timestamp

4. **API Key Security**: API keys in `.mcp.json` are automatically replaced with environment variable references (e.g., `${OPENAI_API_KEY}`) before syncing to prevent accidental secret exposure.

5. **Push to GitHub**: Changes are automatically committed and pushed to your configured repository and branch.

## Configuration

The plugin stores configuration at: `~/.claude/backup-sync/config.json`

Example configuration:

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "gh_host": "github.com"
}
```

Logs are stored at: `~/.claude/backup-sync/sync.log`

## Requirements

- **GitHub CLI**: `gh` command-line tool, installed and authenticated
- **Node.js**: Version 18 or higher
- **Git**: Standard git command-line tool
- **GitHub Repository**: A repository where backups will be stored (can be public or private)

## Troubleshooting

### "Not configured" Error

The plugin hasn't been configured yet. Run `/backup-setup` in Claude Code.

### GitHub Authentication Failed

Ensure the GitHub CLI is authenticated:

```bash
gh auth login -h github.com --web
```

### Sync Fails with Permission Error

Ensure your GitHub token has appropriate permissions:
- `repo` scope for private repositories
- `public_repo` scope for public repositories

Check with:

```bash
gh auth status
```

### View Detailed Logs

Check the sync history with:

```
backup_log(lines: 100)
```

Or manually read the log file:

```bash
cat ~/.claude/backup-sync/sync.log
```

## Manual Operations

**Manually sync your configuration:**
```
backup_sync()
```

**Check current backup status:**
```
backup_status()
```

**Reconfigure the backup repository:**
```
backup_configure(repo: "new-owner/new-repo")
```

## Environment Variables

The plugin uses environment variables from your shell environment when replacing API keys in `.mcp.json`. For example:

- `OPENAI_API_KEY` -> Used for OpenAI keys
- `ANTHROPIC_API_KEY` -> Used for Anthropic keys
- Any custom environment variables you've defined

Make sure these environment variables are properly set before syncing to avoid issues.

## License

MIT License. See [LICENSE](LICENSE) file for details.

## Author

Created by OhJuhun

---

# 한국어

# claude-backup-sync

매 세션이 끝날 때마다 Claude Code 설정을 GitHub 리포지토리에 자동으로 동기화하는 Claude Code 플러그인입니다.

## 동기화되는 항목

플러그인은 모든 Claude Code 설정과 구성을 백업합니다:

- **설정**: `settings.json`, `settings.local.json`
- **글로벌 지침**: `CLAUDE.md`
- **MCP 설정**: `.mcp.json` (API 키는 `${ENV_VAR}` 참조로 자동 변환)
- **에이전트**: 커스텀 에이전트 정의
- **규칙**: 커스텀 규칙 파일
- **명령어**: 커스텀 명령어 정의
- **스킬**: 커스텀 스킬 정의
- **HUD 설정**: HUD 상태 표시줄 설정
- **헬퍼 스크립트**: `~/.claude/scripts/`의 커스텀 스크립트
- **설정 파일**: `.zshrc`, `.gitconfig`, `.ssh/config`
- **Homebrew**: `Brewfile` (Homebrew 패키지 목록)

## 설치

Claude Code 플러그인 매니저를 사용하여 플러그인을 설치합니다:

```bash
claude plugin install --source github --url https://github.com/OhJuhun/claude-backup-sync
```

## 설정

설치 후 다음 단계로 플러그인을 구성합니다:

### 1. GitHub CLI 인증 확인

GitHub CLI가 인증되었는지 확인합니다:

```bash
gh auth status
```

인증되지 않았다면 다음으로 인증합니다:

```bash
gh auth login -h github.com --web
```

### 2. 설정 명령어 실행

Claude Code에서 설정 명령어를 실행합니다:

```
/backup-setup
```

다음 단계를 안내합니다:
- GitHub CLI 인증 확인
- 백업 리포지토리 지정 (형식: `owner/repo`)
- 필요한 경우 리포지토리 생성
- 플러그인 구성
- 첫 번째 동기화 테스트 실행
- 설정 완료 확인

### 3. 수동 설정 (대체 방법)

수동으로 설정하려면 MCP 도구를 직접 사용합니다:

```
backup_configure(repo: "your-username/backup-repo", branch: "main", gh_host: "github.com")
```

그 다음 다음으로 테스트합니다:

```
backup_sync()
```

## MCP 도구

플러그인은 수동 제어를 위해 다음 MCP 도구를 제공합니다:

| 도구 | 설명 |
|------|------|
| `backup_configure` | 백업 리포지토리, 브랜치, GitHub 호스트 구성 |
| `backup_sync` | 수동으로 GitHub에 동기화 트리거 |
| `backup_status` | 마지막 동기화 시간 및 보류 중인 변경 사항 확인 |
| `backup_log` | 최근 동기화 기록 확인 (기본값: 마지막 20줄) |

### 도구 사용 예시

**플러그인 구성:**
```
backup_configure(repo: "my-username/my-backup", branch: "main")
```

**수동 동기화:**
```
backup_sync()
```

**상태 확인:**
```
backup_status()
```

**로그 보기:**
```
backup_log(lines: 50)
```

## 작동 원리

1. **세션 종료 시 자동 동기화**: Claude Code 세션이 끝날 때마다 (Stop 훅), 플러그인이 자동으로 동기화 스크립트를 실행합니다.

2. **로컬 클론**: 플러그인은 백업 리포지토리의 로컬 클론을 `~/.claude/backup-sync/repo/`에서 유지합니다.

3. **변경 사항 감지**: 각 동기화 시:
   - Claude Code 설정을 로컬 클론으로 복사
   - `git diff`를 사용하여 변경 사항 감지
   - 타임스탐프가 있는 변경 사항 커밋

4. **API 키 보안**: `.mcp.json`의 API 키는 동기화 전에 자동으로 환경 변수 참조 (예: `${OPENAI_API_KEY}`)로 변환되어 실수로 인한 시크릿 노출을 방지합니다.

5. **GitHub에 푸시**: 변경 사항이 자동으로 구성된 리포지토리 및 브랜치에 커밋되고 푸시됩니다.

## 구성

플러그인은 다음 위치에 구성을 저장합니다: `~/.claude/backup-sync/config.json`

구성 예시:

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "gh_host": "github.com"
}
```

로그는 다음 위치에 저장됩니다: `~/.claude/backup-sync/sync.log`

## 요구 사항

- **GitHub CLI**: `gh` 명령어 줄 도구, 설치 및 인증
- **Node.js**: 버전 18 이상
- **Git**: 표준 git 명령어 줄 도구
- **GitHub 리포지토리**: 백업이 저장될 리포지토리 (공개 또는 비공개)

## 문제 해결

### "Not configured" 오류

플러그인이 아직 구성되지 않았습니다. Claude Code에서 `/backup-setup`을 실행합니다.

### GitHub 인증 실패

GitHub CLI가 인증되었는지 확인합니다:

```bash
gh auth login -h github.com --web
```

### 동기화 실패 및 권한 오류

GitHub 토큰에 적절한 권한이 있는지 확인합니다:
- 비공개 리포지토리의 경우 `repo` 스코프
- 공개 리포지토리의 경우 `public_repo` 스코프

다음으로 확인합니다:

```bash
gh auth status
```

### 상세 로그 보기

다음으로 동기화 기록을 확인합니다:

```
backup_log(lines: 100)
```

또는 로그 파일을 수동으로 읽습니다:

```bash
cat ~/.claude/backup-sync/sync.log
```

## 수동 작업

**구성을 수동으로 동기화:**
```
backup_sync()
```

**현재 백업 상태 확인:**
```
backup_status()
```

**백업 리포지토리 다시 구성:**
```
backup_configure(repo: "new-owner/new-repo")
```

## 환경 변수

플러그인은 `.mcp.json`의 API 키를 변환할 때 셸 환경의 환경 변수를 사용합니다. 예시:

- `OPENAI_API_KEY` -> OpenAI 키에 사용
- `ANTHROPIC_API_KEY` -> Anthropic 키에 사용
- 정의한 모든 커스텀 환경 변수

동기화 전에 이러한 환경 변수가 올바르게 설정되어 있는지 확인하여 문제를 방지합니다.

## 라이선스

MIT 라이선스. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조합니다.

## 작성자

OhJuhun에 의해 작성됨
