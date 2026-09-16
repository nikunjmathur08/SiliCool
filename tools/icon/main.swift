//
//  main.swift — app icon
//
//  Renders every size the asset catalog needs. Blade count and weight scale
//  with the rendered size, because a 44-blade ring turns into a grey smudge at
//  16pt. Run tools/icon/build.sh, which also writes Contents.json.
//

import SwiftUI
import AppKit

struct AppIcon: View {
    var pixels: CGFloat

    /// Apple's macOS grid: the rounded square fills 824 of a 1024 canvas.
    private var plateInset: CGFloat { pixels * (1024 - 824) / 2 / 1024 }
    private var plateSize: CGFloat { pixels - plateInset * 2 }
    private var barCount: Int { pixels < 64 ? 12 : (pixels < 160 ? 22 : 34) }
    private var barWidth: CGFloat { max(1.2, plateSize * (pixels < 64 ? 0.045 : 0.021)) }
    private var ringOuter: CGFloat { plateSize * 0.40 }
    private var barLength: CGFloat { plateSize * (pixels < 64 ? 0.145 : 0.115) }

    var body: some View {
        ZStack { plate; core; ring }
            .frame(width: pixels, height: pixels)
    }

    private var plate: some View {
        RoundedRectangle(cornerRadius: plateSize * 0.2237, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 0.19, green: 0.20, blue: 0.23),
                                          Color(red: 0.07, green: 0.07, blue: 0.09)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: plateSize * 0.2237, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.18), .clear],
                                                 startPoint: .top, endPoint: .bottom),
                                  lineWidth: max(0.5, plateSize * 0.006)))
            .frame(width: plateSize, height: plateSize)
    }

    /// Cool at the centre: a warm dot inside a radial ring reads as a sun,
    /// which is the opposite of what this app is for.
    private var core: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(gradient: Gradient(stops: [
                    .init(color: Color(red: 0.30, green: 0.64, blue: 1.00).opacity(0.34), location: 0),
                    .init(color: Color(red: 0.20, green: 0.45, blue: 0.95).opacity(0.0), location: 1)]),
                    center: .center, startRadius: 0, endRadius: plateSize * 0.30))
                .frame(width: plateSize * 0.66, height: plateSize * 0.66)

            Circle()
                .fill(RadialGradient(gradient: Gradient(stops: [
                    .init(color: Color(red: 0.72, green: 0.89, blue: 1.00), location: 0),
                    .init(color: Color(red: 0.28, green: 0.64, blue: 1.00), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.38, blue: 0.92).opacity(0.0), location: 1)]),
                    center: .init(x: 0.45, y: 0.40), startRadius: 0, endRadius: plateSize * 0.16))
                .frame(width: plateSize * 0.30, height: plateSize * 0.30)
                .blur(radius: plateSize * 0.010)
        }
    }

    private var ring: some View {
        Canvas { ctx, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            // Blades lean tangentially. A purely radial ring is a sunburst;
            // a leaning one is an impeller.
            let lean = 0.30
            var path = Path()
            for index in 0..<barCount {
                let angle = Double(index) / Double(barCount) * 2 * .pi - .pi / 2
                let innerRadius = ringOuter - barLength
                path.move(to: CGPoint(x: centre.x + cos(angle + lean) * innerRadius,
                                      y: centre.y + sin(angle + lean) * innerRadius))
                path.addLine(to: CGPoint(x: centre.x + cos(angle) * ringOuter,
                                         y: centre.y + sin(angle) * ringOuter))
            }
            ctx.stroke(path, with: .color(.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: barWidth, lineCap: .round))
        }
        .frame(width: pixels, height: pixels)
    }
}

@MainActor
func write(pixels: Int, to path: String) {
    let renderer = ImageRenderer(content: AppIcon(pixels: CGFloat(pixels)))
    renderer.scale = 1
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("render failed at \(pixels)"); exit(1)
    }
    try! png.write(to: URL(fileURLWithPath: path))
}

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
MainActor.assumeIsolated {
    // 1x and 2x for every size the macOS catalog asks for.
    for (size, name) in [(16, "icon_16x16"), (32, "icon_16x16@2x"),
                         (32, "icon_32x32"), (64, "icon_32x32@2x"),
                         (128, "icon_128x128"), (256, "icon_128x128@2x"),
                         (256, "icon_256x256"), (512, "icon_256x256@2x"),
                         (512, "icon_512x512"), (1024, "icon_512x512@2x")] {
        write(pixels: size, to: "\(outputDirectory)/\(name).png")
    }
    print("  rendered 10 sizes")
}
