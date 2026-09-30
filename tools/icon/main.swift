//
//  main.swift — app icon
//
//  Composites the fan artwork (icon.png at the repo root) onto the dark
//  rounded plate and renders every size the asset catalog needs. Run
//  tools/icon/build.sh, which also writes Contents.json.
//
//  The artwork arrives as a 597px PNG, so each size is taken through ImageIO's
//  thumbnail path rather than letting SwiftUI scale it — a plain bilinear
//  stretch from 597 to 16 leaves a grey smudge instead of a fan.
//

import SwiftUI
import AppKit
import ImageIO

struct AppIcon: View {
    var pixels: CGFloat
    var artwork: NSImage

    /// Apple's macOS grid: the rounded square fills 824 of a 1024 canvas.
    static func plateSize(for pixels: CGFloat) -> CGFloat {
        let inset = pixels * (1024 - 824) / 2 / 1024
        return pixels - inset * 2
    }

    /// The fan covers most of the plate but leaves the corner radius readable.
    static func artworkSize(for pixels: CGFloat) -> CGFloat {
        plateSize(for: pixels) * 0.86
    }

    private var plateSize: CGFloat { Self.plateSize(for: pixels) }
    private var artworkSize: CGFloat { Self.artworkSize(for: pixels) }

    var body: some View {
        ZStack { plate; fan }
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

    private var fan: some View {
        Image(nsImage: artwork)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: artworkSize, height: artworkSize)
    }
}

/// ImageIO downsamples with a proper prefilter; SwiftUI does not.
func artwork(atMaxPixels pixels: Int, from source: CGImageSource) -> NSImage? {
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
func write(pixels: Int, source: CGImageSource, to path: String) {
    let target = Int(AppIcon.artworkSize(for: CGFloat(pixels)).rounded(.up))
    guard let artwork = artwork(atMaxPixels: target, from: source) else {
        print("failed to scale artwork for \(pixels)"); exit(1)
    }
    let renderer = ImageRenderer(content: AppIcon(pixels: CGFloat(pixels), artwork: artwork))
    renderer.scale = 1
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("render failed at \(pixels)"); exit(1)
    }
    try! png.write(to: URL(fileURLWithPath: path))
}

let arguments = CommandLine.arguments
guard arguments.count > 2 else {
    print("usage: render <output directory> <source artwork>"); exit(1)
}
let outputDirectory = arguments[1]
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[2]) as CFURL, nil) else {
    print("error: cannot read artwork at \(arguments[2])"); exit(1)
}
MainActor.assumeIsolated {
    // 1x and 2x for every size the macOS catalog asks for.
    for (size, name) in [(16, "icon_16x16"), (32, "icon_16x16@2x"),
                         (32, "icon_32x32"), (64, "icon_32x32@2x"),
                         (128, "icon_128x128"), (256, "icon_128x128@2x"),
                         (256, "icon_256x256"), (512, "icon_256x256@2x"),
                         (512, "icon_512x512"), (1024, "icon_512x512@2x")] {
        write(pixels: size, source: source, to: "\(outputDirectory)/\(name).png")
    }
    print("  rendered 10 sizes")
}
