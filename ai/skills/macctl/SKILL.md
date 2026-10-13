---
name: macctl
description: >-
  Drive a GUI window on this Mac with the `macctl` CLI: find the window,
  screenshot it, read the screen, then click, type, scroll, or press
  controls, while the human keeps using the machine. Use when asked to
  operate, fill in, click through, or screenshot a desktop or browser
  window (web apps, settings panes, dialogs), or to take the wheel on a
  GUI workflow.
---

# Driving a window with macctl

You are working a GUI on the human's own machine while they use it for
other things. The goal is to get through the screens correctly with the
fewest, shortest interruptions. `macctl --help` and the package README
(`~/.dotfiles/pkgs/macctl/README.md`) have the command table, so this
skill covers only how to work.

## Before you start

- Run `macctl status`. Screen Recording and Accessibility are granted to
  the app hosting you (Paseo, iTerm), not to the binary, so if one is
  missing, say which System Settings pane to use and stop. Screen
  Recording takes effect only after the host app relaunches. A grant that
  shows as on but doesn't work means the host app was rebuilt since, so
  the entry must be removed and re-added.
- Find the window once with `macctl windows -a <app> -t <title>`, then pin
  its id with `-w <id>` for the session. Titles change as pages change;
  ids don't. Windows on other Spaces are listed too, and commands switch
  Spaces to bring them forward, which the human accepts. If the app also
  has a window on the current Space, that switch fails and nothing is
  sent, so ask the human to move the window here.

## The loop

Capture, read, act, repeat:

1. `macctl shot -w ID` and read the image yourself. Capture coordinates
   are click coordinates; no conversion. When only the words matter
   (which page is this?), `macctl text` is faster, listing each line of
   on-screen text with its y.
2. Decide the one action the screen calls for. Say what you see and what
   you're about to do before doing it, so the human can follow the
   transcript later.
3. Act with `--wait`: `press NAME` to advance a page, `fill` and `click`
   for the rest. On success the command prints "changed" with the next
   capture; anything else exits non-zero. A second click on a button that
   already worked skips a screen, and pages save slowly, so look again
   rather than acting again. Exit 1 means nothing was sent, so retry
   freely; exit 2 means the input may have landed.
4. Re-capture before any click if the layout may have moved, say a side
   panel closed, a popup appeared, or a field grew.

Prefer `macctl tree` with `press`/`set`, which act through the app's
accessibility tree and never touch focus or the cursor. Browsers expose
the page there, with buttons and fields under their DOM ids, so on a web
app start with `tree` and use coordinates only for what it doesn't list.
A custom dropdown's options are often plain text, so open it and `press`
the option's exact text, which `text` lists.

When the human is doing the clicking instead of you, end every reply
with one explicit line: what to tap and what to enter.

## Disruption contract

Every click, fill, or key briefly makes the target window frontmost and
then hands the cursor, the app, and the window back. So:

- Batch what you can into one command, e.g. `fill`, which clicks, selects,
  types, and tabs in one activation, rather than a key, then a click, then
  a key.
- Keystrokes the human types during that instant can land in the target's
  focused field, so after a page settles, glance at the field you filled
  before moving on.
- Captures never activate anything, and `text` and `tree` do so only to
  reach another Space, so use them freely.
- If `macctl` refuses because the screen is locked or the target never
  became frontmost, nothing was sent. A locked screen is the human
  stepping away, not a fault, so report it and wait rather than polling.

## Quirks worth knowing

- Pass `--prime X Y`, a blank area of the page, on `fill`. It clicks there
  afterwards, so no field stays focused to catch the human's next
  keystroke, and it primes focus for pages that drop a first click.
- Password managers open an autofill menu on a focused field. Dismiss it
  by clicking a blank area of the page, never by picking an entry.
- A stray modifier can zoom the page. `key 0 --cmd` resets it.
- A menu or picklist commits the hovered option when it closes, so close
  it with a click on a blank spot before scrolling.
