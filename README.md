# claude-agents-skills

Personal Claude Code agents and skills — installable on any machine with one command.

## Install

```bash
git clone https://github.com/Gowtham1495/claude-agents-skills.git
cd claude-agents-skills
bash install.sh
```

Restart Claude Code. All agents and skills will be available.

## Update

```bash
cd claude-agents-skills
git pull
bash install.sh
```

---

## Agents

| Agent | Trigger | Purpose |
|---|---|---|
| `planner` | `/planner` | Clarifies requirements, writes a structured plan file to `.claude/plans/` |
| `developer` | `/developer` | Full-stack implementation (Angular + Spring Boot). Reads CLAUDE.md and plan files. |
| `tester` | `/tester` | Creates/updates Playwright E2E tests. Reads CLAUDE.md for fixture patterns. |

## Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `feature-planning` | `/feature-planning` | Tech-agnostic planning checklist and plan file template |
| `angular` | `/angular` | Angular 17+ signals, components, services, RBAC guards |
| `spring-boot` | `/spring-boot` | Controller-Service-Repository, PATCH DTOs, security, testing |
| `liquibase` | `/liquibase` | DB migration two-file rule, YAML format, NOT NULL backfill |
| `playwright` | `/playwright` | Token auth, API helpers, cleanup, selectors, RBAC tests |
| `pptx` | `/pptx` | Client-side PowerPoint export with PptxGenJS |

---

## Adding a new agent or skill

**New agent:**
```bash
# Create in the repo
cp agents/planner.md agents/my-agent.md
# Edit it, then sync to ~/.claude/agents/
bash install.sh
# Commit and push
git add agents/my-agent.md && git commit -m "add my-agent" && git push
```

**New skill:**
```bash
mkdir -p skills/my-skill
# Write skills/my-skill/SKILL.md
bash install.sh
git add skills/my-skill && git commit -m "add my-skill skill" && git push
```

---

## Project-specific context

These agents are generic. Project-specific details (package names, RBAC roles, migration versions, test profiles) go in a `CLAUDE.md` file at the project root. Agents read it automatically.
