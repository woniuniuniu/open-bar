import AppKit
import CoreGraphics
import Foundation

// Renders the OPEN BAR app icon: the "OB" mark under a menu bar with an
// orange notch, on a dark squircle that follows Apple's macOS icon grid.

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift make_icon.swift output.png\n", stderr)
    exit(2)
}

let canvas: CGFloat = 1024
// macOS icon grid: an 824 pt body centred on the 1024 canvas.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyRadius: CGFloat = 206  // matches the corner profile of system icons

let gray = CGColor(srgbRed: 0.706, green: 0.706, blue: 0.706, alpha: 1)
let orange = CGColor(srgbRed: 1.0, green: 0.416, blue: 0.031, alpha: 1)
let backgroundTop = CGColor(srgbRed: 0.106, green: 0.106, blue: 0.106, alpha: 1)
let backgroundBottom = CGColor(srgbRed: 0.051, green: 0.051, blue: 0.051, alpha: 1)

/// Apple-style continuous-corner rounded rectangle (y-down coordinates).
func continuousRoundedRect(_ rect: CGRect, radius r: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let (minX, minY, maxX, maxY) = (rect.minX, rect.minY, rect.maxX, rect.maxY)
    path.move(to: CGPoint(x: minX + 1.52866483 * r, y: minY))
    path.addLine(to: CGPoint(x: maxX - 1.52866483 * r, y: minY))
    path.addCurve(to: CGPoint(x: maxX - 0.63149399 * r, y: minY + 0.07491100 * r),
                  control1: CGPoint(x: maxX - 1.08849323 * r, y: minY),
                  control2: CGPoint(x: maxX - 0.86840689 * r, y: minY + 0.02210862 * r))
    path.addCurve(to: CGPoint(x: maxX - 0.07491100 * r, y: minY + 0.63149399 * r),
                  control1: CGPoint(x: maxX - 0.37282392 * r, y: minY + 0.16905899 * r),
                  control2: CGPoint(x: maxX - 0.16905899 * r, y: minY + 0.37282392 * r))
    path.addCurve(to: CGPoint(x: maxX, y: minY + 1.52866483 * r),
                  control1: CGPoint(x: maxX - 0.02210862 * r, y: minY + 0.86840689 * r),
                  control2: CGPoint(x: maxX, y: minY + 1.08849323 * r))
    path.addLine(to: CGPoint(x: maxX, y: maxY - 1.52866483 * r))
    path.addCurve(to: CGPoint(x: maxX - 0.07491100 * r, y: maxY - 0.63149399 * r),
                  control1: CGPoint(x: maxX, y: maxY - 1.08849323 * r),
                  control2: CGPoint(x: maxX - 0.02210862 * r, y: maxY - 0.86840689 * r))
    path.addCurve(to: CGPoint(x: maxX - 0.63149399 * r, y: maxY - 0.07491100 * r),
                  control1: CGPoint(x: maxX - 0.16905899 * r, y: maxY - 0.37282392 * r),
                  control2: CGPoint(x: maxX - 0.37282392 * r, y: maxY - 0.16905899 * r))
    path.addCurve(to: CGPoint(x: maxX - 1.52866483 * r, y: maxY),
                  control1: CGPoint(x: maxX - 0.86840689 * r, y: maxY - 0.02210862 * r),
                  control2: CGPoint(x: maxX - 1.08849323 * r, y: maxY))
    path.addLine(to: CGPoint(x: minX + 1.52866483 * r, y: maxY))
    path.addCurve(to: CGPoint(x: minX + 0.63149399 * r, y: maxY - 0.07491100 * r),
                  control1: CGPoint(x: minX + 1.08849323 * r, y: maxY),
                  control2: CGPoint(x: minX + 0.86840689 * r, y: maxY - 0.02210862 * r))
    path.addCurve(to: CGPoint(x: minX + 0.07491100 * r, y: maxY - 0.63149399 * r),
                  control1: CGPoint(x: minX + 0.37282392 * r, y: maxY - 0.16905899 * r),
                  control2: CGPoint(x: minX + 0.16905899 * r, y: maxY - 0.37282392 * r))
    path.addCurve(to: CGPoint(x: minX, y: maxY - 1.52866483 * r),
                  control1: CGPoint(x: minX + 0.02210862 * r, y: maxY - 0.86840689 * r),
                  control2: CGPoint(x: minX, y: maxY - 1.08849323 * r))
    path.addLine(to: CGPoint(x: minX, y: minY + 1.52866483 * r))
    path.addCurve(to: CGPoint(x: minX + 0.07491100 * r, y: minY + 0.63149399 * r),
                  control1: CGPoint(x: minX, y: minY + 1.08849323 * r),
                  control2: CGPoint(x: minX + 0.02210862 * r, y: minY + 0.86840689 * r))
    path.addCurve(to: CGPoint(x: minX + 0.63149399 * r, y: minY + 0.07491100 * r),
                  control1: CGPoint(x: minX + 0.16905899 * r, y: minY + 0.37282392 * r),
                  control2: CGPoint(x: minX + 0.37282392 * r, y: minY + 0.16905899 * r))
    path.addCurve(to: CGPoint(x: minX + 1.52866483 * r, y: minY),
                  control1: CGPoint(x: minX + 0.86840689 * r, y: minY + 0.02210862 * r),
                  control2: CGPoint(x: minX + 1.08849323 * r, y: minY))
    path.closeSubpath()
    return path
}

