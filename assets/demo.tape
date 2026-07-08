# demo.tape — VHS script for the README demo gif.
#
#   brew install vhs
#   vhs assets/demo.tape        # run from the projstatus repo root; writes assets/demo.gif
#
# Uses ~/Tools/sowtime, a small demo repo with the standard layout
# (docs/tasks/project-0-mvp/milestone-{0,1}-…/TASKS.md). The hidden
# background job (assets/demo-edits.sh) marks a checklist item and then a
# whole task done while `projstatus watch` is recording, so the gif shows
# the dashboard following the markdown live.

Output assets/demo.gif
Set FontSize 15
Set Width 1000
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Invisible setup: a clean slate (in case a previous take left edits behind)
# and a snappy refresh for the recording.
Hide
Type "cd ~/Tools/sowtime && git checkout -- docs && export REFRESH=1 && clear"
Enter
Sleep 1s
Show

Type "projstatus"
Enter
Sleep 4s

Type "projstatus now"
Enter
Sleep 3.5s

# Invisible: kick off the timed edits, then put the live pane on camera.
Hide
Type "sh ~/Tools/projstatus/assets/demo-edits.sh & clear"
Enter
Sleep 500ms
Show

Type "projstatus watch"
Enter
Sleep 12s        # edits land at ~5s and ~9s: sub-count 1/2 → 2/2, tasks 3/5 → 4/5

Type "a"         # the whole tree, from inside the pane
Sleep 3.5s

Type "q"
Sleep 1s

# Invisible teardown: put the demo repo back the way we found it.
Hide
Type "git checkout -- docs"
Enter
Sleep 500ms
