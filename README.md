# skills-reloaded

A prompt-based framework for automatically building AI skills and agents that work within existing repositories. It generates structured documentation (contexts, skills, and agents) to enable AI systems to understand and work effectively with your codebase.

## What It Does

**skills-reloaded** analyzes your codebase and automatically generates:

1. **Context Documentation** - Maps your codebase into Bounded Contexts using Domain-Driven Design principles
2. **Executable Skills** - Creates specialized skills that AI agents can use to work with your code
3. **AI Workforce** - Builds an orchestrator and specialized sub-agents tailored to your tech stack

The framework operates through a three-phase workflow that progressively builds understanding of your codebase and creates the necessary documentation for AI systems to work effectively within it.

## Skills Overview

### 1. `explore-context`
Analyzes your codebase and documents technical areas and business contexts using Domain-Driven Design principles. Run this first.

### 2. `create-skills`
Generates executable skills from discovered contexts and **installs** them to your AI tool. Detects Claude Code, OpenCode, Codex, Gemini CLI, or GitHub Copilot automatically. If it can't detect your tool, you'll be prompted to choose.

### 3. `create-agents`
Creates an orchestrator and specialized sub-agents for your tech stack, then **installs** them to your AI tool. Same auto-detection as `create-skills`.

## Installation

The installation process uses automated scripts to download and install the skills into your AI tool's skills directory.

### Supported tools

- **Claude Code** (`.claude/skills/`)
- **OpenCode** (`.opencode/skills/`)
- **Codex** (`.agents/skills/`)
- **Gemini CLI** (`.gemini/skills/`)
- **GitHub Copilot** (`.github/skills/`)

### Installation

**Windows**: 
Open **PowerShell** in your target project directory and run:

```powershell
# Navigate to your project
cd C:\path\to\your\project

# Download and run the installer
irm https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main/install.ps1 | iex
```

**Mac/Linux** Open **Terminal** in your target project directory and run:

```bash
# Navigate to your project
cd /path/to/your/project

# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main/install.sh | bash
```

**The installer will:**
1. Download all skills from GitHub
2. Show an interactive menu to select which tools to install for
3. Install the skills to the selected tools
4. Clean up any legacy skill files


### Manual Installation (Alternative)

If you prefer to install manually or the automated installer doesn't work:

```bash
# Clone the repository
git clone https://github.com/techreloaded-ar/skills-reloaded.git
cd skills-reloaded

# Run the install script
# On Mac/Linux:
./install.sh

# On Windows PowerShell:
.\install.ps1
```

### Verification

After installation, verify the three skills are in your tool's directory:

```bash
# Claude Code
ls .claude/skills/

# OpenCode
ls .opencode/skills/

# Codex
ls .agents/skills/

# Gemini CLI
ls .gemini/skills/

# GitHub Copilot
ls .github/skills/
```

You should see: `create-agents`, `create-skills`, `explore-context`

## Usage

### First-Time Setup

Run the skills in this order to analyze your codebase and generate the complete documentation:

```
1. explore-context  → Discovers contexts and technical areas
2. create-skills    → Generates and auto-installs executable skills from contexts
3. create-agents    → Creates and auto-installs orchestrator and specialized sub-agents
```

**Note:** Both `create-skills` and `create-agents` will automatically detect which AI tool you're using and install the generated files in the appropriate directory. If detection fails or multiple tools are found, you'll be prompted to select the target tool.

**How to invoke skills:**

The exact method depends on your AI tool:

- **Claude Code**: Type `/explore-context`, `/create-skills`, `/create-agents`
- **OpenCode**: Use the skills command interface
- **Codex**: Type `@explore-context`, `@create-skills`, `@create-agents`
- **Gemini CLI**: Use the skills invocation syntax


### Re-analyzing Your Codebase

If your codebase changes significantly, you can re-run the analysis:

1. Delete the contexts: `rm -rf .skills-reloaded/contexts/*` (or `Remove-Item` on Windows)
2. Re-run: `explore-context` → `create-skills` → `create-agents`

### Using Generated Skills and Agents

The `create-skills` and `create-agents` skills automatically install generated files into your AI tool's directory structure. The skills are ready to use immediately after generation.

**Automatic Installation Paths:**
- **Claude Code**: `.claude/skills/`
- **OpenCode**: `.opencode/skills/`
- **Codex**: `.agents/skills/`
- **Gemini CLI**: `.gemini/skills/`
- **GitHub Copilot**: `.github/skills/`


## Key Features

- **Auto-Detection**: Automatically detects your AI tool and installs skills/agents in the correct location
- **Memory Efficient**: Uses context compaction to handle large codebases without token overflow
- **DDD-Based**: Uses Domain-Driven Design principles for clean context boundaries
- **Preserves Customizations**: User modifications are preserved during regeneration


## Important Notes

- All skills use `disable-model-invocation: true` - they must be invoked explicitly by the user
- The `explore-context` skill deletes all files in `.skills-reloaded/contexts/` before starting
- Skills preserve existing "User Customizations" sections during regeneration

