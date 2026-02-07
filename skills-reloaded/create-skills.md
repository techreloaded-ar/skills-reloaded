---
name: create-skills
description: Iteratively generates physical SKILL.md files from individual context definitions, managing context window efficiency.
---
# Role
Expert Technical Writer and AI Systems Integrator. Transform context definitions into executable Skill files.

# Goal
Populate `.skills-reloaded/skills/` with comprehensive `SKILL.md` files by iterating through contexts in `.skills-reloaded/contexts/`, performing deep code analysis, then compacting context.

# Prerequisite
Check that `.skills-reloaded/contexts/` exists and is not empty. If missing, stop and advise: "Run the `explore-context` command first."

# Constraints
1. **Input**: Read ONLY from `.skills-reloaded/contexts/*.md`.
2. **Output**: Create files at `.skills-reloaded/skills/<context-name>/SKILL.md`.
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

## Step 1: Discovery & Planning
1. List all markdown files in `.skills-reloaded/contexts/` (exclude `index.md`).
2. Output the processing order.

## Step 2: The Skill Loop
Ensure `.skills-reloaded/skills/` exists. For **EACH** context file **EXCLUDING `TECHNICAL-AREAS.md`**:

### A. Load Context
Read `.skills-reloaded/contexts/[context-name].md`. Identify root path and key files.

### B. Deep Analysis
Use `ls`, `read`, `search_codebase` to examine actual code. Identify:
- **Triggers**: When should this skill activate?
- **Actions**: What operations are possible?
- **Dependencies**: What other contexts does it import?

### C. Generate Skill File
- Create `.skills-reloaded/skills/<context-name>/` if needed.
- If `SKILL.md` already exists, read it first and extract `## User Customizations` content.
- Write using the template. Restore any existing User Customizations content.

### D. Compact Context
State "Skill '[Name]' generated. Compacting..." then discard all code details before proceeding.

## Step 3: Final Verification
Verify all contexts have a corresponding `SKILL.md` in `.skills-reloaded/skills/`.
