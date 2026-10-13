// The accessibility commands: `tree`, `text`, `press`, and `set`.

import AppKit

/// Deep enough for web pages, whose trees nest dozens of groups deep.
let defaultTreeDepth = 100

/// Prints `win`'s interactive AX elements, plus static text if `all`.
func printTree(_ win: Window, depth: Int, all: Bool) {
    let roles = all ? interactiveOrText : interactiveRoles
    let found = inAXWindow(win) {
        elements($0, win, depth: depth, roles: roles)
    }
    for e in found {
        let f = e.frame
        print(
            e.role, Int(f.minX), Int(f.minY), Int(f.width), Int(f.height),
            e.title, e.description, e.id, oneLine(e.value, limit: 80),
            separator: "\t")
    }
}

/// Prints the static text and field values shown in `region` of `win`
/// (window-relative; default all of it), top to bottom, as "y<tab>text".
/// A browser's tab titles and URL aren't content, so in a browser only
/// the page's text is printed.
func printText(_ win: Window, region: CGRect?) {
    let bounds = region ?? CGRect(origin: .zero, size: win.frame.size)
    let all = inAXWindow(win) { elements($0, win, roles: shownRoles) }
        .filter { !$0.value.isEmpty && $0.frame.intersects(bounds) }
    let page = all.filter(\.inPage)
    let shown = page.isEmpty ? all : page
    // A paragraph that wraps around an inline label starts left of it, so
    // ties on y keep page order, not x order.
    let order = shown.indices.sorted {
        (shown[$0].frame.minY, $0) < (shown[$1].frame.minY, $1)
    }
    for i in order {
        print(Int(shown[i].frame.minY), shown[i].value, separator: "\t")
    }
}

/// AXPresses the element named `name`. Browsers list AXPress on text
/// under any click listener, but pages that act on mousedown ignore it,
/// so text, such as a custom dropdown's option, is clicked at its centre
/// instead, as is anything without AXPress.
func press(_ win: Window, name: String) {
    inAXWindow(win) { root in
        let found = elements(root, win, roles: interactiveOrText)
        let target = match(name, in: found)
        if target.role != kAXStaticTextRole, pressable(target.ref) {
            let pressed = AXUIElementPerformAction(
                target.ref, kAXPressAction as CFString)
            if pressed != .actionUnsupported {
                // A busy app times the call out, then handles it, so any
                // other failure may have pressed it all the same.
                inputSent = true
                guard pressed == .success else {
                    fail("AXPress failed on \(target.role) '\(name)' "
                        + "(\(pressed.rawValue))")
                }
                return
            }
        }
        let why = target.role == kAXStaticTextRole
            ? "'\(name)' is text" : "no AXPress on '\(name)'"
        drive(win, prime: nil) {
            $0.click(clickPoint(target, win, why, "clicking"))
        }
    }
}

/// Sets the value of the text field named `name`; if the app rejects
/// that, fills the field at its centre instead.
func setValue(_ win: Window, name: String, value: String, prime: CGPoint?) {
    inAXWindow(win) { root in
        let field = match(name, in: elements(root, win, roles: fieldRoles))
        let before: String? = attribute(field.ref, kAXValueAttribute)
        let written = setAttribute(
            field.ref, kAXValueAttribute, value as CFString) == .success
        if written {
            // A field that reformats what it is given ("1234" to "1,234")
            // did accept it, and refilling by hand would only produce the
            // same thing, so compare against what was there rather than
            // against `value`. Browsers apply the write asynchronously, so
            // poll for a moment.
            let maxAttempts = 10
            let pollInterval: useconds_t = 50_000
            for _ in 0..<maxAttempts {
                let after: String? = attribute(field.ref, kAXValueAttribute)
                if after != before || value == before {
                    inputSent = true
                    return
                }
                usleep(pollInterval)
            }
        }
        let reason = written
            ? "AXValue was accepted but '\(name)' did not change"
            : "'\(name)' rejected AXValue"
        drive(win, prime: prime) {
            let p = clickPoint(field, win, reason, "filling")
            $0.fill(p, value, tab: true, blank: prime)
        }
    }
}

