import AppKit
import CoreGraphics
import Foundation
import Darwin

private let canvasSize = 1_024
private let colorSpace = CGColorSpaceCreateDeviceRGB()

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [red, green, blue, alpha])
        ?? CGColor(gray: 0, alpha: alpha)
}

private func roundedPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

private func fillGradient(
    context: CGContext,
    rect: CGRect,
    radius: CGFloat,
    colors: [CGColor],
    locations: [CGFloat]
) {
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
        return
    }
    context.saveGState()
    context.addPath(roundedPath(rect, radius: radius))
    context.clip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )
    context.restoreGState()
}

private func pngData(from image: CGImage, size: Int) -> Data? {
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    guard let scaledImage = context.makeImage() else { return nil }
    return NSBitmapImageRep(cgImage: scaledImage).representation(using: .png, properties: [:])
}

private func appendBigEndian(_ value: UInt32, to data: inout Data) {
    var bigEndianValue = value.bigEndian
    withUnsafeBytes(of: &bigEndianValue) { bytes in
        data.append(contentsOf: bytes)
    }
}

private func icnsData(from image: CGImage) -> Data? {
    let representations: [(type: String, size: Int)] = [
        ("icp4", 16), ("icp5", 32), ("icp6", 64),
        ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1_024),
        ("ic11", 32), ("ic12", 64), ("ic13", 256), ("ic14", 512)
    ]
    var chunks = Data()
    for representation in representations {
        guard let typeData = representation.type.data(using: .ascii), typeData.count == 4,
              let png = pngData(from: image, size: representation.size),
              png.count <= Int(UInt32.max) - 8 else { return nil }
        chunks.append(typeData)
        appendBigEndian(UInt32(png.count + 8), to: &chunks)
        chunks.append(png)
    }
    guard chunks.count <= Int(UInt32.max) - 8 else { return nil }
    var result = Data("icns".utf8)
    appendBigEndian(UInt32(chunks.count + 8), to: &result)
    result.append(chunks)
    return result
}

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("App icon generation failed: \(message)\n".utf8))
    Darwin.exit(EXIT_FAILURE)
}

guard CommandLine.arguments.count == 3 else { fail("Output PNG and ICNS paths are required") }
guard let context = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fail("Could not create a drawing context") }

context.clear(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
let backgroundRect = CGRect(x: 52, y: 52, width: 920, height: 920)
fillGradient(
    context: context,
    rect: backgroundRect,
    radius: 214,
    colors: [color(0.09, 0.15, 0.33), color(0.26, 0.22, 0.79), color(0.49, 0.13, 0.81)],
    locations: [0, 0.52, 1]
)

context.addPath(roundedPath(backgroundRect.insetBy(dx: 2, dy: 2), radius: 212))
context.setStrokeColor(color(1, 1, 1, 0.26))
context.setLineWidth(4)
context.strokePath()

if let shine = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(1, 1, 1, 0.28), color(1, 1, 1, 0)] as CFArray,
    locations: [0, 1]
) {
    context.saveGState()
    context.addPath(roundedPath(backgroundRect, radius: 214))
    context.clip()
    context.drawRadialGradient(
        shine,
        startCenter: CGPoint(x: 230, y: 800),
        startRadius: 20,
        endCenter: CGPoint(x: 300, y: 710),
        endRadius: 700,
        options: []
    )
    context.restoreGState()
}

let blue = [color(0.40, 0.91, 0.98), color(0.01, 0.52, 0.78)]
let violet = [color(0.77, 0.71, 0.99), color(0.49, 0.23, 0.93)]
let coral = [color(0.99, 0.73, 0.45), color(0.96, 0.25, 0.37)]
let green = [color(0.43, 0.91, 0.72), color(0.02, 0.59, 0.41)]
let tileColors = [blue, violet, coral, green, [color(1, 1, 1, 0.94), color(0.91, 0.93, 1)], blue, coral, green, violet]
let positions: [CGFloat] = [190, 422, 654]

for row in 0..<3 {
    for column in 0..<3 {
        let rect = CGRect(x: positions[column], y: positions[2 - row], width: 180, height: 180)
        fillGradient(
            context: context,
            rect: rect,
            radius: 48,
            colors: tileColors[(row * 3) + column],
            locations: [0, 1]
        )
        context.addPath(roundedPath(rect.insetBy(dx: 1.5, dy: 1.5), radius: 46.5))
        context.setStrokeColor(color(1, 1, 1, 0.3))
        context.setLineWidth(3)
        context.strokePath()
    }
}

let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 478, y: 470))
arrow.addLine(to: CGPoint(x: 548, y: 540))
arrow.move(to: CGPoint(x: 496, y: 540))
arrow.addLine(to: CGPoint(x: 548, y: 540))
arrow.addLine(to: CGPoint(x: 548, y: 488))
context.addPath(arrow)
context.setStrokeColor(color(0.26, 0.22, 0.79))
context.setLineWidth(26)
context.setLineCap(.round)
context.setLineJoin(.round)
context.strokePath()

guard let cgImage = context.makeImage(),
      let masterPNG = pngData(from: cgImage, size: canvasSize),
      let iconData = icnsData(from: cgImage) else { fail("Could not encode the final icon") }

do {
    try masterPNG.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
    try iconData.write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
} catch {
    fail(error.localizedDescription)
}