func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)
}

func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r), transform: nil)
}

/// A square of side `r` at a corner, minus the quarter circle that rounds it:
/// adding it fills a concave fillet, subtracting it rounds a convex corner.
func cornerFillet(cornerX: CGFloat, cornerY: CGFloat, dx: CGFloat, dy: CGFloat, r: CGFloat) -> CGPath {
    let square = CGPath(rect: CGRect(x: min(cornerX, cornerX + dx * r), y: min(cornerY, cornerY + dy * r),
                                     width: r, height: r), transform: nil)
    return square.subtracting(circle(cornerX + dx * r, cornerY + dy * r, r))
}

// MARK: - The mark, in the 1254 px coordinates of the reference artwork

/// Menu bar with a notch cradling the orange "status item".
func menuBarPath() -> CGPath {
    let notchCenter: CGFloat = 804
    var bar = roundedRect(207, 291, 739, 35, 17.5)

    // Outer cup below the bar, joined to it with small concave fillets.
    let outerLeft = notchCenter - 65, outerRight = notchCenter + 65
    let cup = CGMutablePath()
    cup.move(to: CGPoint(x: outerLeft, y: 300))
    cup.addLine(to: CGPoint(x: outerRight, y: 300))
    cup.addArc(tangent1End: CGPoint(x: outerRight, y: 377), tangent2End: CGPoint(x: notchCenter, y: 377), radius: 34)
    cup.addArc(tangent1End: CGPoint(x: outerLeft, y: 377), tangent2End: CGPoint(x: outerLeft, y: 300), radius: 34)
    cup.closeSubpath()
    bar = bar.union(cup)
    bar = bar.union(cornerFillet(cornerX: outerLeft, cornerY: 326, dx: -1, dy: 1, r: 10))
    bar = bar.union(cornerFillet(cornerX: outerRight, cornerY: 326, dx: 1, dy: 1, r: 10))

    // Inner cut that opens the cup, with the bar's top edge rounded into it.
    let innerLeft = notchCenter - 50, innerRight = notchCenter + 50
    let cut = CGMutablePath()
    cut.move(to: CGPoint(x: innerLeft, y: 270))
    cut.addLine(to: CGPoint(x: innerRight, y: 270))
    cut.addArc(tangent1End: CGPoint(x: innerRight, y: 368), tangent2End: CGPoint(x: notchCenter, y: 368), radius: 27)
    cut.addArc(tangent1End: CGPoint(x: innerLeft, y: 368), tangent2End: CGPoint(x: innerLeft, y: 270), radius: 27)
    cut.closeSubpath()
    bar = bar.subtracting(cut)
    bar = bar.subtracting(cornerFillet(cornerX: innerLeft, cornerY: 291, dx: -1, dy: 1, r: 12))
    bar = bar.subtracting(cornerFillet(cornerX: innerRight, cornerY: 291, dx: 1, dy: 1, r: 12))

    // Short trailing segment.
    return bar.union(roundedRect(963, 291, 83, 35, 17.5))
}

