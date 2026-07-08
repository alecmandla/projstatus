#!/bin/bash
#
# smoke.sh — golden-ish checks for projstatus, run on stock macOS bash 3.2.
#
# Each fixture under tests/fixtures/ is copied to a temp dir and `git init`ed
# there so projstatus sees it as its own repo (not this one). Output is piped
# (no tty), so colors are off and assertions are plain-text greps.
#
#   tests/smoke.sh            run everything
#   tests/smoke.sh depth3     run one fixture's checks

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../projstatus"
BASH_BIN="/bin/bash"
ONLY="${1:-}"

# Stable width regardless of terminal (old + new env var names).
export MNEMO_COLS=72 PROJSTATUS_COLS=72

PASS=0; FAIL=0
WORK="$(mktemp -d "${TMPDIR:-/tmp}/projstatus-smoke.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

fixture_dir() {  # copies fixture $1 into a fresh git repo, prints its path
  local src="$HERE/fixtures/$1" dst="$WORK/$1"
  rm -rf "$dst"; cp -R "$src" "$dst"
  (cd "$dst" && git init -q)
  printf '%s' "$dst"
}

run() {  # run <fixture-path> [args…] — runs projstatus in the fixture
  local d="$1"; shift
  (cd "$d" && "$BASH_BIN" "$SCRIPT" "$@" 2>&1)
}

assert_contains() {  # assert_contains <desc> <haystack> <needle>
  if printf '%s' "$2" | grep -qF -- "$3"; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    printf 'FAIL: %s\n  wanted: %s\n  got:\n%s\n' "$1" "$3" "$(printf '%s' "$2" | sed 's/^/    /')" >&2
  fi
}

assert_not_contains() {
  if printf '%s' "$2" | grep -qF -- "$3"; then
    FAIL=$((FAIL+1))
    printf 'FAIL: %s\n  did not want: %s\n' "$1" "$3" >&2
  else
    PASS=$((PASS+1))
  fi
}

want() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

# --- syntax: parses under bash 3.2 -------------------------------------------
if want syntax; then
  if "$BASH_BIN" -n "$SCRIPT"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: bash -n" >&2; fi
fi

# --- depth3: the classic project → milestone → task layout, zero config ------
if want depth3; then
  d="$(fixture_dir depth3)"

  out="$(run "$d")"   # pointer view → milestone-1-core
  assert_contains "depth3 pointer: project line"    "$out" "Project 0"
  assert_contains "depth3 pointer: milestone line"  "$out" "Milestone 1"
  assert_contains "depth3 pointer: is the pointer"  "$out" "◆ current pointer"
  assert_contains "depth3 pointer: pointer state"   "$out" "in progress"
  assert_contains "depth3 pointer: open task"       "$out" "P0M1T1"
  assert_contains "depth3 pointer: task title"      "$out" "Test the core loop"
  assert_contains "depth3 pointer: tasks count"     "$out" "1/3 done"
  assert_contains "depth3 pointer: gaps section"    "$out" "GAP-P0M1-1"
  assert_contains "depth3 pointer: gap severity"    "$out" "[High]"
  assert_contains "depth3 pointer: issues section"  "$out" "ISS-P0M1-0"

  out="$(run "$d" P0M0)"
  assert_contains "depth3 P0M0: done milestone"     "$out" "Milestone 0"
  assert_contains "depth3 P0M0: all done"           "$out" "2/2 done"
  assert_contains "depth3 P0M0: past marker"        "$out" "↩ past"

  out="$(run "$d" P0)"
  assert_contains "depth3 P0: project header"       "$out" "Project 0 · Foundations"
  assert_contains "depth3 P0: milestone row"        "$out" "M1 core"

  out="$(run "$d" P2)"
  assert_contains "depth3 P2: summary only"         "$out" "summary only"
  assert_contains "depth3 P2: summary bullet"       "$out" "parking lot"

  out="$(run "$d" ls)"
  assert_contains "depth3 ls: project 0"            "$out" "P0 · Foundations"
  assert_contains "depth3 ls: project 1"            "$out" "P1 · Growth"
  assert_contains "depth3 ls: summary-only project" "$out" "P2 · Later"
  assert_contains "depth3 ls: milestone row"        "$out" "M0 setup"

  out="$(run "$d" view P0M1; cat "$d/.git/projstatus-view")"
  assert_contains "depth3 view: token round-trip"   "$out" "P0M1"

  out="$(run "$d" Z9)"
  assert_contains "depth3 bad selector"             "$out" "unknown selector"
fi

