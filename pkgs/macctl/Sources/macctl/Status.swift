// `status`, and the preconditions every other command checks.

import AppKit

/// Prints lock state, permissions and the frontmost app; true if every
/// command can run.
func status() -> Bool {
    let locked = screenLocked()
    let recording = CGPreflightScreenCaptureAccess()
    let accessibility = AXIsProcessTrusted()
    let front = NSWorkspace.shared.frontmostApplication
    print("locked:", locked ? "yes" : "no")
    print("screen-recording:", recording ? "yes" : "no")
    print("accessibility:", accessibility ? "yes" : "no")
    print("frontmost:", front.map {
        "\($0.localizedName ?? "?") (pid \($0.processIdentifier))"
    } ?? "none")
    return !locked && recording && accessibility
}

/// Preconditions for capturing and driving windows; each fails if unmet.
enum Precheck {
    static func ensureUnlocked() {
        if screenLocked() { fail("screen is locked") }
    }

    /// Without it, captures silently lack window content.
    static func ensureScreenRecording() {
        if !CGPreflightScreenCaptureAccess() {
            fail("the host app lacks Screen Recording permission")
        }
    }

    static func ensureAccessibility() {
        if !AXIsProcessTrusted() {
            fail("the host app lacks Accessibility permission")
        }
    }
}

/// Also true without a GUI session, or while another user has the console.
private func screenLocked() -> Bool {
    guard let session = CGSessionCopyCurrentDictionary() as? [String: Any]
    else { return true }
    return session["CGSSessionScreenIsLocked"] as? Bool == true
        || session[kCGSessionOnConsoleKey] as? Bool == false
}
