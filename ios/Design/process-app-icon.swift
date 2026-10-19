// Builds light / dark / tinted icons from the glossy STRK mark.
// Usage: swift ios/Design/process-app-icon.swift <source> <appiconset>
import AppKit
import Foundation
import ImageIO

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("usage: process-app-icon.swift <source> <appiconset>\n", stderr)
    exit(1)
}
let sourceURL = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2], isDirectory: true)
let size = 1024

guard let source = NSImage(contentsOf: sourceURL) else {
    fputs("could not load \(sourceURL.path)\n", stderr)
    exit(1)
}

func makeContext() -> CGContext {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    return CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func cgImage(from image: NSImage) -> CGImage {
    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
}

func save(_ image: CGImage, as name: String, in directory: URL = outDir) {
    let url = directory.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: a
    )
}

let src = cgImage(from: source)
let canvas = CGRect(x: 0, y: 0, width: size, height: size)

// Universal + dark: keep the glossy blue mark on black.
do {
    let ctx = makeContext()
    ctx.setFillColor(rgb(0x000000))
    ctx.fill(canvas)
    ctx.interpolationQuality = .high
    ctx.draw(src, in: canvas)
    let image = ctx.makeImage()!
    save(image, as: "AppIcon.png")
    save(image, as: "AppIcon-Dark.png")
}

// Build a silhouette for the tinted home-screen appearance.
let maskCtx = makeContext()
maskCtx.draw(src, in: canvas)
let pixels = maskCtx.data!.assumingMemoryBound(to: UInt8.self)
let count = size * size
var alpha = [UInt8](repeating: 0, count: count)
for i in 0..<count {
    let o = i * 4
    // Keep anything that isn't near-black background.
    let brightness = (Int(pixels[o]) + Int(pixels[o + 1]) + Int(pixels[o + 2])) / 3
    alpha[i] = brightness > 18 ? 255 : 0
}

do {
    let ctx = makeContext()
    ctx.setFillColor(rgb(0x000000))
    ctx.fill(canvas)
    let ink = makeContext()
    let inkData = ink.data!.assumingMemoryBound(to: UInt8.self)
    for i in 0..<count where alpha[i] == 255 {
        let o = i * 4
        inkData[o] = 255
        inkData[o + 1] = 255
        inkData[o + 2] = 255
        inkData[o + 3] = 235
    }
    ctx.draw(ink.makeImage()!, in: canvas)
    save(ctx.makeImage()!, as: "AppIcon-Tinted.png")
}

// Full-colour mark for in-app use (transparent background).
do {
    let markDir = outDir
        .deletingLastPathComponent()
        .appendingPathComponent("MuscleMark.imageset", isDirectory: true)
    try FileManager.default.createDirectory(at: markDir, withIntermediateDirectories: true)

    let ctx = makeContext()
    let data = ctx.data!.assumingMemoryBound(to: UInt8.self)
    for i in 0..<count {
        let o = i * 4
        let r = pixels[o], g = pixels[o + 1], b = pixels[o + 2]
        let brightness = (Int(r) + Int(g) + Int(b)) / 3
        if brightness <= 18 {
            data[o] = 0; data[o + 1] = 0; data[o + 2] = 0; data[o + 3] = 0
        } else {
            data[o] = r; data[o + 1] = g; data[o + 2] = b; data[o + 3] = 255
        }
    }
    save(ctx.makeImage()!, as: "MuscleMark.png", in: markDir)
    let contents = """
    {
      "images" : [
        { "filename" : "MuscleMark.png", "idiom" : "universal", "scale" : "1x" },
        { "idiom" : "universal", "scale" : "2x" },
        { "idiom" : "universal", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 },
      "properties" : { "template-rendering-intent" : "original" }
    }
    """
    try contents.write(to: markDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}
