//
//  SensorPanel.swift
//  SiliCool
//
//  Sensors, grouped and in a fixed order. The list never re-sorts itself by
//  temperature — rows staying put is what makes it readable at a glance.
//

import SwiftUI

struct SensorPanel: View {
    var monitor: HardwareMonitor

    @State private var expanded: Set<String> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 9) {
                ForEach(monitor.sensorGroups) { group in
                    SensorGroupRow(group: group,
                                   isExpanded: expanded.contains(group.id)) {
                        if expanded.contains(group.id) {
                            expanded.remove(group.id)
                        } else {
                            expanded.insert(group.id)
                        }
                    }
                }
            }
            .padding(.trailing, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.never)
    }
}

// MARK: - Group row

struct SensorGroupRow: View {
    var group: SensorGroup
    var isExpanded: Bool
    var toggle: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 7) {
            Button(action: toggle) {
                HStack(spacing: 9) {
                    Image(systemName: group.kind.symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Text(group.kind.title)
                                .font(Theme.label(11))

                            Text(verbatim: "\(group.sensors.count)")
                                .font(Theme.label(9, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.primary.opacity(0.07)))

                            if let detail = group.detail {
                                Text(detail)
                                    .font(Theme.label(9))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.08))
                                Capsule()
                                    .fill(Heat.colour(for: group.thermalLoad, scheme: colorScheme))
                                    .frame(width: max(2, geometry.size.width * group.thermalLoad))
                            }
                        }
                        .frame(height: 3)
                    }

                    Text(verbatim: "\(Int(group.peak))°")
                        .font(Theme.label(12, weight: .semibold))
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Individual probes carry no published name, so they are listed
                // under their SMC key — the only honest label for them.
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)],
                          spacing: 4) {
                    ForEach(group.sensors) { sensor in
                        HStack(spacing: 4) {
                            Text(sensor.name)
                                .font(Theme.label(9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 2)
                            Text(verbatim: "\(Int(sensor.celsius))°")
                                .font(Theme.label(9, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 23)
                .padding(.bottom, 2)
            }
        }
        .animation(.snappy(duration: 0.22), value: isExpanded)
    }
}
