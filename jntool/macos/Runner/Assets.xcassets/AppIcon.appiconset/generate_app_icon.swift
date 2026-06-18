import AppKit

let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func color(_ hex: UInt32) -> NSColor {
    let r = CGFloat((hex >> 16) & 0xff) / 255.0
    let g = CGFloat((hex >> 8) & 0xff) / 255.0
    let b = CGFloat(hex & 0xff) / 255.0
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
}

func addLightning(to path: NSBezierPath) {
    path.move(to: NSPoint(x: 25.9, y: 44.9))
    path.line(to: NSPoint(x: 23.9, y: 44.2))
    path.line(to: NSPoint(x: 23.9, y: 33.9))
    path.curve(to: NSPoint(x: 21.7, y: 31.7), controlPoint1: NSPoint(x: 23.9, y: 32.7), controlPoint2: NSPoint(x: 22.9, y: 31.7))
    path.line(to: NSPoint(x: 10.3, y: 31.7))
    path.curve(to: NSPoint(x: 9.4, y: 29.9), controlPoint1: NSPoint(x: 9.4, y: 31.7), controlPoint2: NSPoint(x: 8.9, y: 30.6))
    path.line(to: NSPoint(x: 16.8, y: 19.4))
    path.curve(to: NSPoint(x: 15.0, y: 15.8), controlPoint1: NSPoint(x: 17.9, y: 17.9), controlPoint2: NSPoint(x: 16.8, y: 15.8))
    path.line(to: NSPoint(x: 1.2, y: 15.8))
    path.curve(to: NSPoint(x: 0.3, y: 14.1), controlPoint1: NSPoint(x: 0.3, y: 15.8), controlPoint2: NSPoint(x: -0.2, y: 14.8))
    path.line(to: NSPoint(x: 10.0, y: 0.5))
    path.curve(to: NSPoint(x: 10.9, y: 0.0), controlPoint1: NSPoint(x: 10.2, y: 0.2), controlPoint2: NSPoint(x: 10.6, y: 0.0))
    path.line(to: NSPoint(x: 39.8, y: 0.0))
    path.curve(to: NSPoint(x: 40.7, y: 1.8), controlPoint1: NSPoint(x: 40.7, y: 0.0), controlPoint2: NSPoint(x: 41.2, y: 1.0))
    path.line(to: NSPoint(x: 33.3, y: 12.3))
    path.curve(to: NSPoint(x: 35.1, y: 15.8), controlPoint1: NSPoint(x: 32.2, y: 13.8), controlPoint2: NSPoint(x: 33.3, y: 15.8))
    path.line(to: NSPoint(x: 46.5, y: 15.8))
    path.curve(to: NSPoint(x: 47.4, y: 17.7), controlPoint1: NSPoint(x: 47.4, y: 15.8), controlPoint2: NSPoint(x: 48.0, y: 16.9))
    path.line(to: NSPoint(x: 25.9, y: 44.9))
    path.close()
}

for size in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else { fatalError("无法创建绘制上下文") }
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let inset = CGFloat(size) * 0.07
    let backgroundRect = rect.insetBy(dx: inset, dy: inset)
    let background = NSBezierPath(roundedRect: backgroundRect, xRadius: CGFloat(size) * 0.21, yRadius: CGFloat(size) * 0.21)
    NSGradient(starting: color(0xf7f0ff), ending: color(0xe7f8ff))?.draw(in: background, angle: -35)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.18)
    shadow.shadowBlurRadius = CGFloat(size) * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -CGFloat(size) * 0.018)
    shadow.set()

    let scale = CGFloat(size) * 0.015
    let lightning = NSBezierPath()
    addLightning(to: lightning)

    var transform = AffineTransform()
    transform.translate(x: CGFloat(size) * 0.155, y: CGFloat(size) * 0.13)
    transform.scale(scale)
    lightning.transform(using: transform)

    color(0x863bff).setFill()
    lightning.fill()

    NSGraphicsContext.current?.restoreGraphicsState()
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("无法导出 PNG")
    }
    let url = outputDir.appendingPathComponent("app_icon_\(size).png")
    try png.write(to: url)
}
