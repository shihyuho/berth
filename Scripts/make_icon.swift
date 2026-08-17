import AppKit

// 產生 App icon:淺海藍圓角底 + ⚓,輸出 iconset 資料夾(交給 iconutil 轉 icns)。
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let variants: [(px: Int, name: String)] = [
    (16, "16x16"), (32, "16x16@2x"),
    (32, "32x32"), (64, "32x32@2x"),
    (128, "128x128"), (256, "128x128@2x"),
    (256, "256x256"), (512, "256x256@2x"),
    (512, "512x512"), (1024, "512x512@2x"),
]

func render(px: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let side = CGFloat(px)
    let inset = side * 0.05
    let bg = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2),
        xRadius: side * 0.2, yRadius: side * 0.2
    )
    NSColor(calibratedRed: 0.84, green: 0.92, blue: 0.97, alpha: 1).setFill()
    bg.fill()

    let glyph = "⚓" as NSString
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: side * 0.58)]
    let size = glyph.size(withAttributes: attrs)
    glyph.draw(
        at: NSPoint(x: (side - size.width) / 2, y: (side - size.height) / 2),
        withAttributes: attrs
    )
    return rep
}

for variant in variants {
    guard let rep = render(px: variant.px),
          let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("無法產生 \(variant.name)\n".data(using: .utf8)!)
        continue
    }
    let path = "\(outDir)/icon_\(variant.name).png"
    try? png.write(to: URL(fileURLWithPath: path))
}
