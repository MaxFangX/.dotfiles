// `macctl`: usage, argument parsing, and dispatch to the commands.

import AppKit

let usage = """
    usage: macctl <command> [<sel>] [args]

    Window selection <sel>, for every command but status and windows:
      -w, --window ID        window number from `macctl windows`; wins
      -a, --app NAME         owning app name, case-insensitive exact match
      -t, --title SUBSTRING  case-insensitive title substring
    -a/-t search every Space; of several matches, the frontmost wins.

    Coordinates are window-relative points. Captures are scaled so one
    pixel is one point: a coordinate read off a capture is the one to click.

    Commands:
      status        lock state, permissions, frontmost app; exit 1 unless
                    unlocked with Screen Recording and Accessibility
      windows [-a NAME] [-t SUBSTRING] [--onscreen]
                    id pid x y w h onscreen app title, tab-separated
      shot <sel> [-o PATH] [--full]
                    capture (default /tmp/macctl/<id>.png), print the
                    path; --full keeps native resolution
      click <sel> X Y [--prime PX PY] [--wait]
      fill <sel> X Y TEXT [--no-tab] [--prime PX PY] [--wait]
                    click, Cmd+A, type TEXT (empty: Delete), Tab
      type <sel> TEXT [--wait]
      key <sel> KEYNAME [--cmd] [--shift] [--alt] [--ctrl] [--wait]
                    KEYNAME: one character, or return tab space delete
                    escape up down left right home end pageup pagedown
                    f1..f12
      scroll <sel> LINES [--at X Y] [--wait]
                    negative scrolls down; default at (2/3 w, 1/2 h)
      wait <sel> [--timeout SECS] [--baseline PATH]
                    capture every second until the window differs from
                    the baseline and two captures match; print
                    "changed <capture>", or after SECS (15) "unchanged
                    <capture>" (or "unsettled" if it changed but never
                    stopped), exit 2. PATH must be a default-scale shot
                    of this window: against a --full one everything
                    differs, so it reports a change at once

    Through Accessibility, with no activation unless the window is on
    another Space (browsers expose web pages):
      tree <sel> [--depth N] [--all]
                    interactive elements as role x y w h title
                    description id value, tab-separated (id: the web
                    page's DOM id); --all adds static text; N: 100
      text <sel> [--region X Y W H]
                    static text and field values on screen (or in the
                    region), top to bottom, as y<tab>text
      press <sel> NAME [--wait]
                    AXPress the element whose title, description or id
                    is NAME, else static text reading NAME, else one
                    whose label contains it; click it if it has no
                    AXPress (custom dropdown options)
      set <sel> NAME VALUE [--prime PX PY] [--wait]
                    set the value of the text field matched as for
                    press; if the app rejects that, fill it

    Input commands (click fill type key scroll, and press's and set's
    fallbacks) raise the window only while sending, then restore the
    cursor and the frontmost app and window. They send nothing unless the
    window is key. AX commands on another Space raise it the same way.
      --prime PX PY  (click fill set) a blank point in the window, clicked
                     before the action (Firefox drops the first click into
                     a window that just became key) and, after fill, again
                     at the end, so no field is left focused for a stray
                     keystroke
      --wait         (click fill type key scroll press set) then wait, with
                     the pre-action capture as baseline
      --             end of flags, for TEXT starting with '-'

    Exit status: 0 ok; 1 error, nothing sent; 2 no change confirmed
    (wait timed out, or a failure after input was sent): look before
    acting again.
    """

let argv = Array(CommandLine.arguments.dropFirst())
guard let name = argv.first else {
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(1)
}
if ["-h", "--help", "help"].contains(name) {
    print(usage)
    exit(0)
}
guard let command = Command(rawValue: name) else {
    fail("unknown command '\(name)' (see macctl --help)")
}
let args = parse(command, argv.dropFirst())