/// `id`'s AX element. Apps list only windows on the current Space.
func axWindow(_ app: AXUIElement, _ id: CGWindowID) -> AXUIElement? {
    let windows: [AXUIElement] = attribute(app, kAXWindowsAttribute) ?? []
    return windows.first { windowID($0) == id }
}

func windowID(_ window: AXUIElement) -> CGWindowID? {
    var id: CGWindowID = 0
    return _AXUIElementGetWindow(window, &id) == .success ? id : nil
}

func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
    var value: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(
        element, name as CFString, &value)
    return status == .success ? value as? T : nil
}

@discardableResult
func setAttribute(
    _ element: AXUIElement, _ name: String, _ value: CFTypeRef
) -> AXError {
    AXUIElementSetAttributeValue(element, name as CFString, value)
}

/// Titles and frames can collide, so this is the only exact mapping
/// from an AX element to a CGWindowID. Private, but stable for over a
/// decade and used by most window managers.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(
    _ element: AXUIElement, _ id: inout CGWindowID
) -> AXError

private let interactiveRoles: Set<String> = [
    "AXButton", "AXCheckBox", "AXComboBox", "AXLink", "AXMenuItem",
    "AXPopUpButton", "AXRadioButton", "AXTextArea", "AXTextField",
]
private let webAreaRole = "AXWebArea"
/// What `set` writes to.
private let fieldRoles: Set<String> = [
    "AXComboBox", "AXTextArea", "AXTextField",
]
private let interactiveOrText = interactiveRoles.union([kAXStaticTextRole])
/// What `text` prints the value of.
private let shownRoles = fieldRoles.union([
    "AXPopUpButton", kAXStaticTextRole,
])

private struct Element {
    let ref: AXUIElement
    let role: String
    let title: String
    let description: String
    /// The DOM id, for web content.
    let id: String
    let value: String
    /// Window-relative.
    let frame: CGRect
    /// Inside a web page, rather than the browser around it.
    let inPage: Bool
}

/// Runs `body` on `win`'s AX window, which the app lists only while it is
/// on the current Space. A window elsewhere is brought forward like an
/// input target, switching Spaces, until `body` is done.
private func inAXWindow<T>(_ win: Window, _ body: (AXUIElement) -> T) -> T {
    Precheck.ensureUnlocked()
    Precheck.ensureAccessibility()
    let app = AXUIElementCreateApplication(win.pid)
    // Browsers watch the first flag and Electron apps the second. Neither
    // is unset afterwards.
    setAttribute(app, "AXEnhancedUserInterface", kCFBooleanTrue)
    setAttribute(app, "AXManualAccessibility", kCFBooleanTrue)
    if let root = axWindow(app, win.id) { return body(root) }

    bringForward(win)
    guard let root = axWindow(app, win.id) else {
        fail("window \(win.id) is not in its app's AX windows")
    }
    let result = body(root)
    usleep(restoreDelay)
    restoreFocus?()
    return result
}

/// The element named `name`, preferring a web page's own over the
/// browser's, so "Back" is the page's button, not the toolbar's.
private func match(_ name: String, in elements: [Element]) -> Element {
    guard !name.isEmpty else { fail("NAME is empty") }
    let page = elements.filter(\.inPage)
    if let e = named(name, in: page) ?? named(name, in: elements) { return e }
    fail("no element named '\(name)'")
}

/// The first control whose title, description or id is `name`
/// (case-insensitive), else the first static text reading `name`, else
/// the first control where one contains it. Some paragraph contains
/// almost any name, so text must match exactly.
private func named(_ name: String, in elements: [Element]) -> Element? {
    let controls = elements.filter { $0.role != kAXStaticTextRole }
    let labels = { (e: Element) in [e.title, e.description, e.id] }
    let lowered = name.lowercased()
    let exact = controls.first { e in
        labels(e).contains { $0.lowercased() == lowered }
    } ?? elements.first { e in
        e.role == kAXStaticTextRole && e.value.lowercased() == lowered
    }
    if let exact { return exact }

    for e in controls {
        let hit = labels(e).first { $0.localizedCaseInsensitiveContains(name) }
        if let hit {
            // "Continue" could be "Continue without saving".
            warn("no exact match; using \(e.role) '\(hit)'")
            return e
        }
    }
    return nil
}

