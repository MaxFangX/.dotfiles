// Window lookup through the window server: `windows`, and `<sel>`.

import CoreGraphics
import Foundation

/// A window as the window server reports it; `frame` is in global points.
struct Window {
    let id: CGWindowID
    let pid: pid_t
    let app: String
    let title: String
    let frame: CGRect
    let layer: Int
    let onscreen: Bool

    /// The screen point for window-relative `x`, `y`, or nil outside the
    /// window.
    func screenPoint(_ x: Double, _ y: Double) -> CGPoint? {
        let p = CGPoint(x: frame.minX + x, y: frame.minY + y)
        return frame.contains(p) ? p : nil
    }

    /// One `macctl windows` line.
    var line: String {
        let f = frame
        return [
            "\(id)", "\(pid)", "\(Int(f.minX))", "\(Int(f.minY))",
            "\(Int(f.width))", "\(Int(f.height))", onscreen ? "1" : "0",
            app, title,
        ].joined(separator: "\t")
    }
}

/// The window given by -w, else the frontmost one matching -a/-t.
func selectWindow(_ args: Args) -> Window {
    if let raw = args["--window"] {
        guard let id = CGWindowID(raw), let win = window(id) else {
            fail("no window with id '\(raw)'")
        }
        return win
    }
    guard args.has("--app") || args.has("--title") else {
        fail("select a window with -w, -a or -t")
    }

    let matches = windows(
        app: args["--app"], title: args["--title"], onscreenOnly: false)
    guard let win = matches.first else { fail("no window matches") }
    if matches.count > 1 {
        warn("\(matches.count) windows match; using \(win.id) "
            + "(\(win.app): \(win.title))")
    }
    return win
}

/// Titled layer-0 windows on every Space, front to back.
func windows(app: String?, title: String?, onscreenOnly: Bool) -> [Window] {
    if !CGPreflightScreenCaptureAccess() {
        warn("window titles are hidden without Screen Recording permission")
    }
    return allWindows().filter { w in
        w.layer == 0 && !w.title.isEmpty
            && (app.map { w.app.lowercased() == $0.lowercased() } ?? true)
            && (title.map { w.title.localizedCaseInsensitiveContains($0) }
                ?? true)
            && (w.onscreen || !onscreenOnly)
    }
}

func window(_ id: CGWindowID) -> Window? {
    allWindows().first { $0.id == id }
}

/// Windows on other Spaces report not onscreen, so lookups must include
/// offscreen windows.
private func allWindows() -> [Window] {
    let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
    let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
        as? [[String: Any]] ?? []
    return info.compactMap { d in
        guard let id = d[kCGWindowNumber as String] as? CGWindowID,
              let pid = d[kCGWindowOwnerPID as String] as? pid_t,
              let bounds = d[kCGWindowBounds as String] as? NSDictionary,
              let frame = CGRect(dictionaryRepresentation: bounds)
        else { return nil }
        return Window(
            id: id,
            pid: pid,
            app: d[kCGWindowOwnerName as String] as? String ?? "",
            title: d[kCGWindowName as String] as? String ?? "",
            frame: frame,
            layer: d[kCGWindowLayer as String] as? Int ?? 0,
            onscreen: d[kCGWindowIsOnscreen as String] as? Bool ?? false)
    }
}
