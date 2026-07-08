#!/bin/sh
# Timed edits for the demo tape (assets/demo.tape): while `projstatus watch`
# is on camera, finish P0M0T3 the way an agent would — the last checklist
# item first, then the task's status line.
T=~/Tools/sowtime/docs/tasks/project-0-mvp/milestone-0-sowing-calendar/TASKS.md
sleep 5
sed -i '' 's/- \[ \] coming-up list handles the wrap/- [x] coming-up list handles the wrap/' "$T"
sleep 4
sed -i '' '/^## P0M0T3/,/^## P0M0T4/ s/`\[ \] TODO`/`[x] DONE`/' "$T"
