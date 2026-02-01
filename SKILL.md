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
- Multi-project status dashboard (GitHub + Azure DevOps)
- Incremental sync with SQLite cache for fast queries
- LLM-powered agent instruction analysis
- Activity logging for transparency

**Perfect for:**
- Developers juggling multiple repos
- Teams using AI coding assistants (Claude, Copilot, etc.)
- Anyone who wants better AGENTS.md based on actual commit patterns

## Getting Started

### Prerequisites

1. **GitHub CLI** - `gh` must be installed and authenticated
   ```bash
   gh auth login  # If not already logged in
   ```

2. **Your repositories** - At least one repo with commit history

3. **(Optional) AGENTS.md** - For agent analysis feature

### First-Time Setup

```bash
# Run setup (checks dependencies, creates directories)
god setup

# Add your first project (replace with your repo)
god projects add github:yourusername/yourrepo

# Sync data (fetches commits, PRs, issues)
god sync

# See your project status
god status
```

**Expected output:**
```
🔭 god-mode

github:yourusername/yourrepo
  Last: 2h ago • feat: add new feature
  This week: 15 commits • 2 PRs • 3 issues

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This week: 15 commits • 2 open PRs
```

### Using in OpenClaw

When running god-mode commands in OpenClaw, I (your OpenClaw agent) can:
- Help you set up projects
- Explain the analysis results
- Provide the LLM analysis for `god agents analyze`
- Guide you through applying recommendations

**Typical workflow in OpenClaw:**
1. You: "Set up god-mode for my tada repo"
2. Me: Runs `god projects add github:InfantLab/tada` and `god sync`
3. You: "Analyze my agents.md"
4. Me: Runs `god agents analyze`, shows you the prompt, provides JSON analysis
5. You: Decide which recommendations to apply
6. Me: Helps apply them to your AGENTS.md

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

god-mode automatically detects and uses the best available LLM:

1. **OpenClaw (default when running as skill)** - Uses your OpenClaw agent
2. **Anthropic** - Set `ANTHROPIC_API_KEY="sk-ant-..."`
3. **OpenAI** - Set `OPENAI_API_KEY="sk-..."`  
4. **OpenRouter** - Set `OPENROUTER_API_KEY="sk-or-..."`
5. **Manual** - Outputs prompt if no LLM available

**When running in OpenClaw:**
- The analysis prompt is displayed to your OpenClaw agent
- You (or your agent) provides the JSON analysis directly in the conversation
- Much simpler than managing separate API keys!

**OpenClaw Workflow:**

When you run `god agents analyze` in OpenClaw:

1. **Analysis starts:**
   ```
   🔭 Analyzing github:InfantLab/tada
   ✅ Found AGENTS.md (remote)
   ✅ 155 commits analyzed
   🤖 Using OpenClaw's LLM
   ```

2. **I (OpenClaw agent) receive the analysis prompt** showing:
   - Your complete AGENTS.md content
   - Commit pattern summary (45 features, 68 bug fixes, etc.)
   - Most changed files/directories
   - Pain points and commit samples

3. **I analyze and provide JSON response:**
   ```json
   {
     "gaps": [
       {
         "area": "Testing",
         "observation": "68 bug fixes but no testing guidance in AGENTS.md",
         "impact": "high",
         "suggestion": "Add testing section with coverage targets"
       }
     ],
     "strengths": [...],
     "recommendations": [...]
   }
   ```

4. **god-mode displays results** and offers to apply changes to your AGENTS.md

5. **You choose** which recommendations to accept, and god-mode updates the file

**Standalone Workflow (outside OpenClaw):**

If you set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`, god-mode calls the API directly:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
god agents analyze myproject  # Fully automated
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

## Common Questions

### How do I know if god-mode is working?
Run `god status` - if you see project data, it's working! If you see "No projects configured", run `god projects add github:your/repo` first.

### Do I need an API key to use god agents analyze?
No! When running in OpenClaw, the analysis prompt is shown to your OpenClaw agent (me), and I provide the analysis. No separate API key needed.

### Can I use this outside OpenClaw?
Yes! god-mode works standalone. Just set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` for automated LLM analysis, or use it without API keys to get the analysis prompt only.

### How often should I sync?
Run `god sync` when you want fresh data. The first sync fetches 90 days of commits. Subsequent syncs are incremental (only new data).

### What gets stored locally?
Everything! Commits, PRs, issues, and analysis results are cached in `~/.god-mode/cache.db`. Activity logs in `~/.god-mode/logs/activity.log`. Nothing is sent to external servers (except the LLM API call if you use one).

### Can I use this for private repos?
Yes! god-mode uses your `gh` CLI authentication, so it has access to whatever your GitHub account can access.

## Troubleshooting

### "gh: command not found"
Install GitHub CLI: https://cli.github.com/

### "Not logged in to GitHub"
Run: `gh auth login`

### "No projects configured"
Add a project: `god projects add github:user/repo`

### Stale data
Force refresh: `god sync --force`

### Agent analysis returns empty {}
This is normal in OpenClaw mode - the prompt is displayed for the OpenClaw agent to analyze. The agent provides the JSON response in conversation, not as return value.

---

*OpenClaw Community Skill*  
*License: MIT*  
*Repository: https://github.com/InfantLab/god-mode-skill*
