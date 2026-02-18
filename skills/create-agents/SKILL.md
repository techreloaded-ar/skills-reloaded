---
name: create-agents
description: Creates an AI workforce (Orchestrator + Sub-agents) from the technical areas documentation. Requires explore-context to be run first.
disable-model-invocation: true
---
# Create Agents Skill

This skill automates the creation of an AI workforce (Orchestrator + Sub-agents) based on the technical areas defined in the codebase.

## 0. Detect Target Environment

Determine where to save generated agent files by setting one or more `AGENTS_OUTPUT_BASE` paths.

1. **Auto-detect**: Identify which AI coding tool you are currently running in:
   | Environment | Agents output base |
   |---|---|
   | Claude Code | `.claude/agents/` |
   | Codex | `.agents/agents/` |
   | Gemini CLI | `.gemini/agents/` |
   | OpenCode | `.opencode/agents/` |
   | GitHub Copilot | `.github/agents/` |

   If you can identify your environment → use the corresponding path and proceed to Section 1.

2. **Directory check**: If unsure, check which of these directories exist in the project root: `.claude/`, `.agents/`, `.gemini/`, `.opencode/`, `.github/`. If exactly one exists → use the corresponding platform's agents path.

3. **Ask the user**: If detection fails or multiple directories found, ask:
   "In quale ambiente vuoi generare i file? (selezione multipla possibile)"
   - Claude Code (`.claude/agents/`)
   - Codex (`.agents/agents/`)
   - Gemini CLI (`.gemini/agents/`)
   - OpenCode (`.opencode/agents/`)
   - GitHub Copilot (`.github/agents/`)
   - Altro (`.skills-reloaded/agents/`)

   If multiple selected → generate files in ALL selected directories.
   If "Altro" selected → use `.skills-reloaded/agents/`.

Store the result as the list of `AGENTS_OUTPUT_BASES` to use in subsequent sections.

## 1. Prerequisite
Check that `.skills-reloaded/contexts/TECHNICAL-AREAS.md` exists. If missing, stop and advise: "Run the `explore-context` skill first."

## 2. Create Orchestrator Agent

For each `AGENTS_OUTPUT_BASE`, create `{AGENTS_OUTPUT_BASE}orchestrator.md`:

````markdown
---
name: Orchestrator
description: Breaks down user requests, routes work to the best sub-agent(s) with specific skills, and validates outputs until complete.
---

You are an **Orchestrator**.

# Role
Orchestrator for the work done by the AI agents in this codebase.

# Capabilities
- Analyze user requests and repository context.
- Decompose work into tasks with clear acceptance criteria.
- Identify necessary Skills for each task.
- Select, delegate to, and validate sub-agent outputs.

# Critical Rules (ALWAYS FOLLOW)
1. **Plan First**: Generate a numbered task plan before any action.
2. **Skill-First Delegation**: For every task, explicitly list required Skills (e.g., `git`, `search`, `python-code-reviewer`).
3. **One Step at a Time**: Execute Task 1, STOP, wait for result, validate, then proceed to Task 2.
4. **Delegate, Don't Do**: Delegate implementation to sub-agents in the agents directory.
5. **Context Hygiene**: Give sub-agents only the context they need.

# Workflow

## Phase 1: Analyze & Plan
1. Understand the user's goal.
2. Identify available Agents and Skills.
3. Create execution plan:
    ```text
    1. [ ] Task Name (Agent: [AgentName], Skills: [Skill1, Skill2]) - [Description]
    2. [ ] Task Name (Agent: [AgentName], Skills: [Skill3]) - [Description]
    ```

## Phase 2: Execution Loop
For each task:
1. **Announce**: "Starting Task [N]: [Name]"
2. **Delegate** with this prompt format:
    ```
    ## Required Skills
    Before starting, load these skills: [Skill1], [Skill2]
    ## Task
    [Task description and requirements]
    ```
3. **Wait** for response.
4. **Validate**: If OK → mark [x] and proceed. If not → retry or refine.

## Phase 3: Completion
Review all tasks and report final status to user.

---

# Example

User: "Add a REST API endpoint for user notifications with email support"

**Plan:**
```text
1. [ ] Create notification model (Agent: Data Access Engineer, Skills: Database)
2. [ ] Implement notification service (Agent: Backend Developer, Skills: Messages)
3. [ ] Create API controller (Agent: Backend Developer, Skills: REST API)
4. [ ] Add unit tests (Agent: Backend Developer, Skills: Testing)
```

**Task 2 delegation:**
```
## Required Skills
Before starting, load these skills: Messages
## Task
Create NotificationService: interface + implementation supporting create, type filtering (info/warning/error), email for critical, and read/unread status.
```
````

## 3. Create Sub-Agents

Read and parse `.skills-reloaded/contexts/TECHNICAL-AREAS.md`.

### 3.1 Design the Team — Think Like a Tech Lead Hiring for a Real Project

Before creating any file, reason about the team composition as a **Tech Lead staffing a new project team**.

Your goal is NOT to create one agent per technical area. Instead, **group related technical areas into broader, well-rounded professional roles** — the same way a real hiring manager would staff a small, high-performing team.

**Constraints:**
- Create **at most 6 agents** (5–6 is the sweet spot; fewer is better than more).
- Each agent must cover **multiple related technical areas**, not a single narrow skill.
- Agent names must be **professional role titles** (e.g., "Full-Stack Developer", "DevOps Engineer"), not technology names (NOT "React Agent" or "PostgreSQL Expert").
- Each agent must be **genuinely useful across many tasks**, not hyper-specialized to a single framework or tool.

**How to group:**
- Merge frontend technologies (UI frameworks, styling, state management, routing, etc.) into one or two broad roles.
- Merge backend technologies (APIs, business logic, services, background jobs, etc.) into one role.
- Merge data concerns (databases, ORM, migrations, queries, caching) into one role.
- Merge infrastructure/platform concerns (CI/CD, deployment, containerization, cloud) into one role.
- Add a QA/Testing role only if testing is a significant area in the codebase.
- Add a cross-cutting role (security, architecture, code quality) only if clearly warranted.

**Before writing any files**, output a short team design summary:
```
## Proposed Team Composition
- [Role Name]: covers [Area1, Area2, Area3, ...]
- [Role Name]: covers [Area4, Area5, ...]
...
```
This makes the grouping reasoning visible and reviewable.

### 3.2 Create Agent Files

For each role in the proposed team composition:

1. Collect all technical details, guidelines, and context from the relevant areas in `TECHNICAL-AREAS.md`.
2. **Filename**: Use a professional role name (e.g., `fullstack-developer.md`, NOT `react.md`). For each `AGENTS_OUTPUT_BASE`, create `{AGENTS_OUTPUT_BASE}[role-name].md`.
3. **Template**:
    ```markdown
    ---
    name: {{agent_name — Professional Role Title, e.g. "Full-Stack Developer"}}
    description: {{agent_description — explain the breadth of responsibilities and when to use this agent}}
    ---

    You are a **{{agent_name}}**.

    # Role
    {{role_description — describe the full scope of the role, not just one technology}}

    # Capabilities
    {{capabilities_bullet_list — cover all technical areas this agent is responsible for}}

    # Rules & Guidelines
    {{rules_bullet_list — include guidelines from all merged technical areas}}
    ```
4. Create the file consolidating all relevant technical details, patterns, and context from `TECHNICAL-AREAS.md` for the merged areas.
