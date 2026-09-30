//
//  main.swift — installer window background
//
//  Renders the picture behind the disk image window at 1x and 2x. Run
//  tools/dmg-background/build.sh, which also combines them into the
//  multi-representation TIFF that Finder needs for Retina.
//
//  The icon positions here must match the ones in scripts/make-dmg.sh:
//  Finder places SiliCool.app at (165, 205) and Applications at (495, 205)
//  in a 660 × 420 window.
//

import SwiftUI
import AppKit
import ImageIO

let windowSize = CGSize(width: 660, height: 420)
let appIconCentre = CGPoint(x: 165, y: 205)
let applicationsCentre = CGPoint(x: 495, y: 205)
/// Points the logo occupies in the header lockup.
let logoPointSize: CGFloat = 36

struct DMGBackground: View {
    var logo: NSImage

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.09, green: 0.10, blue: 0.12),
                                    Color(red: 0.05, green: 0.05, blue: 0.07)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            // A cool bloom behind the app icon, echoing the icon itself.
            RadialGradient(colors: [Color(red: 0.20, green: 0.45, blue: 0.95).opacity(0.22), .clear],
                           center: .init(x: appIconCentre.x / windowSize.width,
                                         y: appIconCentre.y / windowSize.height),
                           startRadius: 0, endRadius: 260)

            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    Image(nsImage: logo)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: logoPointSize, height: logoPointSize)

                    Text("SiliCool")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Fan control for Apple silicon")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 34)

                Spacer()

                Text("Drag SiliCool into Applications")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.bottom, 30)
            }

            // Level with the two icons, centred between them.
            Image(systemName: "arrow.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.28))
                .position(x: (appIconCentre.x + applicationsCentre.x) / 2, y: appIconCentre.y)
        }
        .frame(width: windowSize.width, height: windowSize.height)
    }
}

/// ImageIO downsamples with a proper prefilter; SwiftUI does not.
func logo(atMaxPixels pixels: Int, from source: CGImageSource) -> NSImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(1, pixels)
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    return NSImage(cgImage: image, size: NSSize(width: pixels, height: pixels))
}

@MainActor
func write(scale: CGFloat, logoSource: CGImageSource, to path: String) {
    guard let mark = logo(atMaxPixels: Int(logoPointSize * scale), from: logoSource) else {
        print("failed to scale logo"); exit(1)
    }
    let renderer = ImageRenderer(content: DMGBackground(logo: mark))
    renderer.scale = scale
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("render failed"); exit(1)
    }
    try! png.write(to: URL(fileURLWithPath: path))
    print("  wrote \(path)")
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("usage: render <output directory> <source artwork>"); exit(1)
}
let outputDirectory = arguments[1]
guard arguments.count > 2,
      let logoSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[2]) as CFURL, nil) else {
    print("error: pass the source artwork as the second argument"); exit(1)
}
MainActor.assumeIsolated {
    write(scale: 1, logoSource: logoSource, to: "\(outputDirectory)/dmg-bg.png")
    write(scale: 2, logoSource: logoSource, to: "\(outputDirectory)/dmg-bg@2x.png")
}