if command == .status { exit(status() ? 0 : 1) }
if command == .windows {
    let found = windows(
        app: args["--app"], title: args["--title"],
        onscreenOnly: args.has("--onscreen"))
    found.forEach { print($0.line) }
    exit(0)
}

let win = selectWindow(args)
let prime = args.flags["--prime"].map { point(win, $0) }
switch command {
case .status, .windows:
    preconditionFailure("\(command) is handled above")
case .shot:
    print(capture(win, to: args["--output"], full: args.has("--full")))
case .wait:
    let timeout: TimeInterval? = args["--timeout"].map { number($0, "SECS") }
    let baseline = pixels(args["--baseline"] ?? capture(win))
    waitForChange(win, from: baseline, timeout: timeout)
case .tree:
    let depth: Int = args["--depth"].map { number($0, "N") }
        ?? defaultTreeDepth
    printTree(win, depth: depth, all: args.has("--all"))
case .text:
    let region = args.flags["--region"].map { r -> CGRect in
        let n: [Double] = zip(r, ["X", "Y", "W", "H"]).map(number)
        return CGRect(x: n[0], y: n[1], width: n[2], height: n[3])
    }
    printText(win, region: region)
case .press:
    acting(win, args) { press(win, name: args.positionals[0]) }
case .set:
    acting(win, args) {
        let (name, value) = (args.positionals[0], args.positionals[1])
        setValue(win, name: name, value: value, prime: prime)
    }
case .click, .fill, .key, .scroll, .type:
    let events = inputEvents(command, win, args, blank: prime)
    acting(win, args) { drive(win, prime: prime, events) }
}

/// Runs `action`; with --wait, then waits for the window to change from
/// how it looked before.
private func acting(_ win: Window, _ args: Args, _ action: () -> Void) {
    let baseline = args.has("--wait") ? pixels(capture(win)) : nil
    action()
    if let baseline { waitForChange(win, from: baseline) }
}

enum Command: String {
    case status, windows, shot, click, fill, type, key, scroll, wait
    case tree, text, press, set

    /// Positional count and accepted flags, written as in the usage, so
    /// "--at X Y" takes two values.
    var grammar: (positionals: Int, flags: [String]) {
        let sel = ["--window ID", "--app NAME", "--title SUBSTRING"]
        let prime = "--prime PX PY"
        switch self {
        case .status: return (0, [])
        case .windows:
            return (0, ["--app NAME", "--title SUBSTRING", "--onscreen"])
        case .shot: return (0, sel + ["--output PATH", "--full"])
        case .click: return (2, sel + [prime, "--wait"])
        case .fill: return (3, sel + [prime, "--no-tab", "--wait"])
        case .type: return (1, sel + ["--wait"])
        case .key:
            let modifiers = ["--cmd", "--shift", "--alt", "--ctrl"]
            return (1, sel + modifiers + ["--wait"])
        case .scroll: return (1, sel + ["--at X Y", "--wait"])
        case .wait: return (0, sel + ["--timeout SECS", "--baseline PATH"])
        case .tree: return (0, sel + ["--depth N", "--all"])
        case .text: return (0, sel + ["--region X Y W H"])
        case .press: return (1, sel + ["--wait"])
        case .set: return (2, sel + [prime, "--wait"])
        }
    }
}

/// A command's parsed arguments: positionals, and flag values by long
/// flag name.
struct Args {
    var positionals: [String] = []
    var flags: [String: [String]] = [:]

    subscript(flag: String) -> String? { flags[flag]?.first }
    func has(_ flag: String) -> Bool { flags[flag] != nil }
}

