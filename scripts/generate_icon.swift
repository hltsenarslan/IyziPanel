#!/usr/bin/env swift
import AppKit

// IyziPanel uygulama ikonu üreteci.
// Kenar-dock temasını yansıtır: squircle tile, indigo→mor gradyan,
// sağda glass bir bar, içinde uygulama noktaları ve ince bir tutamak.

func render(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    let s = size
    func px(_ v: CGFloat) -> CGFloat { v / 1024.0 * s }

    // --- Tile (squircle) ---
    let inset = px(88)
    let tileRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = px(200)
    let tile = NSBezierPath(roundedRect: tileRect, xRadius: radius, yRadius: radius)

    ctx.saveGState()
    tile.addClip()

    // Diagonal gradyan: derin indigo → mor → menekşe
    let colors = [
        NSColor(srgbRed: 0.29, green: 0.24, blue: 0.86, alpha: 1).cgColor, // #4B3DDB
        NSColor(srgbRed: 0.49, green: 0.23, blue: 0.93, alpha: 1).cgColor, // #7C3AED
        NSColor(srgbRed: 0.66, green: 0.33, blue: 0.97, alpha: 1).cgColor  // #A855F7
    ] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: tileRect.minX, y: tileRect.maxY),
        end: CGPoint(x: tileRect.maxX, y: tileRect.minY),
        options: [])

    // Üstte yumuşak parlaklık
    let gloss = CGGradient(
        colorsSpace: space,
        colors: [NSColor(white: 1, alpha: 0.28).cgColor,
                 NSColor(white: 1, alpha: 0).cgColor] as CFArray,
        locations: [0, 1])!
    ctx.drawLinearGradient(
        gloss,
        start: CGPoint(x: tileRect.midX, y: tileRect.maxY),
        end: CGPoint(x: tileRect.midX, y: tileRect.midY),
        options: [])

    // --- Glass bar (sağ kenar dock motifi) ---
    let barW = px(150)
    let barH = tileRect.height * 0.66
    let barX = tileRect.maxX - barW - px(80)
    let barY = tileRect.midY - barH / 2
    let barRect = CGRect(x: barX, y: barY, width: barW, height: barH)
    let barPath = NSBezierPath(roundedRect: barRect, xRadius: px(46), yRadius: px(46))

    NSColor(white: 1, alpha: 0.22).setFill()
    barPath.fill()
    NSColor(white: 1, alpha: 0.55).setStroke()
    barPath.lineWidth = px(3)
    barPath.stroke()

    // Bar içindeki uygulama noktaları
    let dotD = px(64)
    let dotX = barRect.midX - dotD / 2
    let gap = px(46)
    let totalDots = dotD * 3 + gap * 2
    var dotY = barRect.midY + totalDots / 2 - dotD
    let dotColors = [
        NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95),
        NSColor(srgbRed: 1.0, green: 0.85, blue: 0.55, alpha: 0.95),
        NSColor(srgbRed: 0.70, green: 0.95, blue: 1.0, alpha: 0.95)
    ]
    for c in dotColors {
        let dot = NSBezierPath(ovalIn: CGRect(x: dotX, y: dotY, width: dotD, height: dotD))
        c.setFill()
        dot.fill()
        dotY -= (dotD + gap)
    }

    // --- Tutamak (handle) ---
    let handleW = px(20)
    let handleH = px(120)
    let handleRect = CGRect(
        x: tileRect.maxX - px(64),
        y: tileRect.midY - handleH / 2,
        width: handleW, height: handleH)
    let handle = NSBezierPath(roundedRect: handleRect, xRadius: handleW / 2, yRadius: handleW / 2)
    NSColor(white: 1, alpha: 0.85).setFill()
    handle.fill()

    ctx.restoreGState()

    // Tile kenarına ince iç çizgi
    NSColor(white: 1, alpha: 0.14).setStroke()
    tile.lineWidth = px(2)
    tile.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "IyziPanel.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let specs: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, size) in specs {
    let rep = render(size: size)
    let data = rep.representation(using: .png, properties: [:])!
    let url = URL(fileURLWithPath: "\(outDir)/\(name).png")
    try! data.write(to: url)
    print("yazıldı: \(name).png (\(Int(size))px)")
}
print("Tamam → \(outDir)")