private func pressable(_ element: AXUIElement) -> Bool {
    var actions: CFArray?
    AXUIElementCopyActionNames(element, &actions)
    return (actions as? [String])?.contains(kAXPressAction) == true
}

/// `e`'s centre as a screen point, for clicking what the app won't act on
/// through AX, and says so after `reason`. Activating can move an open
/// list's options, so call it once the window is forward.
private func clickPoint(
    _ e: Element, _ win: Window, _ reason: String, _ doing: String
) -> CGPoint {
    let f = Element(
        e.ref, role: e.role, origin: win.frame.origin, inPage: e.inPage
    ).frame
    guard !f.isEmpty, let p = win.screenPoint(f.midX, f.midY) else {
        fail("\(reason), and it has no frame in the window to click")
    }
    warn("\(reason); \(doing) at \(Int(f.midX)),\(Int(f.midY))")
    return p
}

/// The elements in `roles` under `root`, `win`'s AX window. Browsers build
/// the tree only once AXEnhancedUserInterface is set, and then lazily, so
/// a first pass that finds nothing, or nothing in the page, is retried.
private func elements(
    _ root: AXUIElement, _ win: Window, depth: Int = defaultTreeDepth,
    roles: Set<String>
) -> [Element] {
    let pass = {
        var found: [Element] = []
        walk(
            root, depth: depth, origin: win.frame.origin,
            roles: roles.union([webAreaRole]), &found)
        return found
    }
    var found = pass()
    let hasPage = found.contains { $0.role == webAreaRole }
    if found.allSatisfy({ $0.role == webAreaRole })
        || hasPage && !found.contains(where: \.inPage)
    {
        usleep(500_000)
        found = pass()
    }
    return found.filter { $0.role != webAreaRole }
}

private func walk(
    _ element: AXUIElement, depth: Int, origin: CGPoint, roles: Set<String>,
    inPage: Bool = false, _ found: inout [Element]
) {
    let role: String = attribute(element, kAXRoleAttribute) ?? ""
    if roles.contains(role) {
        found.append(
            Element(element, role: role, origin: origin, inPage: inPage))
    }
    guard depth > 0 else { return }
    let children: [AXUIElement] =
        attribute(element, kAXChildrenAttribute) ?? []
    for child in children {
        walk(
            child, depth: depth - 1, origin: origin, roles: roles,
            inPage: inPage || role == webAreaRole, &found)
    }
}

private extension Element {
    init(
        _ element: AXUIElement, role: String, origin: CGPoint, inPage: Bool
    ) {
        var position = CGPoint.zero
        var size = CGSize.zero
        if let v: AXValue = attribute(element, kAXPositionAttribute) {
            AXValueGetValue(v, .cgPoint, &position)
        }
        if let v: AXValue = attribute(element, kAXSizeAttribute) {
            AXValueGetValue(v, .cgSize, &size)
        }
        // An Any holding a CF value prints as "Optional(...)", so go
        // through AnyObject.
        let value: AnyObject? = attribute(element, kAXValueAttribute)
        let label = { (name: String) in
            oneLine(attribute(element, name) ?? "")
        }
        self.init(
            ref: element,
            role: role,
            title: label(kAXTitleAttribute),
            description: label(kAXDescriptionAttribute),
            id: label("AXDOMIdentifier"),
            value: oneLine(value.map { "\($0)" } ?? ""),
            frame: CGRect(
                x: position.x - origin.x, y: position.y - origin.y,
                width: size.width, height: size.height),
            inPage: inPage)
    }
}

/// Flattens whitespace so each element stays on one line.
private func oneLine(_ text: String, limit: Int = .max) -> String {
    let flat = text.split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
    return flat.count > limit ? flat.prefix(limit) + "…" : flat
}
