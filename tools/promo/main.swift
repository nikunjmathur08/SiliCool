//
//  main.swift — SiliCool promo video generator
//
//  Renders a silent 1080p H.264 film straight from the app's own SwiftUI views,
//  so the footage is the real interface rather than a mockup. Sensor values come
//  from a live SMC read at launch.
//
//  Build and run from the repo root:
//    swiftc -O -o /tmp/promo $(cat tools/promo/sources.txt) tools/promo/main.swift
//    /tmp/promo docs/silicool-promo.mp4
//
//  The gauge is redrawn here with an explicit phase rather than reusing the
//  app's TimelineView, because a film needs deterministic frames.
//

import SwiftUI
import AppKit
import AVFoundation

// MARK: - Film timing

let fps = 30.0
let duration = 24.0

// Optional second argument renders a smaller, lighter cut for the web.
let web = CommandLine.arguments.contains("--web")
let size = web ? CGSize(width: 1280, height: 720) : CGSize(width: 1920, height: 1080)
let bitrate = web ? 1_800_000 : 6_000_000

/// Eased 0→1 over a window, for entrances and cross-fades.
func ramp(_ t: Double, _ start: Double, _ end: Double) -> Double {
    guard end > start else { return t >= end ? 1 : 0 }
    let x = ((t - start) / (end - start)).clamped(to: 0...1)
    return x * x * (3 - 2 * x)
}

/// 0 outside the window, 1 inside, with soft edges — one scene's visibility.
func window(_ t: Double, _ from: Double, _ to: Double, fade: Double = 0.5) -> Double {
    min(ramp(t, from, from + fade), 1 - ramp(t, to - fade, to))
}

// MARK: - Deterministic gauge

struct PromoGauge: View {
    var rpm: Double
    var minimumRPM: Double
    var maximumRPM: Double
    var phase: Double
    var thermalLoad: Double
    var diameter: CGFloat

