# projstatus

A live, interactive terminal dashboard for repos that keep their plan as **markdown
task files on disk**, in a Linear-style hierarchy. Shows where you are, what's done,
what's left — tasks, gaps, and issues — and follows you as you work. Built to live in
a side pane. One file, zero dependencies beyond bash/awk/sed/grep/git, runs on stock
macOS bash 3.2.

```
  MYPROJECT ▸ status                          14:09:29
  ────────────────────────────────────────────────────
  Project 0 · Foundations
  Milestone 2 — data foundation
  ◆ current pointer — ready to start

  Tasks                                        1/7 done
  ────────────────────────────────────────────────────
  ● P0M2T0  Install and configure expo-sqlite
  ○ P0M2T1  Define the schema + migrations        2/5
  …
  Gaps                                         4/5 done
  ○ GAP-P0M2-3  [High] Add an .easignore
```

## The hierarchy (Linear-style)

projstatus models the same shape Linear does — pick whatever ordered subset your
repo needs (2–5 levels):

| Linear | on disk | example |
|----|----|----|
| Initiative | a folder level `initiative-<n>-<slug>/` | `initiative-0-platform/` |
| Project | a folder level `project-<n>-<slug>/` | `project-1-core-loop/` |
| Milestone | a folder level `milestone-<n>-<slug>/` | `milestone-2-catalog/` |
| Issue | a `## <ID>: Title` header in `TASKS.md` | `## P1M2T3: Build the list` |
| Sub-issue | a `- [ ]` / `- [x]` checklist line inside the issue's section | acceptance criteria |

Folders are the levels above the leaf (1–4 of them); the innermost folder holds
`TASKS.md` (plus optional `GAPS.md` / `ISSUES.md`). **Depth and naming are
auto-detected** from the folder tree, and each level's selector letter comes from its
prefix — so a `project-*/milestone-*` repo answers to `P0M1`, and an
`initiative-*/project-*/milestone-*` repo answers to `I0P1M2`. Partial selectors
(`P0`, `I0P1`) open overviews at that level.

## Install

```sh
git clone https://github.com/alecmandla/projstatus
ln -sf "$PWD/projstatus/projstatus" /usr/local/bin/projstatus   # any dir on your PATH
```

## Use

Run it inside any repo with the hierarchy:

```sh
projstatus              # the current leaf (the pointer), once
projstatus P0M1         # peek at any level: full tokens reach a leaf …
projstatus P0           # … partial tokens show that level's overview
projstatus ls           # the whole tree at a glance
projstatus next         # plain-text orientation (see below)
projstatus --watch      # the live, interactive pane
projstatus pane         # open the live pane in a Supacode split
projstatus view <sel>   # retarget a running pane from another shell
```

In the live pane, click to focus it, then press:

| key | |
|----|----|
| `n` / `p` | next / previous sibling of the current view |
| `c` | jump to the live pointer |
| `a` | whole-tree overview |
| `g` | go to a specific one (type e.g. `P2` or `P0M1`, then Enter) |
| `r` | refresh now |
| `q` | quit |

When not focused, the pane just auto-refreshes (default every 4s) and follows your
work. Redraws are flicker-free (in-place, no screen clear). The pane's target is
remembered in `.git/projstatus-view` (untracked).

## `projstatus next` — orient a new session

For humans and agents starting cold: one command that says where the project stands,
as stable, grep-able plain text.

```
$ projstatus next
pointer: P1M1  docs/tasks/project-1-core-loop/milestone-1-capture
state: ready to start
next-task: P1M1T7  Wire background auto-enrich trigger after capture
file: docs/tasks/project-1-core-loop/milestone-1-capture/TASKS.md
```

If the pointer's leaf is complete, it says so (`note: …`) and hops to the first open
task anywhere in the tree.

## What it reads (the convention)

```
<tasks-root>/<level>-<n>-<slug>/…/TASKS.md    ← 1–4 folder levels
                                 /GAPS.md     (optional)
                                 /ISSUES.md   (optional)
```

- **Tasks** — `## <ID>: Title` headers, each with `- **Status:** \`[x] DONE\`` or `\`[ ] TODO\``.
- **Sub-issues** — `- [ ]` / `- [x]` checklist lines inside a task's section; open
  tasks show a `done/total` suffix.
- **Gaps** — `### GAP-… : Title` + `**Status:**` + `**Severity:**`.
- **Issues** — `### ISS-… : Title` + `**Status:**` + `**Priority:**`.
- **Pointer** — a line matching `Current pointer:` with the current folder's slug in
  backticks (e.g. in `AGENTS.md`). **Optional** — without it, "current" auto-resolves
  to the first leaf that still has unfinished tasks. The pointer may name any level;
  a group pointer descends to its first unfinished leaf.

Task IDs double nicely as branch/worktree names (`claude/p1m2t3`): keep level
letters distinct and IDs will always lowercase into filesystem- and branch-safe
tokens.

## Adapting it to a repo

Everything is auto-detected — depth, prefixes, labels, and letters come from the
folder tree, so most repos need **nothing**. For anything different, drop a
`.projstatus` file at the repo root (plain `KEY="value"` lines) — see
[`.projstatus.example`](.projstatus.example). All keys are optional:

| key | default |
|----|----|
| `PROJECT_NAME` | the repo folder name |
| `TASKS_ROOT` | first of `docs/tasks`, `tasks`, `planning/tasks` that exists |
| `HIERARCHY` | auto-detected — see below |
| `POINTER_FILE` / `POINTER_PATTERN` | `AGENTS.md` / `Current pointer:` |
| `INBOX` | auto-detected (`docs/ISSUES_INBOX.md`, …) |
| `TASK_RE` / `GAP_RE` / `ISS_RE` | derived from the hierarchy's letters / `^### GAP-` / `^### ISS-` |
| `WIDTH_CAP` / `REFRESH` | `72` / `4` |

`HIERARCHY` declares the folder levels, outermost first — each is
`<folder-prefix>[:<Label>[:<Letter>]]` (label and letter are derived from the prefix
when omitted), plus an optional `@<file>[:<Label>[:<Letter>]]` entry for the leaf
(default `@TASKS.md:Task:T`):

```sh
HIERARCHY="initiative-:Initiative:I project-:Project:P milestone-:Milestone:M"
```

The pre-HIERARCHY two-level keys (`OUTER_PREFIX`/`INNER_PREFIX`, `OUTER_LABEL`/…,
`OUTER_LETTER`/…) still work and imply a two-level hierarchy.

Environment overrides: `PROJSTATUS_COLS` (render width), `PROJSTATUS_NO_CLEAR=1`
(append frames instead of redrawing), `PROJSTATUS_FORCE_TTY=1` (treat stdin as
interactive).

## Tests

```sh
tests/smoke.sh            # all fixtures (2-, 3-, 4-level + legacy keys), bash 3.2
tests/smoke.sh depth4     # one fixture
```
