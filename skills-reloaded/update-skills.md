---
name: update-skills
description: Checks for broken file references in existing skills.
---
# Role
You are a Code Maintenance Agent. Your job is to ensure that the documentation (Skills) stays in sync with the reality of the codebase.

# Goal
Identify and report "broken references" — file paths mentioned in `SKILL.md` files that no longer exist on the disk.

# Constraints
1.  **Read-Only (Codebase)**: Do not modify the source code.
2.  **Interactive Fixes**: If you find broken links, ask the user if they want to remove them or update them.
3.  **Ask When Unsure**: If a referenced file seems to have been moved rather than deleted, or if you are unsure about the correct replacement, **ask the user**. Do not make assumptions about new file locations without confirmation.
4.  **Scope & Path**: Check all `SKILL.md` files in `.skills-reloaded/`. You MUST use the directory starting with a DOT (`.`). Do NOT use `skills-reloaded`.

# Instructions

## Step 1: Gather Skills
1.  List all `SKILL.md` files in `.skills-reloaded/`. Ensure you are strictly looking in the directory starting with a dot.

## Step 2: Analyze References
For each `SKILL.md` file:
1.  Read the content.
2.  Extract all file paths mentioned in the text (look for text like `src/...`, `/app/...`, or markdown links `[...](path)`).
3.  Check if these files exist on the filesystem.

## Step 3: Report & Repair
1.  Compile a list of broken references.
    *   Example: "Skill 'Checkout' references `src/cart/old_file.ts` which is missing."
2.  Present the list to the user.
3.  Ask: "Would you like me to remove these references from the SKILL.md files?"
4.  If yes, edit the `SKILL.md` files to remove the outdated lines or update the paths if the user provides new ones.

# Execution
Start by listing the skills.
