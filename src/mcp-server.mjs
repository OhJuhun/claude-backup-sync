import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js'
import fs from 'fs'
import path from 'path'
import os from 'os'
import { execSync } from 'child_process'
import { fileURLToPath } from 'url'

const CONFIG_DIR = path.join(os.homedir(), '.claude', 'backup-sync')
const CONFIG_PATH = path.join(CONFIG_DIR, 'config.json')
const LOG_PATH = path.join(CONFIG_DIR, 'sync.log')
const CLONE_DIR = path.join(CONFIG_DIR, 'repo')

const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT || path.dirname(path.dirname(fileURLToPath(import.meta.url)))
const SCRIPT_PATH = path.join(PLUGIN_ROOT, 'scripts', 'backup-sync.sh')

function readConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    return null
  }
  try {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'))
  } catch {
    return null
  }
}

function readLastLines(filePath, n) {
  const content = fs.readFileSync(filePath, 'utf8')
  const lines = content.split('\n').filter(line => line.length > 0)
  return lines.slice(-n).join('\n')
}

const server = new Server(
  { name: 'backup-sync', version: '1.0.0' },
  { capabilities: { tools: {} } }
)

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'backup_configure',
      description: 'Configure the backup-sync plugin with a GitHub repository',
      inputSchema: {
        type: 'object',
        properties: {
          repo: {
            type: 'string',
            description: 'GitHub repository in owner/repo format'
          },
          branch: {
            type: 'string',
            description: 'Branch to sync to (default: main)'
          },
          gh_host: {
            type: 'string',
            description: 'GitHub host (default: github.com)'
          }
        },
        required: ['repo']
      }
    },
    {
      name: 'backup_sync',
      description: 'Run the backup-sync script to sync Claude config to GitHub',
      inputSchema: {
        type: 'object',
        properties: {}
      }
    },
    {
      name: 'backup_status',
      description: 'Check the current backup-sync status and pending changes',
      inputSchema: {
        type: 'object',
        properties: {}
      }
    },
    {
      name: 'backup_log',
      description: 'Read the backup-sync log file',
      inputSchema: {
        type: 'object',
        properties: {
          lines: {
            type: 'number',
            description: 'Number of lines to read from the end of the log (default: 20)'
          }
        }
      }
    }
  ]
}))

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params

  if (name === 'backup_configure') {
    try {
      const repo = args.repo
      const branch = args.branch || 'main'
      const gh_host = args.gh_host || 'github.com'

      if (!fs.existsSync(CONFIG_DIR)) {
        fs.mkdirSync(CONFIG_DIR, { recursive: true })
      }

      const config = { repo, branch, gh_host }
      fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2), 'utf8')

      return {
        content: [
          {
            type: 'text',
            text: `Backup-sync configured successfully.\n\nRepo: ${repo}\nBranch: ${branch}\nHost: ${gh_host}\nConfig saved to: ${CONFIG_PATH}`
          }
        ]
      }
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error configuring backup-sync: ${error.message}` }],
        isError: true
      }
    }
  }

  if (name === 'backup_sync') {
    try {
      const config = readConfig()
      if (!config) {
        return {
          content: [{ type: 'text', text: 'Not configured. Please run backup_configure first.' }],
          isError: true
        }
      }

      let output
      try {
        output = execSync(`bash "${SCRIPT_PATH}"`, {
          timeout: 60000,
          encoding: 'utf8',
          env: { ...process.env }
        })
      } catch (execError) {
        output = (execError.stdout || '') + (execError.stderr || '')
        return {
          content: [{ type: 'text', text: `Sync script exited with error:\n${output}` }],
          isError: true
        }
      }

      return {
        content: [{ type: 'text', text: `Sync completed:\n${output}` }]
      }
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error running sync: ${error.message}` }],
        isError: true
      }
    }
  }

  if (name === 'backup_status') {
    try {
      const config = readConfig()
      if (!config) {
        return {
          content: [{ type: 'text', text: 'Not configured. Please run backup_configure first.' }]
        }
      }

      let lastSync = 'Never'
      if (fs.existsSync(LOG_PATH)) {
        try {
          const lastLine = readLastLines(LOG_PATH, 1)
          if (lastLine) {
            lastSync = lastLine
          }
        } catch {
          // ignore
        }
      }

      let pendingChanges = 'Unable to check (repo not cloned)'
      if (fs.existsSync(CLONE_DIR)) {
        try {
          const diffStat = execSync('git diff --stat', {
            cwd: CLONE_DIR,
            encoding: 'utf8',
            timeout: 10000
          }).trim()

          const untracked = execSync('git ls-files --others --exclude-standard', {
            cwd: CLONE_DIR,
            encoding: 'utf8',
            timeout: 10000
          }).trim()

          const untrackedFiles = untracked ? untracked.split('\n').filter(Boolean) : []
          const hasDiff = diffStat.length > 0
          const pendingCount = untrackedFiles.length + (hasDiff ? 1 : 0)

          if (pendingCount === 0) {
            pendingChanges = 'None (up to date)'
          } else {
            const parts = []
            if (hasDiff) parts.push(`modified files: ${diffStat}`)
            if (untrackedFiles.length > 0) parts.push(`untracked files: ${untrackedFiles.length} (${untrackedFiles.join(', ')})`)
            pendingChanges = parts.join('\n')
          }
        } catch (gitError) {
          pendingChanges = `Error checking git status: ${gitError.message}`
        }
      }

      const statusText = [
        `Repo:          ${config.repo}`,
        `Branch:        ${config.branch || 'main'}`,
        `Host:          ${config.gh_host || 'github.com'}`,
        `Last sync:     ${lastSync}`,
        `Pending changes:\n${pendingChanges}`
      ].join('\n')

      return {
        content: [{ type: 'text', text: statusText }]
      }
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error checking status: ${error.message}` }],
        isError: true
      }
    }
  }

  if (name === 'backup_log') {
    try {
      const lines = args.lines || 20

      if (!fs.existsSync(LOG_PATH)) {
        return {
          content: [{ type: 'text', text: 'No sync history' }]
        }
      }

      const content = readLastLines(LOG_PATH, lines)
      return {
        content: [{ type: 'text', text: content || 'Log file is empty' }]
      }
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error reading log: ${error.message}` }],
        isError: true
      }
    }
  }

  return {
    content: [{ type: 'text', text: `Unknown tool: ${name}` }],
    isError: true
  }
})

const transport = new StdioServerTransport()
await server.connect(transport)