# --- depth2: a single folder level (milestone → task), zero config -----------
if want depth2; then
  d="$(fixture_dir depth2)"

  out="$(run "$d")"   # no pointer line → first unfinished milestone
  assert_contains "depth2 pointer: milestone line" "$out" "Milestone 0"
  assert_contains "depth2 pointer: is the pointer" "$out" "◆ current pointer"
  assert_contains "depth2 pointer: open task"      "$out" "M0T1"
  assert_contains "depth2 pointer: overall bar"    "$out" "Overall"
  assert_not_contains "depth2 pointer: no second level" "$out" "Project"

  out="$(run "$d" M1)"
  assert_contains "depth2 M1: leaf view"           "$out" "Milestone 1"
  assert_contains "depth2 M1: task"                "$out" "M1T0"
  assert_contains "depth2 M1: upcoming"            "$out" "↪ upcoming"

  out="$(run "$d" ls)"
  assert_contains "depth2 ls: row 0"               "$out" "M0 mvp"
  assert_contains "depth2 ls: row 1"               "$out" "M1 polish"

  out="$(run "$d" view M1; cat "$d/.git/projstatus-view")"
  assert_contains "depth2 view: token round-trip"  "$out" "M1"
fi

# --- depth4: initiative → project → milestone → task, zero config -------------
if want depth4; then
  d="$(fixture_dir depth4)"

  out="$(run "$d")"   # pointer → milestone-1-endpoints
  assert_contains "depth4 pointer: initiative crumb" "$out" "Initiative 0"
  assert_contains "depth4 pointer: project crumb"    "$out" "Project 0"
  assert_contains "depth4 pointer: milestone line"   "$out" "Milestone 1"
  assert_contains "depth4 pointer: open task"        "$out" "I0P0M1T0"
  assert_contains "depth4 pointer: parent bar label" "$out" "Project 0"

  out="$(run "$d" I0P0M0)"
  assert_contains "depth4 full token: leaf"          "$out" "Milestone 0"
  assert_contains "depth4 full token: task"          "$out" "I0P0M0T0"
  assert_contains "depth4 full token: past"          "$out" "↩ past"

  out="$(run "$d" I0P0)"
  assert_contains "depth4 mid token: project header" "$out" "Project 0 · Api"
  assert_contains "depth4 mid token: milestone rows" "$out" "M0 schema"
  assert_contains "depth4 mid token: pointer marker" "$out" "▸"

  out="$(run "$d" I0)"
  assert_contains "depth4 top token: header"         "$out" "Initiative 0 · Platform"
  assert_contains "depth4 top token: project row"    "$out" "P0 api"
  assert_contains "depth4 top token: aggregate"      "$out" "1/3"

  out="$(run "$d" ls)"
  assert_contains "depth4 ls: initiative row"        "$out" "I0 · Platform"
  assert_contains "depth4 ls: nested project row"    "$out" "P0 · Api"
  assert_contains "depth4 ls: leaf row"              "$out" "M1 endpoints"
  assert_contains "depth4 ls: other initiative"      "$out" "I1 · Growth"

  out="$(run "$d" view I0P1M0; cat "$d/.git/projstatus-view")"
  assert_contains "depth4 view: deep token round-trip" "$out" "I0P1M0"

  out="$(run "$d" view I1; cat "$d/.git/projstatus-view")"
  assert_contains "depth4 view: partial token round-trip" "$out" "I1"

  out="$(run "$d" milestone-0-shell)"
  assert_contains "depth4 slug selector"             "$out" "I0P1M0T0"

  out="$(run "$d" I0P9)"
  assert_contains "depth4 missing mid level"         "$out" "no project 9 under I0"
fi

# --- hierarchy config: explicit HIERARCHY key overrides auto-detect ----------
if want hierarchy; then
  d="$(fixture_dir depth2)"
  # task IDs in the fixture stay M0T0-style, so pin TASK_RE alongside
  printf 'HIERARCHY="milestone-:Sprint:S"\nTASK_RE="^## M[0-9]+T[0-9]+:"\n' >> "$d/.projstatus"

  out="$(run "$d")"
  assert_contains "hierarchy: custom label"          "$out" "Sprint 0"
  out="$(run "$d" S1)"
  assert_contains "hierarchy: custom letter selects" "$out" "Sprint 1"
fi

# --- legacy: milestone → phase via the old OUTER_*/INNER_* keys --------------
if want legacy; then
  d="$(fixture_dir legacy)"

  out="$(run "$d")"   # no pointer line → first unfinished phase
  assert_contains "legacy pointer: outer label"     "$out" "Milestone 0"
  assert_contains "legacy pointer: inner label"     "$out" "Phase 0"
  assert_contains "legacy pointer: open task"       "$out" "M0P0T1"

  out="$(run "$d" M0P1)"
  assert_contains "legacy M0P1: phase view"         "$out" "Phase 1"
  assert_contains "legacy M0P1: task"               "$out" "M0P1T0"

  out="$(run "$d" ls)"
  assert_contains "legacy ls: outer row"            "$out" "M0 · Foundation"
  assert_contains "legacy ls: inner row"            "$out" "P0 init"

  out="$(run "$d" view M0P0; cat "$d/.git/projstatus-view")"
  assert_contains "legacy view: token round-trip"   "$out" "M0P0"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
