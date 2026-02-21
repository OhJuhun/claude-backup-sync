# claude-backup-sync

매 세션이 끝날 때마다 Claude Code 설정을 GitHub 리포지토리에 자동으로 동기화하는 Claude Code 플러그인입니다.

## 기능

| 기능 | 설명 |
|------|------|
| 자동 백업 | 세션 종료 시 자동으로 설정 백업 (Stop 훅) |
| 수동 백업 | `/backup-config`으로 수동 백업 |
| 복원 | `/restore-config`으로 GitHub에서 로컬로 설정 복원 |
| API 키 보안 | `.mcp.json`의 API 키를 `${ENV_VAR}` 참조로 자동 변환 |
| 변경 감지 | 변경된 파일이 있을 때만 커밋/푸시 |

> **[English](README.md)**

## 동기화 대상

- **설정**: `settings.json`, `settings.local.json`
- **글로벌 지침**: `CLAUDE.md`
- **MCP 설정**: `.mcp.json` (API 키는 `${ENV_VAR}`로 자동 변환)
- **에이전트, 규칙, 명령어, 스킬**
- **HUD 설정, 헬퍼 스크립트**
- **Dotfiles**: `.zshrc`, `.gitconfig`, `.ssh/config`
- **Homebrew**: `Brewfile`

## 설치

```bash
claude plugins add OhJuhun/claude-backup-sync
```

또는 `~/.claude/settings.json`에 수동 추가:

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

## 설정

### 1. GitHub CLI 인증 확인

```bash
gh auth status
```

인증되지 않았다면:

```bash
gh auth login -h github.com --web
```

### 2. 설정 명령어 실행

```
/backup-setup
```

또는 수동 설정:

```
backup_configure(repo: "your-username/backup-repo", branch: "main", gh_host: "github.com")
```

## 스킬

### `/backup-config` - 설정 백업 (push)

현재 Claude Code 설정을 GitHub 백업 레포로 수동 푸시합니다.

```
/backup-config
/claude-backup-sync:backup-config
```

### `/restore-config` - 설정 복원 (pull)

GitHub 백업 레포에서 로컬로 설정을 복원합니다. 복원할 카테고리를 선택할 수 있습니다.

```
/restore-config
/claude-backup-sync:restore-config
```

**복원 가능 항목:**
- Claude 설정 (settings.json, CLAUDE.md)
- MCP 설정 (.mcp.json)
- 에이전트, 규칙, 명령어, 스킬, HUD, 스크립트
- Dotfiles (.zshrc, .gitconfig, .ssh/config)
- Brewfile

> **참고:** `.mcp.json`에는 실제 API 키 대신 `${ENV_VAR}` 플레이스홀더가 저장됩니다. 복원 후 환경 변수를 직접 설정해야 합니다.

## MCP 도구

| 도구 | 설명 |
|------|------|
| `backup_configure` | 백업 레포, 브랜치, GitHub 호스트 구성 |
| `backup_sync` | 수동 동기화 |
| `backup_status` | 마지막 동기화 시간 및 변경 사항 확인 |
| `backup_log` | 동기화 기록 확인 |

## 작동 원리

1. **자동 동기화**: 세션 종료 시 (Stop 훅) 설정 파일을 로컬 클론에 복사 후 GitHub에 푸시
2. **API 키 보안**: `.mcp.json`의 API 키를 `${ENV_VAR}` 참조로 자동 변환
3. **변경 감지**: 변경 없으면 커밋/푸시 스킵
4. **동시 실행 방지**: 락 파일로 중복 실행 방지

## 구성 파일

설정: `~/.claude/scripts/backup-config.json`

```json
{
  "repo": "your-username/backup-repo",
  "branch": "main",
  "gh_host": "github.com"
}
```

로그: `~/.claude/logs/backup-sync.log`

## 요구 사항

- **GitHub CLI** (`gh`): 설치 및 인증 필요
- **Git**: 표준 git CLI
- **Python 3**: JSON 처리용
- **GitHub 리포지토리**: 백업 저장용 (공개/비공개)

## 문제 해결

| 문제 | 해결 |
|------|------|
| "Not configured" 오류 | `/backup-setup` 실행 |
| 인증 실패 | `gh auth login -h github.com --web` |
| 권한 오류 | `repo` 또는 `public_repo` 스코프 확인 |
| 로그 확인 | `backup_log(lines: 100)` |

## 라이선스

MIT License. [LICENSE](LICENSE) 파일 참조.

## 작성자

OhJuhun
