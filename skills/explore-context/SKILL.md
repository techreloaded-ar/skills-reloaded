---
name: explore-context
description: Maps the codebase's bounded contexts using Domain-Driven Design principles. Generates context documentation files.
disable-model-invocation: true
---
# Role
Expert Software Architect and DDD specialist.

# Goal
Map the project's Bounded Contexts one by one, generating individual Markdown files. Compact your context after each iteration to avoid token overload.

# Constraints
1. **Output**: `.skills-reloaded/contexts/`, one file per context. Create dir if missing.
2. **Compaction**: After writing each file, discard specific code details before proceeding.
3. **Read-Only**: Do not modify project code.

# Instructions

**First**: Delete all files inside `.skills-reloaded/contexts/` (you will recreate them).

## Step 1: Discovery & Planning

1. **Technical Discovery**: Scan the codebase for major technical areas (languages, frameworks, libraries, infrastructure). Create `.skills-reloaded/contexts/TECHNICAL-AREAS.md`:
    ```markdown
    # Technical Areas

    ## {{area_name}}
    ### Description
    {{area_description}}
    ### Key Technologies
    {{key_technologies}}
    ```
    Repeat the `## area` section for each area. Use `---` separators.

2. **Bounded Context Discovery**: Identify **business domain** contexts (not technical). Exclude `.gitignore` paths. Scan root, `src`, `packages`, and docs.

3. **Output a Plan**: List contexts to process in order.

## Step 2: The Context Loop
For **EACH** context:

### A. Deep Analysis
Read files specific **only** to the current context. Analyze responsibilities, dependencies, key files, and rules.

### B. Generate Documentation
Write `.skills-reloaded/contexts/[context-name].md`:
```markdown
# {{context_name}}
## Location
{{context_path}}
## Description
{{context_description}}
## Key Folders
{{key_folders_bullet_list}}
## Key Files
{{key_files_bullet_list}}
## Domain Rules
{{domain_rules_bullet_list}}
```

### C. Compact Context
After writing, state "Context '[Name]' completed. Compacting..." then discard all code details and working memory for this context before proceeding to the next.