/// Parses `command`'s arguments; fails on unknown flags or a wrong number
/// of positionals.
private func parse(_ command: Command, _ argv: ArraySlice<String>) -> Args {
    let grammar = command.grammar
    let arity = Dictionary(uniqueKeysWithValues: grammar.flags.map { flag in
        let words = flag.split(separator: " ")
        return (String(words[0]), words.count - 1)
    })
    let aliases = [
        "-a": "--app", "-o": "--output", "-t": "--title", "-w": "--window",
    ]

    var args = Args()
    var rest = argv
    while let token = rest.popFirst() {
        if token == "--" {
            args.positionals += rest
            break
        }
        if token == "-h" || token == "--help" {
            print(usage)
            exit(0)
        }
        // Other dashed tokens, such as negative amounts, are positionals.
        let second = token.dropFirst().first
        guard token.hasPrefix("-"), second == "-" || second?.isLetter == true
        else {
            args.positionals.append(token)
            continue
        }
        let flag = aliases[token] ?? token
        guard let n = arity[flag] else {
            fail("\(command): unknown flag \(token)")
        }
        guard rest.count >= n else {
            fail("\(command): \(token) takes \(n) value(s)")
        }
        args.flags[flag] = Array(rest.prefix(n))
        rest = rest.dropFirst(n)
    }

    let want = grammar.positionals
    guard args.positionals.count == want else {
        let got = args.positionals.count
        fail("\(command) takes \(want) argument(s), got \(got)")
    }
    return args
}

/// Validates an input command's arguments; returns the events to send.
private func inputEvents(
    _ command: Command, _ win: Window, _ args: Args, blank: CGPoint?
) -> (Sender) -> Void {
    let positionals = args.positionals
    switch command {
    case .click:
        let p = point(win, positionals)
        return { $0.click(p) }
    case .fill:
        let p = point(win, positionals)
        let tab = !args.has("--no-tab")
        return { $0.fill(p, positionals[2], tab: tab, blank: blank) }
    case .key:
        let name = positionals[0]
        let modifiers: [(String, CGEventFlags)] = [
            ("--alt", .maskAlternate), ("--cmd", .maskCommand),
            ("--ctrl", .maskControl), ("--shift", .maskShift),
        ]
        let flags = CGEventFlags(
            modifiers.filter { args.has($0.0) }.map { $0.1 })
        guard let key = keyCode(name, shortcut: !flags.isEmpty) else {
            let hint = flags.isEmpty ? "" : " (with modifiers, use a US key)"
            fail("unknown KEYNAME '\(name)'\(hint)")
        }
        return { $0.pressKey(key.code, flags: flags, text: key.text) }
    case .scroll:
        // Each line is a posted event with a pause, so a careless large
        // number would hold the target frontmost for minutes, catching
        // everything the human types meanwhile.
        let maxLines = 1000
        let lines: Int = number(positionals[0], "LINES")
        guard abs(lines) <= maxLines else {
            fail("LINES beyond ±\(maxLines)")
        }
        let f = win.frame
        let at = args.flags["--at"].map { point(win, $0) }
            ?? CGPoint(x: f.minX + f.width * 2 / 3, y: f.midY)
        return { $0.scroll(lines, at: at) }
    case .type:
        let text = positionals[0]
        guard !text.isEmpty else { fail("TEXT is empty") }
        return { $0.typeText(text) }
    default:
        preconditionFailure("\(command) is not an input command")
    }
}

/// Screen point for window-relative ["X", "Y"]; fails outside the window.
private func point(_ win: Window, _ xy: [String]) -> CGPoint {
    guard let p = win.screenPoint(number(xy[0], "X"), number(xy[1], "Y"))
    else {
        let size = "\(Int(win.frame.width))x\(Int(win.frame.height))"
        fail("\(xy[0]),\(xy[1]) is outside the \(size) window")
    }
    return p
}

private func number<T: LosslessStringConvertible>(
    _ raw: String, _ name: String
) -> T {
    guard let n = T(raw) else { fail("bad \(name) '\(raw)'") }
    return n
}

func fail(_ message: String) -> Never {
    restoreFocus?()
    warn(inputSent ? "input sent, but \(message)" : message)
    exit(inputSent ? 2 : 1)
}

func warn(_ message: String) {
    FileHandle.standardError.write(Data("macctl: \(message)\n".utf8))
}
