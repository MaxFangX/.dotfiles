// Synthetic input within one activation, restoring focus afterwards.

import AppKit

/// Whether input may have reached the target. Later failures exit 2, not
/// 1, so they can't pass for a refusal and invite a repeated action.
var inputSent = false

/// Undoes an activation, set while one is in effect. An abort that left
/// the target frontmost with a field focused would catch the human's next
/// keystrokes, so `fail` runs it too.
private(set) var restoreFocus: (() -> Void)?

/// How long the app gets to handle the last event before `restoreFocus`.
let restoreDelay: useconds_t = 150_000

/// Sends `events` to `win` within one activation, then restores the
/// cursor, the frontmost app, and that app's main window.
func drive(_ win: Window, prime: CGPoint?, _ events: (Sender) -> Void) {
    let app = bringForward(win)
    // Coordinates were resolved against the frame as it was before the
    // window came forward, which is when a human is most likely to grab it.
    guard window(win.id)?.frame == win.frame else {
        fail("window \(win.id) moved while activating; sent nothing")
    }

    inputSent = true
    let sender = Sender(app: app, target: win.id)
    if let prime {
        sender.click(prime)
        usleep(150_000)
    }
    events(sender)
    usleep(restoreDelay)
    restoreFocus?()
}

/// Makes `win` the key window until `restoreFocus` runs, and returns its
/// app. Keystrokes that land in the host app instead can cancel the
/// agent's own tool call, so unless `win` verifiably becomes key, this
/// fails having sent nothing. Within an activation already in effect,
/// only checks that it held.
@discardableResult
func bringForward(_ win: Window) -> AXUIElement {
    Precheck.ensureUnlocked()
    Precheck.ensureAccessibility()
    let app = AXUIElementCreateApplication(win.pid)
    if restoreFocus != nil {
        // If the human has taken focus since, don't take it back.
        if let lost = lostFocus(app, win.id) { fail("\(lost); stopped") }
        return app
    }
    let cursor = CGEvent(source: nil)?.location
    let previousApp = NSWorkspace.shared.frontmostApplication
    let previousMain = visibleMainWindow(app, besides: win)

    // Runs on every exit path, including a failed or aborted activation,
    // which may have half-happened. A warp sends no event, and the page
    // would then keep hover styles that make the next capture differ, so
    // the cursor is moved back rather than warped.
    restoreFocus = {
        restoreFocus = nil
        if let cursor, let move = CGEvent(
            mouseEventSource: nil, mouseType: .mouseMoved,
            mouseCursorPosition: cursor, mouseButton: .left)
        {
            post(move)
        }
        if let previousMain {
            setAttribute(previousMain, kAXMainAttribute, kCFBooleanTrue)
            AXUIElementPerformAction(previousMain, kAXRaiseAction as CFString)
        }
        if let previousApp, previousApp.processIdentifier != win.pid {
            bringToFront(previousApp.processIdentifier)
        }
    }

    guard activate(win, app) else {
        let hint = win.onscreen ? "" : " (on another Space, or minimized?)"
        fail("window \(win.id) did not become key\(hint); sent nothing")
    }
    return app
}

/// Posts input to the activated target, stopping if it loses focus.
struct Sender {
    let app: AXUIElement
    let target: CGWindowID

    func click(_ p: CGPoint) {
        // The hover may make --prime unnecessary; see README.
        mouse(.mouseMoved, p, pause: 100_000)
        mouse(.leftMouseDown, p, pause: 60_000)
        mouse(.leftMouseUp, p, pause: 60_000)
    }

    /// Clicks the field at `p`, replaces its contents with `text`, and
    /// optionally tabs out. A field left focused, with its text selected
    /// after Tab, would catch a keystroke of the human's during a later
    /// activation, so a `blank` point is clicked last to drop focus.
    func fill(_ p: CGPoint, _ text: String, tab: Bool, blank: CGPoint?) {
        click(p)
        usleep(200_000)
        pressKey(Key.a, flags: .maskCommand)
        if text.isEmpty { pressKey(Key.delete) } else { typeText(text) }
        if tab { pressKey(Key.tab) }
        if let blank { click(blank) }
    }

    /// Sends each character as a Unicode string on virtual key 0, so
    /// neither the keyboard layout nor the shift state matters.
    func typeText(_ text: String) {
        for character in text {
            pressKey(0, text: String(character), pause: 12_000)
        }
    }

    /// Scrolls `lines` (negative = down) at `p`, in steps of at most 10.
    func scroll(_ lines: Int, at p: CGPoint) {
        mouse(.mouseMoved, p, pause: 60_000)
        var left = lines
        while left != 0 {
            let step = max(-10, min(10, left))
            let event = CGEvent(
                scrollWheelEvent2Source: nil, units: .line, wheelCount: 1,
                wheel1: Int32(step), wheel2: 0, wheel3: 0)
            if let event { send(event) }
            left -= step
            usleep(15_000)
        }
    }

    /// Posts a key down and up carrying exactly `flags`.
    func pressKey(
        _ code: CGKeyCode, flags: CGEventFlags = [], text: String? = nil,
        pause: useconds_t = 30_000
    ) {
        for down in [true, false] {
            guard let event = CGEvent(
                keyboardEventSource: nil, virtualKey: code, keyDown: down)
            else { continue }
            if let text {
                let units = Array(text.utf16)
                event.keyboardSetUnicodeString(
                    stringLength: units.count, unicodeString: units)
            }
            send(event, flags: flags, release: !down)
            usleep(pause)
        }
    }

