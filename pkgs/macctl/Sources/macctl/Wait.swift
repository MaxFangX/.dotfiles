// `wait` and `--wait`: polling captures until the window settles.

import Foundation

/// Captures `win` every second until it differs from `baseline` and two
/// consecutive captures match, then prints "changed" and the capture's
/// path. After `timeout` seconds (default 15), prints "unchanged", or
/// "unsettled" if it differs but never stopped changing, and exits 2.
/// A second click can skip a screen, so this never repeats the action
/// that preceded it.
func waitForChange(
    _ win: Window, from baseline: Data, timeout: TimeInterval? = nil
) -> Never {
    let defaultTimeout: TimeInterval = 15
    let pollInterval: TimeInterval = 1

    let deadline = Date().addingTimeInterval(timeout ?? defaultTimeout)
    var previous: Data?
    var everDiffered = false
    var path: String
    repeat {
        Thread.sleep(forTimeInterval: pollInterval)
        path = capture(win)
        let current = pixels(path)
        if current != baseline {
            // A window that changed and changed back, say a spinner, still
            // acted, so don't tell the caller to click again.
            everDiffered = true
            if current == previous {
                print("changed", path)
                exit(0)
            }
        }
        previous = current
        // Stop before a poll that would end past the deadline.
    } while Date().addingTimeInterval(pollInterval) < deadline
    print(everDiffered ? "unsettled" : "unchanged", path)
    exit(2)
}