func notchDotPath() -> CGPath { roundedRect(774, 296, 60, 53, 10) }

func letterOPath() -> CGPath {
    let ring = CGMutablePath()
    ring.addPath(circle(410.5, 645, 219.5))
    ring.addPath(circle(410.5, 645, 110.5))
    return ring
}

func stemPath() -> CGPath { roundedRect(666, 434, 115, 425, 14) }

/// Upper bowl of the B: a D shape cut along a 45° diagonal.
func upperBowlPath() -> CGPath {
    let left: CGFloat = 792, top: CGFloat = 436
    let center = CGPoint(x: 928, y: 529), radius: CGFloat = 93
    // Where the arc meets the diagonal x - y = left - top.
    let k = (left - top) - (center.x - center.y)
    let angle = acos(k / (radius * sqrt(2))) - .pi / 4
    let path = CGMutablePath()
    path.move(to: CGPoint(x: left, y: top))
    path.addLine(to: CGPoint(x: center.x, y: top))
    path.addArc(center: center, radius: radius, startAngle: -.pi / 2, endAngle: angle, clockwise: false)
    path.closeSubpath()
    return path
}

/// Lower bowl of the B.
func lowerBowlPath() -> CGPath {
    let left: CGFloat = 796, top: CGFloat = 631, bottom: CGFloat = 859
    let radius = (bottom - top) / 2
    let centerX: CGFloat = 1063 - radius
    let path = CGMutablePath()
    path.move(to: CGPoint(x: left, y: top + 8))
    path.addArc(tangent1End: CGPoint(x: left, y: top), tangent2End: CGPoint(x: centerX, y: top), radius: 8)
    path.addLine(to: CGPoint(x: centerX, y: top))
    path.addArc(center: CGPoint(x: centerX, y: top + radius), radius: radius,
                startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
    path.addArc(tangent1End: CGPoint(x: left, y: bottom), tangent2End: CGPoint(x: left, y: top), radius: 8)
    path.closeSubpath()
    return path
}

// MARK: - Render

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(
    data: nil, width: Int(canvas), height: Int(canvas), bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }

// Work top-down like the reference artwork.
context.translateBy(x: 0, y: canvas)
context.scaleBy(x: 1, y: -1)

let squircle = continuousRoundedRect(body, radius: bodyRadius)

// Soft drop shadow, as on system icons.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 30,
                  color: CGColor(gray: 0, alpha: 0.24))
context.addPath(squircle)
context.setFillColor(backgroundBottom)
context.fillPath()
context.restoreGState()

// Background gradient.
context.saveGState()
context.addPath(squircle)
context.clip()
let gradient = CGGradient(colorsSpace: colorSpace, colors: [backgroundTop, backgroundBottom] as CFArray,
                          locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.minY), end: CGPoint(x: 0, y: body.maxY), options: [])

// Keep the reference artwork's proportions (its frame was 1079 px wide) and
// centre the mark (x 190...1063, y 291...863) in the body, lifted slightly
// for optical balance.
let scale = body.width / 1079
let opticalLift: CGFloat = 6
context.translateBy(x: body.midX, y: body.midY - opticalLift)
context.scaleBy(x: scale, y: scale)
context.translateBy(x: -(190 + 1063) / 2, y: -(291 + 863) / 2)

context.setFillColor(gray)
for path in [menuBarPath(), stemPath(), lowerBowlPath()] {
    context.addPath(path)
    context.fillPath()
}
context.addPath(letterOPath())
context.fillPath(using: .evenOdd)

context.setFillColor(orange)
for path in [notchDotPath(), upperBowlPath()] {
    context.addPath(path)
    context.fillPath()
}
context.restoreGState()

guard let image = context.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: image)
guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