    private func mouse(
        _ type: CGEventType, _ p: CGPoint, pause: useconds_t
    ) {
        guard let event = CGEvent(
            mouseEventSource: nil, mouseType: type, mouseCursorPosition: p,
            mouseButton: .left)
        else { return }
        // Apps can ignore a press of count 0, so give it a real click's count.
        event.setIntegerValueField(.mouseEventClickState, value: 1)
        send(event, release: type == .leftMouseUp)
        usleep(pause)
    }

    /// Posts `event` unless focus moved since activation, which would send
    /// the rest of the input wherever it went. Releases always go out, so
    /// no button or key is left held.
    private func send(
        _ event: CGEvent, flags: CGEventFlags = [], release: Bool = false
    ) {
        if !release, let lost = lostFocus(app, target) {
            fail("\(lost); stopped")
        }
        post(event, flags: flags)
    }
}

/// Virtual key codes sent by name.
private enum Key {
    static let a: CGKeyCode = 0
    static let tab: CGKeyCode = 48
    static let delete: CGKeyCode = 51
}

/// Virtual key code for a KEYNAME, plus the text a character key types.
/// Apps dispatch a shortcut on its key code and can take an attached
/// string as input instead, so the text is omitted for a `shortcut`.
/// Nil for unknown names. Key 0 with a modifier would be Cmd+A and the
/// like, so for a `shortcut`, also nil for characters without a key code.
func keyCode(
    _ name: String, shortcut: Bool
) -> (code: CGKeyCode, text: String?)? {
    let named: [String: CGKeyCode] = [
        "return": 36, "tab": Key.tab, "space": 49, "delete": Key.delete,
        "escape": 53, "home": 115, "pageup": 116, "end": 119,
        "pagedown": 121, "left": 123, "right": 124, "down": 125, "up": 126,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
        "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
    ]
    if let code = named[name.lowercased()] { return (code, nil) }
    guard name.count == 1 else { return nil }

    // A character's index here is its US ANSI virtual key code, which
    // shortcuts match on. Other characters type via key 0.
    let ansi = Array("asdfhgzxcv\0bqweryt123465=97-80]ou[ip\0lj'k;\\,/nm.\0 `")
    let index = ansi.firstIndex { String($0) == name.lowercased() }
    guard let code = index ?? (shortcut ? nil : 0) else { return nil }
    return (CGKeyCode(code), shortcut ? nil : name)
}

/// How focus moved off `target`, or nil if it hasn't. These are
/// synchronous calls into the target's main thread, which errors whenever
/// it is busy, as a browser is mid layout or script, and treating that as
/// lost focus would abort routinely in the middle of typed text. So an
/// unanswered query also counts as unmoved.
private func lostFocus(_ app: AXUIElement, _ target: CGWindowID) -> String? {
    guard let frontmost: Bool = attribute(app, kAXFrontmostAttribute)
    else { return nil }
    guard frontmost else { return "the target app lost focus" }
    // The human may have switched to another of the app's windows, or the
    // page opened one, so the app staying frontmost isn't enough.
    guard let key: AXUIElement = attribute(
        app, kAXFocusedWindowAttribute), let id = windowID(key)
    else { return nil }
    return id == target ? nil : "another window of the app took focus"
}

/// Brings `win` forward as the key window; false if that doesn't hold
/// within about a second.
private func activate(_ win: Window, _ app: AXUIElement) -> Bool {
    let maxAttempts = 20
    let pollInterval: useconds_t = 50_000

    for attempt in 0..<maxAttempts {
        let key: AXUIElement? = attribute(app, kAXFocusedWindowAttribute)
        if attribute(app, kAXFrontmostAttribute) == true,
           let key, windowID(key) == win.id
        {
            // Firefox finishes its own focus handling after AppKit reports
            // the window key, so input sent right after a fresh activation
            // can go astray.
            if attempt > 0 { usleep(250_000) }
            return true
        }
        // A window on another Space appears only once activation has
        // switched there, so look it up on every pass.
        if let window = axWindow(app, win.id) {
            setAttribute(window, kAXMainAttribute, kCFBooleanTrue)
            setAttribute(window, kAXFocusedAttribute, kCFBooleanTrue)
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
        bringToFront(win.pid)
        usleep(pollInterval)
    }
    return false
}

/// The app's main window, to re-raise afterwards, unless it is `win` or
/// off screen, where raising it could switch Spaces.
private func visibleMainWindow(
    _ app: AXUIElement, besides win: Window
) -> AXUIElement? {
    guard let main: AXUIElement = attribute(app, kAXMainWindowAttribute),
          let id = windowID(main), id != win.id,
          window(id)?.onscreen == true
    else { return nil }
    return main
}

/// Activation requests can be refused, so AXFrontmost is set as well, as
/// System Events does.
private func bringToFront(_ pid: pid_t) {
    NSRunningApplication(processIdentifier: pid)?.activate()
    setAttribute(
        AXUIElementCreateApplication(pid), kAXFrontmostAttribute,
        kCFBooleanTrue)
}

/// A scroll that inherited a modifier once zoomed the page, so every
/// event carries explicit flags.
private func post(_ event: CGEvent, flags: CGEventFlags = []) {
    event.flags = flags
    event.post(tap: .cghidEventTap)
}
