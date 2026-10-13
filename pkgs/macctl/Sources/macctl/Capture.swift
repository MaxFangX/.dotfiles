// Window captures: `shot`, and the baselines `wait` compares.

import Foundation
import ImageIO

/// Captures `win` to a PNG and returns its path, without raising it.
/// Unless `full`, scales the image so one pixel is one point.
func capture(
    _ win: Window, to path: String? = nil, full: Bool = false
) -> String {
    Precheck.ensureUnlocked()
    Precheck.ensureScreenRecording()
    let path = path ?? "/tmp/macctl/\(win.id).png"
    let url = URL(fileURLWithPath: path)
    let files = FileManager.default
    try? files.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true)
    // A failed capture must not leave the previous image looking current.
    try? files.removeItem(at: url)

    // -l captures the window even when covered; -o drops the shadow, so
    // the image is exactly the window's frame.
    let screencapture = Process()
    screencapture.executableURL =
        URL(fileURLWithPath: "/usr/sbin/screencapture")
    screencapture.arguments = ["-x", "-o", "-l", "\(win.id)", path]
    let stderr = Pipe()
    screencapture.standardError = stderr
    do { try screencapture.run() } catch { fail("screencapture: \(error)") }
    let message = String(
        decoding: stderr.fileHandleForReading.readDataToEndOfFile(),
        as: UTF8.self
    ).split(whereSeparator: \.isNewline).joined(separator: "; ")
    screencapture.waitUntilExit()
    guard screencapture.terminationStatus == 0, let image = loadImage(path)
    else { fail("cannot capture window \(win.id): \(message)") }

    // The window may have been resized since lookup, and scaling to its
    // old size would give a capture whose coordinates no longer match it.
    // So scale to its size now.
    let frame = window(win.id)?.frame ?? win.frame
    let width = Int(frame.width.rounded())
    let height = Int(frame.height.rounded())
    if !full && image.width != width {
        writeScaled(image, width: width, height: height, to: url)
    }
    return path
}

/// Decoded pixels of the image at `path`, for comparing captures.
func pixels(_ path: String) -> Data {
    guard let data = loadImage(path)?.dataProvider?.data as Data? else {
        fail("cannot read image \(path)")
    }
    return data
}

/// Reads the file afresh so a rewritten path is never served from cache.
private func loadImage(_ path: String) -> CGImage? {
    guard let data = FileManager.default.contents(atPath: path),
          let source = CGImageSourceCreateWithData(data as CFData, nil)
    else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

private func writeScaled(
    _ image: CGImage, width: Int, height: Int, to url: URL
) {
    guard let context = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fail("cannot scale capture") }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let scaled = context.makeImage(),
          let png = CGImageDestinationCreateWithURL(
              url as CFURL, "public.png" as CFString, 1, nil)
    else { fail("cannot scale capture") }
    CGImageDestinationAddImage(png, scaled, nil)
    guard CGImageDestinationFinalize(png) else {
        fail("cannot write \(url.path)")
    }
}
