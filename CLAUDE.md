# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**skills-reloaded** is a prompt-based framework for automatically building AI skills and agents that work within existing repositories. It generates structured documentation (contexts, skills, and agents) to enable AI systems to understand and work effectively with a codebase.

## Architecture

The framework operates through a **three-phase workflow**:

### Phase 1: Context Discovery (`explore-context` command)
- **Purpose**: Maps the codebase into Bounded Contexts using Domain-Driven Design principles
- **Output Location**: `.skills-reloaded/contexts/`
- **Process**:
  1. Scans codebase for technical areas (languages, frameworks, infrastructure) → creates `TECHNICAL-AREAS.md`
  2. Identifies business domain contexts (excludes technical/infrastructure contexts)
  3. Generates one `.md` file per context with location, description, key folders/files, and domain rules
- **Memory Management**: Uses compaction strategy — after documenting each context, discards code details before processing the next to avoid token overflow

### Phase 2: Skill Generation (`create-skills` command)
- **Purpose**: Transforms context documentation into executable skill files
- **Input**: Reads from `.skills-reloaded/contexts/*.md` (excluding `TECHNICAL-AREAS.md`)
- **Output Location**: `.skills-reloaded/skills/<context-name>/SKILL.md`
- **Process**:
  1. For each context, performs deep code analysis using actual file reads (not filename guessing)
  2. Generates SKILL.md with: context, rules, examples, and user customizations section
  3. Preserves existing "User Customizations" sections during regeneration
  4. Compacts context after each skill generation
- **Template Structure**:
  - Frontmatter: `name`, `description` (must include precise trigger conditions)
  - Sections: Context, Rules, Examples, User Customizations

### Phase 3: Agent Creation (`create-agents` command)
- **Purpose**: Builds an AI workforce with orchestrator and specialized sub-agents
- **Prerequisite**: Requires `TECHNICAL-AREAS.md` from Phase 1
- **Output Location**: `.skills-reloaded/agents/`
- **Components**:
  1. **Orchestrator** (`orchestrator.md`): Routes work to sub-agents, validates outputs
     - Workflow: Analyze → Plan → Execute Loop → Validate
     - Uses skill-first delegation (explicitly lists required skills per task)
  2. **Sub-Agents**: One per technical area from `TECHNICAL-AREAS.md`
     - Named by professional role (e.g., `nextjs-dev.md`, not `nextjs.md`)
     - Contains role, capabilities, rules & guidelines from technical area

### Maintenance (`update-skills` command)
- **Purpose**: Validates and repairs broken file references in skill documentation
- **Process**:
  1. Scans all `SKILL.md` files in `.skills-reloaded/` (note: directory starts with `.`)
  2. Extracts file paths and checks if they exist
  3. Reports broken references and asks user for fix strategy (remove or update)
- **Important**: Always uses `.skills-reloaded/` (with dot), never `skills-reloaded/`

## Key Design Principles

1. **Iterative Processing**: All commands process items one-by-one with context compaction between iterations to manage token limits
2. **Read Actual Code**: Commands must read actual files, not guess from filenames
3. **Preservation**: Skills preserve user customizations during regeneration
4. **Separation of Concerns**:
   - Contexts = Domain knowledge
   - Skills = Executable capabilities
   - Agents = Specialized workers
5. **Orchestration Pattern**: Orchestrator delegates work to specialized sub-agents with explicit skill requirements

## Directory Structure

```
.skills-reloaded/
├── contexts/           # Phase 1 output: Bounded context documentation
│   ├── TECHNICAL-AREAS.md
│   └── [context-name].md
├── skills/             # Phase 2 output: Executable skills
│   └── [context-name]/
│       └── SKILL.md
└── agents/             # Phase 3 output: AI workforce
    ├── orchestrator.md
    └── [role-name].md  # Sub-agents
```

## Command Execution Order

1. **First time setup**: `explore-context` → `create-skills` → `create-agents`
2. **After codebase changes**: `update-skills` to validate existing documentation
3. **Re-analysis**: Delete `.skills-reloaded/contexts/*` and re-run `explore-context`

## Important Gotchas

- The `explore-context` command **deletes all files** in `.skills-reloaded/contexts/` before starting
- Skills explicitly **exclude `TECHNICAL-AREAS.md`** from processing (it's for agent creation)
- Directory naming: Always use `.skills-reloaded/` (with leading dot) in code, never `skills-reloaded/`
- Agent filenames use professional roles, not technology names
- User Customizations section in SKILL.md must never be auto-generated — only restored from existing files
