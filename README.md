# projstatus

A live, interactive terminal dashboard for repos that use a **project → milestone → task**
hierarchy (the kind that mirrors Linear). Shows where you are, what's done, what's left —
tasks, gaps, and issues — and follows you as you work. Built to live in a side pane.

```
  MYPROJECT ▸ status                          14:09:29
  ────────────────────────────────────────────────────
  Project 0 · Foundations
  Milestone 2 — data foundation
  ◆ current pointer — ready to start

  Tasks                                        0/7 done
  ────────────────────────────────────────────────────
  ○ P0M2T0  Install and configure expo-sqlite …
  …
  Gaps                                         4/5 done
  ○ GAP-P0M1-3  [Low] Add an .easignore …
```

## Install

```sh
git clone <this> ~/Tools/projstatus
ln -sf ~/Tools/projstatus/projstatus /opt/homebrew/bin/projstatus   # any dir on your PATH
```

## Use

Run it inside any git repo with the hierarchy:

```sh
projstatus              # the current milestone (the pointer), once
projstatus P0M1         # peek at any milestone
projstatus P2           # a project overview (or its outline if summary-only)
projstatus ls           # every project + milestone at a glance
projstatus --watch      # the live, interactive pane
projstatus pane         # open the live pane in a Supacode split
projstatus view <sel>   # retarget a running pane from another shell
```

In the live pane, click to focus it, then press:

| key | |
|----|----|
| `n` / `p` | next / previous milestone |
| `c` | jump to the live pointer |
| `a` | all-projects overview |
| `g` | go to a specific one (type e.g. `P2`, then Enter) |
| `r` | refresh now |
| `q` | quit |

When not focused, the pane just auto-refreshes (default every 4s) and follows your work.
Redraws are flicker-free (in-place, no screen clear). The pane's target is remembered in
`.git/projstatus-view` (untracked).

## What it reads (the convention)

```
<tasks-root>/project-<n>-<slug>/milestone-<m>-<slug>/TASKS.md
                                                     /GAPS.md     (optional)
                                                     /ISSUES.md   (optional)
```

- **Tasks** — `## <ID>: Title` headers, each with `- **Status:** \`[x] DONE\`` or `\`[ ] TODO\``.
- **Gaps** — `### GAP-… : Title` + `**Status:**` + `**Severity:**`.
- **Issues** — `### ISS-… : Title` + `**Status:**` + `**Priority:**`.
- **Pointer** — a line matching `Current pointer:` with the milestone slug in backticks
  (e.g. in `AGENTS.md`). **Optional** — without it, "current" auto-resolves to the first
  milestone that still has unfinished tasks.

## Adapting it to a project

Everything is auto-detected, so standard repos need **nothing**. For anything different,
drop a `.projstatus` file at the repo root (plain `KEY="value"` lines) — see
[`.projstatus.example`](.projstatus.example). All keys are optional:

| key | default |
|----|----|
| `PROJECT_NAME` | the repo folder name |
| `TASKS_ROOT` | first of `docs/tasks`, `tasks`, `planning/tasks` that exists |
| `POINTER_FILE` / `POINTER_PATTERN` | `AGENTS.md` / `Current pointer:` |
| `INBOX` | auto-detected (`docs/ISSUES_INBOX.md`, …) |
| `TASK_RE` / `GAP_RE` / `ISS_RE` | `^## P\d+M\d+T\d+:` / `^### GAP-` / `^### ISS-` |
| `WIDTH_CAP` / `REFRESH` | `72` / `4` |

No dependencies beyond bash, awk, sed, grep, git. Tested on stock macOS bash 3.2.
