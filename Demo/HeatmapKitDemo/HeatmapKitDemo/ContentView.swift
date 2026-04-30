//
//  ContentView.swift
//  HeatmapKitDemo
//

import SwiftUI
import HeatmapKit

struct ContentView: View {
    @State private var palette: ColorPalette = .green
    @State private var data: [Date: Double] = SampleData.generate()
    @State private var weekdayLabels = false

    var body: some View {
        let heatmap = makeHeatmap()

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                heatmap
                Divider()
                controls(for: heatmap)
                Divider()
                stats
            }
            .padding(20)
        }
    }

    // MARK: - Heatmap

    private func makeHeatmap() -> CalendarHeatmap<HeatmapDay> {
        CalendarHeatmap(contributions: data)
            .levels(palette)
            .showWeekdayLabels(weekdayLabels)
            .tooltipOnTap { date, value in
                let day = date.formatted(date: .abbreviated, time: .omitted)
                return value == 0 ? "\(day)\nno activity"
                                  : "\(day)\n\(Int(value)) commits"
            }
            .accessibilityCellLabel { date, value in
                let day = date.formatted(date: .abbreviated, time: .omitted)
                return value == 0 ? "\(day), no activity"
                                  : "\(day), \(Int(value)) commits"
            }
    }

    // MARK: - Sections

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HeatmapKit").font(.largeTitle.bold())
            Text("Tap a cell for the built-in tooltip. Hit Share to exercise the snapshot API.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func controls(for heatmap: CalendarHeatmap<HeatmapDay>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Palette", selection: $palette) {
                Text("Green").tag(ColorPalette.green)
                Text("Orange").tag(ColorPalette.orange)
                Text("Blue").tag(ColorPalette.blue)
                Text("Purple").tag(ColorPalette.purple)
                Text("Red").tag(ColorPalette.red)
                Text("Grayscale").tag(ColorPalette.grayscale)
            }
            .pickerStyle(.menu)

            Toggle("Weekday labels", isOn: $weekdayLabels)

            HStack {
                Button("Regenerate") {
                    data = SampleData.generate()
                }
                .buttonStyle(.bordered)

                Spacer()

                if let cg = heatmap.snapshot(scale: 3, background: Color.black) {
                    let image = Image(decorative: cg, scale: 3)
                    ShareLink(item: image,
                              preview: SharePreview("Activity", image: image)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder
    private var stats: some View {
        let active = data.values.filter { $0 > 0 }.count
        let total = Int(data.values.reduce(0, +))
        let best = Int(data.values.max() ?? 0)

        HStack(alignment: .top, spacing: 24) {
            stat("Active days", "\(active)")
            stat("Total", "\(total)")
            stat("Best day", "\(best)")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title2.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sample data

enum SampleData {
    /// Generates a year of pseudo-realistic activity: ~60 % active days,
    /// values skewed toward small numbers with occasional spikes.
    static func generate() -> [Date: Double] {
        var data: [Date: Double] = [:]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for offset in 0...364 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if Double.random(in: 0..<1) < 0.6 {
                let raw = Double.random(in: 0..<1)
                let value = floor(pow(raw, 2.0) * 20.0 + 1.0) // 1…21, skewed small
                data[date] = value
            }
        }
        return data
    }
}

#Preview {
    ContentView()
}
