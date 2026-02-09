---
name: create-skills
description: Generates SKILL.md files from previously discovered bounded contexts. Requires explore-context to be run first.
disable-model-invocation: true
---
# Role
Expert Technical Writer and AI Systems Integrator. Transform context definitions into executable Skill files.

# Goal
Populate the target skills directory with comprehensive `SKILL.md` files by iterating through contexts in `.skills-reloaded/contexts/`, performing deep code analysis, then compacting context.

# Prerequisite
Check that `.skills-reloaded/contexts/` exists and is not empty. If missing, stop and advise: "Run the `explore-context` skill first."

# Constraints
1. **Input**: Read ONLY from `.skills-reloaded/contexts/*.md`.
2. **Output**: Create files at `{SKILLS_OUTPUT_BASE}<context-name>/SKILL.md` (one per target platform detected in Step 0).
3. **Template**:
    ```markdown
    ---
    name: {{skill_name}}
    description: {{skill_description — must be a precise trigger, e.g. "Use this skill when ..."}}
    ---
    # {{Skill Title}}

    ## Context
    {{Detailed description of the domain: business logic, technical decisions, constraints, dependencies. Explain "Why" and "How" in depth.}}

    ## Rules
    {{Comprehensive bulleted list of invariants, validation rules, constraints, and edge cases.}}

    ## Examples
    {{Code/logic examples with multiple scenarios if applicable.}}

    ## User Customizations
    {{Preserved during updates. Do NOT generate content here — only restore existing content.}}
    ```
4. **Compaction**: After generating each skill, discard code details before starting the next.
5. **Quality**: Read actual code. Do not hallucinate from filenames.

# Instructions

## Step 0: Detect Target Environment

Determine where to save generated skill files by setting one or more `SKILLS_OUTPUT_BASE` paths.

1. **Auto-detect**: Identify which AI coding tool you are currently running in:
   | Environment | Skills output base |
   |---|---|
   | Claude Code | `.claude/skills/` |
   | Codex | `.agents/skills/` |
   | Gemini CLI | `.gemini/skills/` |
   | OpenCode | `.opencode/skills/` |

   If you can identify your environment → use the corresponding path and proceed to Step 1.

2. **Directory check**: If unsure, check which of these directories exist in the project root: `.claude/`, `.agents/`, `.gemini/`, `.opencode/`. If exactly one exists → use the corresponding platform's skills path.

3. **Ask the user**: If detection fails or multiple directories found, ask:
   "In quale ambiente vuoi generare i file? (selezione multipla possibile)"
   - Claude Code (`.claude/skills/`)
   - Codex (`.agents/skills/`)
   - Gemini CLI (`.gemini/skills/`)
   - OpenCode (`.opencode/skills/`)
   - Altro (`.skills-reloaded/skills/`)

   If multiple selected → generate files in ALL selected directories.
   If "Altro" selected → use `.skills-reloaded/skills/`.

Store the result as the list of `SKILLS_OUTPUT_BASES` to use in subsequent steps.

## Step 1: Discovery & Planning
1. List all markdown files in `.skills-reloaded/contexts/` (exclude `index.md`).
2. Output the processing order.

## Step 2: The Skill Loop
Ensure each `SKILLS_OUTPUT_BASE` directory exists. For **EACH** context file **EXCLUDING `TECHNICAL-AREAS.md`**:

### A. Load Context
Read `.skills-reloaded/contexts/[context-name].md`. Identify root path and key files.

### B. Deep Analysis
Use `ls`, `read`, `search_codebase` to examine actual code. Identify:
- **Triggers**: When should this skill activate?
- **Actions**: What operations are possible?
- **Dependencies**: What other contexts does it import?

### C. Generate Skill File
For each `SKILLS_OUTPUT_BASE`:
- Create `{SKILLS_OUTPUT_BASE}<context-name>/` if needed.
- If `SKILL.md` already exists at that path, read it first and extract `## User Customizations` content.
- Write using the template. Restore any existing User Customizations content.

### D. Compact Context
State "Skill '[Name]' generated. Compacting..." then discard all code details before proceeding.

## Step 3: Final Verification
Verify all contexts have a corresponding `SKILL.md` in each `SKILLS_OUTPUT_BASE` directory.
