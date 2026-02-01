---
name: god-mode
description: Developer oversight and AI agent coaching. Use when viewing project status across repos, syncing GitHub data, or analyzing agents.md against commit patterns.
metadata: {"openclaw": {"requires": {"bins": ["gh", "sqlite3", "jq"]}}}
user-invocable: true
---

# god-mode Skill

> Developer oversight and AI agent coaching for OpenClaw.

## Overview

**god-mode** gives you a bird's-eye view of all your coding projects and coaches you to write better AI agent instructions.

**Key features:**
- Multi-project status dashboard
- Incremental sync from GitHub (Azure/GitLab coming)
- Agent instruction analysis based on commit patterns
- Local SQLite cache for fast queries

## Quick Start

```bash
# First-run setup
god setup

# Add a project
god projects add github:myuser/myrepo

# Sync data
god sync

# See overview
god status

# Analyze your agents.md
god agents analyze myrepo
```

## Commands

### `god status [project]`
Show overview of all projects, or details for one:
```bash
god status              # All projects
god status myproject    # One project in detail
```

### `god sync [project] [--force]`
Fetch/update data from repositories:
```bash
god sync                # Incremental sync all
god sync myproject      # Just one project
god sync --force        # Full refresh (ignore cache)
```

### `god projects`
Manage configured projects:
```bash
god projects                        # List all
god projects add github:user/repo   # Add project
god projects remove myproject       # Remove project
```

### `god agents analyze <project>`
Analyze agents.md against commit history using LLM:
```bash
god agents analyze myproject
```

**What it does:**
1. Fetches your AGENTS.md from the repository
2. Analyzes commit patterns (types, pain points, frequently changed files)
3. Calls an LLM (Claude/GPT) to find gaps and suggest improvements
4. Displays recommendations interactively
5. Optionally applies changes to your AGENTS.md

**LLM Configuration:**

Set one of these environment variables to enable automatic analysis:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."     # Claude (recommended)
export OPENAI_API_KEY="sk-..."            # GPT-4o
export OPENROUTER_API_KEY="sk-or-..."    # Multiple models
```

Without an API key, god-mode outputs the analysis prompt for manual processing.

**Interactive Workflow:**
```bash
god agents analyze myproject

🔭 Analyzing myproject
✅ Found AGENTS.md
✅ 155 commits analyzed
🤖 Analyzing with Anthropic (Claude 3.5 Sonnet)... Done

⚠️ GAPS FOUND (3)

1. Testing practices (high impact)
   → 68 bug fix commits but no testing guidance
   → Add testing section with coverage targets

2. Voice API debugging (medium impact)
   → 12 commits mention "voice" but no troubleshooting tips

Apply recommendations to AGENTS.md? (y/N): y
Select recommendations (e.g., 1,3 or 'a' for all): 1,2

✅ Applied 2 recommendations
Commit changes? (Y/n): y
✅ Committed and pushed
```

### `god agents generate <project>` (Coming Soon)
Bootstrap agents.md for a new project by analyzing repo structure.

### `god logs [options]`
View activity logs:
```bash
god logs                # Last 50 lines
god logs -n 100         # Last 100 lines
god logs -f             # Follow log output
god logs --path         # Show log file location
god logs --clear        # Clear all logs
```

All god-mode activity is logged to `~/.god-mode/logs/activity.log` with timestamps for transparency and debugging.

## Configuration

Config file: `~/.config/god-mode/config.yaml`

```yaml
projects:
  - id: github:user/repo
    name: My Project      # Display name
    priority: high        # high/medium/low
    tags: [work, api]
    local: ~/code/myrepo  # Local clone path

sync:
  initialDays: 90         # First sync lookback
  commitsCacheMinutes: 60

analysis:
  agentFiles:             # Files to search for
    - agents.md
    - AGENTS.md
    - CLAUDE.md
    - .github/copilot-instructions.md
```

## Data Storage

All data stored locally in `~/.god-mode/`:
- `cache.db` - SQLite database (commits, PRs, issues, analyses)
- `contexts/` - Saved workspace contexts (v0.2)

## Authentication

god-mode uses your existing CLI authentication:

| Provider | CLI | Setup |
|----------|-----|-------|
| GitHub | `gh` | `gh auth login` |
| Azure | `az` | `az login` |
| GitLab | `glab` | `glab auth login` |

**No tokens stored by god-mode.** We delegate to CLIs you already trust.

## Requirements

- `gh` - GitHub CLI (for GitHub repos)
- `sqlite3` - Database
- `jq` - JSON processing

## Examples

### Morning Check-In
```bash
god status
# See all projects at a glance
# Notice any stale PRs or quiet projects
```

### Before Switching Projects
```bash
god status myproject
# See recent activity, open PRs, issues
# Remember where you left off
```

### Improving Your AI Assistant
```bash
god agents analyze myproject
# Get suggestions based on your actual commit patterns
# Apply recommendations to your agents.md
```

### Weekly Review
```bash
god status
# Review activity across all projects
# Identify projects needing attention
```

## Agent Workflows

### Daily Briefing (Heartbeat)
```markdown
# HEARTBEAT.md
- Run `god status` and summarize:
  - Projects with stale PRs (>3 days)
  - Projects with no activity (>5 days)
  - Open PRs needing review
```

### Agent Analysis (Cron)
```yaml
# Weekly agent instruction review
schedule: "0 9 * * 1"  # Monday 9am
task: |
  Run `god agents analyze` on high-priority projects.
  If gaps found, notify with suggestions.
```

## Troubleshooting

### "gh: command not found"
Install GitHub CLI: https://cli.github.com/

### "Not logged in to GitHub"
Run: `gh auth login`

### "No projects configured"
Add a project: `god projects add github:user/repo`

### Stale data
Force refresh: `god sync --force`

---

*OpenClaw Community Skill*  
*License: MIT*  
*Repository: https://github.com/InfantLab/god-mode-skill*