    private var duty: Double { (rpm / maximumRPM).clamped(to: 0...1) }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Heat.colour(for: thermalLoad, scheme: .dark, opacity: 0.34), location: 0),
                        .init(color: Heat.colour(for: thermalLoad, scheme: .dark, opacity: 0.16), location: 0.42),
                        .init(color: .clear, location: 1)
                    ]), center: .center, startRadius: 0, endRadius: diameter * 0.46))
                .blur(radius: 18)

            Canvas { ctx, canvasSize in
                let mid = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let outer = min(canvasSize.width, canvasSize.height) / 2 - 6
                let length = outer * (0.05 + 0.16 * duty)
                let brightness = max(0.22, duty)

                var bars = Path()
                for index in 0..<120 {
                    let angle = Double(index) / 120 * 2 * .pi - .pi / 2 + phase
                    let c = cos(angle), s = sin(angle)
                    bars.move(to: CGPoint(x: mid.x + c * (outer - length), y: mid.y + s * (outer - length)))
                    bars.addLine(to: CGPoint(x: mid.x + c * outer, y: mid.y + s * outer))
                }
                ctx.stroke(bars, with: .color(.white.opacity(brightness)),
                           style: StrokeStyle(lineWidth: diameter / 190 * 2.1, lineCap: .round))
            }

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(verbatim: "\(Int(rpm))")
                        .font(.system(size: diameter * 0.15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("rpm")
                        .font(.system(size: diameter * 0.045, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .foregroundStyle(.white)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Captions

struct Caption: View {
    var kicker: String
    var headline: String
    var body_: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(kicker.uppercased())
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .tracking(2.4)
                .foregroundStyle(Color(red: 0.35, green: 0.66, blue: 1))
            Text(headline)
                .font(.system(size: 54, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(body_)
                .font(.system(size: 21, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 620, alignment: .leading)
    }
}

// MARK: - The frame

struct Film: View {
    var t: Double
    var monitor: HardwareMonitor
    var phase: Double
    /// Which sensor group is open, so the film shows real probe names rather
    /// than four identical collapsed rows.
    var expandedGroup: SensorGroupKind?

    private var ground: some View {
        ZStack {
            Color(red: 0.043, green: 0.047, blue: 0.055)
            RadialGradient(colors: [Color(red: 0.10, green: 0.24, blue: 0.55).opacity(0.55), .clear],
                           center: .init(x: 0.30, y: 0.45), startRadius: 0, endRadius: 900)
        }
    }

    var body: some View {
        ZStack {
            ground

            // 1. Title
            Group {
                VStack(spacing: 26) {
                    PromoGauge(rpm: 2317 + 2600 * ramp(t, 0.4, 3.2), minimumRPM: 2317,
                               maximumRPM: 7826, phase: phase, thermalLoad: 0.25, diameter: 260)
                    Text("SiliCool")
                        .font(.system(size: 76, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Fan and thermal telemetry for Apple silicon")
                        .font(.system(size: 24, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(window(t, 0, 4.6))
            }

            // 2. The panel, with the fans ramping
            sceneWithPanel(
                visible: window(t, 4.4, 10.4),
                caption: Caption(kicker: "Reads the SMC directly",
                                 headline: "Every fan, every sensor.",
                                 body_: "3,486 keys enumerated. 256 live temperature sensors. A 15 ms sample, off the main thread."),
                gaugeRPM: 2317 + 5300 * ramp(t, 5.0, 9.4))

            // 3. Sensors
            sceneWithPanel(
                visible: window(t, 10.2, 15.6),
                caption: Caption(kicker: "Named by measurement",
                                 headline: "Not by a lookup table.",
                                 body_: "Core counts come from the OS. Duplicate keys are found by sampling, not by trusting a published list."),
                gaugeRPM: 4900)

            // 4. Control
            sceneWithPanel(
                visible: window(t, 15.4, 20.4),
                caption: Caption(kicker: "Curves, or hold it yourself",
                                 headline: "Take the fans.",
                                 body_: "Then hand them back — every exit path returns them to automatic, including Ctrl-C."),
                gaugeRPM: 7826)

            // 5. End card
            VStack(spacing: 22) {
                Text("SiliCool")
                    .font(.system(size: 62, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Free · Apple silicon · macOS 14 and later")
                    .font(.system(size: 23, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(window(t, 20.2, 24.0, fade: 0.6))
        }
        .frame(width: 1920, height: 1080)
        .scaleEffect(size.width / 1920, anchor: .topLeading)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
    }

    /// The real panel on the left, a caption on the right.
    private func sceneWithPanel(visible: Double, caption: Caption, gaugeRPM: Double) -> some View {
        HStack(spacing: 84) {
            VStack(spacing: 14) {
                PromoGauge(rpm: gaugeRPM, minimumRPM: 2317, maximumRPM: 7826,
                           phase: phase, thermalLoad: (gaugeRPM / 7826) * 0.9, diameter: 226)
                ControlDeck(monitor: monitor)
                Divider().opacity(0.4)
                VStack(spacing: 9) {
                    ForEach(monitor.sensorGroups.prefix(4)) { group in
                        SensorGroupRow(group: group,
                                       isExpanded: group.kind == expandedGroup,
                                       toggle: {})
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(width: 460, height: 780)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.09, green: 0.10, blue: 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.07)))
            .shadow(color: .black.opacity(0.5), radius: 40, y: 18)

            caption
        }
        .opacity(visible)
    }
}

// MARK: - Encoding

@MainActor
func renderFrame(_ view: Film) -> CGImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    return renderer.cgImage
}

func makePixelBuffer(_ image: CGImage, pool: CVPixelBufferPool) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer?
    guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
          let buffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

    guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: Int(size.width), height: Int(size.height),
        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    else { return nil }

    context.draw(image, in: CGRect(origin: .zero, size: size))
    return buffer
}

let outputPath = CommandLine.arguments.dropFirst().first { !$0.hasPrefix("--") } ?? "silicool-promo.mp4"
let outputURL = URL(fileURLWithPath: outputPath)
try? FileManager.default.removeItem(at: outputURL)

let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: Int(size.width),
    AVVideoHeightKey: Int(size.height),
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: bitrate,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
])
input.expectsMediaDataInRealTime = false

let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferWidthKey as String: Int(size.width),
        kCVPixelBufferHeightKey as String: Int(size.height)
    ])

writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

MainActor.assumeIsolated {
    // Real sensors, read once.
    let probe = SensorProbe()
    let monitor = HardwareMonitor()
    monitor.applyOneShot(discovery: probe.discover(), snapshot: probe.sample())

    let total = Int(duration * fps)
    var phase = 0.0

    for index in 0..<total {
        let t = Double(index) / fps
        // The app caps rotation at 0.2 rev/s; the film matches it.
        phase += 0.2 * (1 / fps) * 2 * .pi

        // Scene state the views read from the monitor has to be set before the
        // frame is rendered.
        monitor.curveEnabled = (t >= 15.4 && t < 20.4)
        let expanded: SensorGroupKind? = (t >= 10.2 && t < 15.6) ? .cpuCores : nil

        guard let image = renderFrame(Film(t: t, monitor: monitor, phase: phase, expandedGroup: expanded)),
              let pool = adaptor.pixelBufferPool,
              let buffer = makePixelBuffer(image, pool: pool) else { continue }

        while !input.isReadyForMoreMediaData { usleep(2000) }
        adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps)))

        if index % 60 == 0 {
            print(String(format: "  %4.1f s / %.0f s", t, duration))
            fflush(stdout)
        }
    }

    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()

    if writer.status == .completed {
        let attributes = try? FileManager.default.attributesOfItem(atPath: outputPath)
        let bytes = (attributes?[.size] as? Int) ?? 0
        print(String(format: "wrote %@ (%.1f MB)", outputPath, Double(bytes) / 1_048_576))
    } else {
        print("failed: \(writer.error?.localizedDescription ?? "unknown")")
        exit(1)
    }
}
