# macctl

macOS window control for AI agents: find a window, capture it, and drive
it (click, type, scroll, press controls by name) while the human keeps
using the same machine. Swift, Apple frameworks only.

## Permissions

Screen Recording and Accessibility are granted to the host app that
spawns macctl (Paseo, iTerm), not to the binary, so rebuilds never
re-prompt. `macctl status` exits 1 unless the screen is unlocked and both
are granted. Without Screen Recording, `shot` refuses and window titles
are hidden, so `-a`/`-t` lookups find nothing.

## Commands

Coordinates are window-relative points; captures are scaled so one pixel
is one point. `<sel>` is `-w ID`, or `-a NAME` and/or `-t SUBSTRING`.
The lookup searches every Space, and the frontmost match wins, with a
note on stderr.

| Command                                   | Does                          |
| ----------------------------------------- | ----------------------------- |
| `status`                                  | lock, permissions, frontmost  |
| `windows [-a NAME] [-t SUB] [--onscreen]` | list windows, tab-separated   |
| `shot <sel> [-o PATH] [--full]`           | capture, print the path       |
| `click <sel> X Y`                         | left click                    |
| `fill <sel> X Y TEXT [--no-tab]`          | click, Cmd+A, type, Tab       |
| `type <sel> TEXT`                         | type into the focused field   |
| `key <sel> KEYNAME [--cmd --shift ...]`   | one key press                 |
| `scroll <sel> LINES [--at X Y]`           | negative scrolls down         |
| `wait <sel> [--timeout S] [--baseline P]` | wait for a change, then quiet |
| `tree <sel> [--depth N] [--all]`          | accessible elements           |
| `text <sel> [--region X Y W H]`           | text on screen, by y          |
| `press <sel> NAME`                        | press a control by name       |
| `set <sel> NAME VALUE`                    | set a field by name, or fill  |

Commands that act (click, fill, type, key, scroll, press, set) take
`--wait`, which afterwards waits for the window to change from its
pre-action capture and settle. `wait` and `--wait` print
`changed <capture>`, or on timeout `unchanged` or `unsettled` (changed,
never settled). click, fill and set take `--prime PX PY`, a blank point
in the window that is clicked before the action, and after `fill` clicked
again so no field is left focused.

`press`/`set` match NAME against the AX title, description, or DOM id of
web content, exactly and then as a substring. After exact controls,
`press` also matches static text, exactly only, so a custom dropdown's
options are reachable; text is clicked, not pressed. In a browser,
elements of the page win over the browser's own, such as its toolbar's
Back. An element without AXPress is clicked at its centre through the
input path below, with a note on stderr. `text` prints static text and
field values inside the window, or `--region`, and in a browser the
page's only, one per line as `y<tab>text`, sorted by y and then page
order. See `macctl --help`.

Exit codes: 0 ok; 1 error, nothing sent; 2 no change confirmed, because
the wait timed out or something failed after input was sent, including
an AXPress or value write that errored and may still have landed. On 2,
look before acting again.

## Disruption contract

Captures never activate, raise, or move anything, and neither do AX
commands unless the window is on another Space (see below). Every input
command:

1. Refuses if the screen is locked.
2. Saves the cursor position, the frontmost app, and the target app's
   main window (if on screen).
3. Raises the window and activates the app (also via `AXFrontmost`),
   then polls up to ~1s until the app is frontmost and the window key.
   Otherwise it sends nothing and exits 1. The coordinates were resolved
   against the window's old frame, so if it moved while coming forward,
   nothing is sent either.
4. Clicks `--prime PX PY` first, if given (and again after a `fill`).
5. Posts the events to the HID tap with explicit modifier flags. Before
   each press it checks that the target window is still the key window;
   if focus moved to another app or another window of the same app, it
   stops, still sending releases, and exits 2. A check the app is too
   busy to answer counts as unmoved, so a slow page can't abort a `fill`
   halfway through.
6. Moves the cursor back, re-raises the app's previous main window, and
   re-activates the previous app, on every exit path including an abort.
7. With `--wait`, polls captures only.

Each line of `scroll` is a posted event with a pause, so a large count
would hold the target frontmost for minutes. Hence the cap of ±1000
lines.

The target stays frontmost for roughly 0.5-1 s per command, plus 24 ms
per typed character. Keystrokes the human types meanwhile land in it.

`tree`, `text`, `press` and `set` ask the app's accessibility tree, so
they never activate or move anything, except in two cases that go
through steps 1-6 above. An app lists only the windows on the current
Space, so a window on another Space is brought forward (switching
Spaces) for the duration of the command. And `press` on an element
without AXPress, or `set` on a field that refuses the value, falls back
to a click or a fill. Firefox-family browsers expose web content to
accessibility, with DOM ids, so on a web page these are the first
choice and coordinates the fallback.

## Quirks

- Firefox (and Zen) drops the first click into a window that just became
  key. Every click is preceded by a mouse move and 100 ms of hover, which
  in testing was enough; `--prime` remains for pages where it isn't.
- A field left focused catches whatever the human types during the next
  command's brief activation, and after `fill`'s Tab the next field's
  text is selected, so a keystroke replaces it. `fill --prime` ends by
  clicking the blank point, which drops focus.
- Firefox settles its own focus after AppKit reports the window key, so
  input waits 250 ms after a fresh activation.
- A scroll event that inherits a modifier zooms the page, so every event
  carries explicit flags. `key 0 --cmd` resets zoom.
- A warp sends no event, so the page would keep the hover style and
  `--wait` would see a change the click didn't make. So the cursor is
  returned with a posted mouse move, not a warp.
- Nothing is sent until the target is verifiably key, so `escape` is
  allowed. Still avoid it, as reaching the host app would cancel the
  agent's running tool call.
- `tree`, `press` and `set` set `AXEnhancedUserInterface` (browsers) and
  `AXManualAccessibility` (Electron) on the app, and leave them set, so
  it builds an accessibility tree, which can slow the app and disturb
  window animations.
- Browsers apply an accessibility value write asynchronously, so `set`
  polls for up to 0.5 s before concluding the field didn't take it.
- Firefox lists AXPress on static text whose page has a click listener
  on an ancestor, which pages built on React and the like have on every
  element, but that press is a synthetic click a mousedown handler never
  sees. So `press` clicks text for real.
- `wait` compares the whole window, so unrelated churn in it, such as a
  fading scrollbar or a sidebar badge, can report a change the action
  didn't make. That is the safe direction; look at the capture.

## Limitations

- Capturing a window on another Space works; a minimized window is
  untested.
- Driving a window on another Space, and AX commands on one, rely on
  activation switching Spaces there and back. If the app has another
  window on the current Space, activating it may not switch, and the
  command fails having sent nothing.
- Single-character KEYNAMEs use US ANSI key codes, so shortcuts assume
  that layout; with modifiers, other characters are refused. Typed text
  is layout-independent.
