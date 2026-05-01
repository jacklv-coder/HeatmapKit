//
//  ContentView.swift
//  HeatmapKitDemo
//

import SwiftUI
import HeatmapKit

// MARK: - Top-level tabs

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SingleHeatmapView()
            }
            .tabItem { Label("Single", systemImage: "calendar") }

            NavigationStack {
                BoardsView()
            }
            .tabItem { Label("Boards", systemImage: "square.grid.2x2") }
        }
    }
}

// MARK: - Single heatmap demo

struct SingleHeatmapView: View {
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
            .fitToWidth(minCellSize: 15)
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

// MARK: - Boards demo (Streaks-style habit cards)

struct BoardsView: View {
    @State private var boards = Board.samples()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(boards) { board in
                    HabitCard(board: board) {
                        toggle(board)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Boards")
    }

    private func toggle(_ board: Board) {
        guard let i = boards.firstIndex(where: { $0.id == board.id }) else { return }
        boards[i].completed.toggle()
    }
}

struct Board: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let cardBackground: Color
    let foreground: Color
    let buttonBackground: Color
    let palette: [Color]      // 5-step (empty, then 4 intensities)
    let actionLabel: String
    var completed: Bool
    let data: [Date: Double]

    static func samples() -> [Board] {
        return [
            Board(
                emoji: "💊",
                title: "Take supplements",
                cardBackground: .white,
                foreground: .black,
                buttonBackground: Color(white: 0.94),
                palette: [
                    Color(white: 0.93),
                    Color(red: 0.62, green: 0.62, blue: 0.92),
                    Color(red: 0.50, green: 0.50, blue: 0.95),
                    Color(red: 0.40, green: 0.40, blue: 0.92),
                    Color(red: 0.30, green: 0.30, blue: 0.78),
                ],
                actionLabel: "Check In",
                completed: false,
                data: randomData(activeProbability: 0.55)
            ),
            Board(
                emoji: "👁",
                title: "Meditate",
                cardBackground: .white,
                foreground: .black,
                buttonBackground: Color(white: 0.94),
                palette: [
                    Color(white: 0.93),
                    Color(red: 0.95, green: 0.65, blue: 0.78),
                    Color(red: 0.85, green: 0.50, blue: 0.65),
                    Color(red: 0.70, green: 0.35, blue: 0.55),
                    Color(red: 0.45, green: 0.10, blue: 0.32),
                ],
                actionLabel: "Check In",
                completed: false,
                data: randomData(activeProbability: 0.6)
            ),
            Board(
                emoji: "☕",
                title: "Limit coffee",
                cardBackground: .white,
                foreground: .black,
                buttonBackground: Color(white: 0.94),
                palette: [
                    Color(white: 0.93),
                    Color(red: 0.92, green: 0.85, blue: 0.70),
                    Color(red: 0.80, green: 0.65, blue: 0.45),
                    Color(red: 0.60, green: 0.45, blue: 0.20),
                    Color(red: 0.45, green: 0.32, blue: 0.10),
                ],
                actionLabel: "1 cup",
                completed: true,
                data: randomData(activeProbability: 0.65)
            ),
            Board(
                emoji: "👩‍💻",
                title: "Work on side pr…",
                cardBackground: Color(red: 0.27, green: 0.10, blue: 0.20),
                foreground: .white,
                buttonBackground: Color(red: 0.97, green: 0.88, blue: 0.92),
                palette: [
                    Color(red: 0.40, green: 0.18, blue: 0.28),     // dark "empty" inside dark card
                    Color(red: 0.85, green: 0.55, blue: 0.75),
                    Color(red: 0.95, green: 0.75, blue: 0.85),
                    Color(red: 0.95, green: 0.45, blue: 0.70),
                    Color(red: 1.00, green: 0.85, blue: 0.92),
                ],
                actionLabel: "1 hr",
                completed: true,
                data: randomData(activeProbability: 0.65)
            ),
            Board(
                emoji: "🛏️",
                title: "Go To Sleep At…",
                cardBackground: Color(red: 0.10, green: 0.18, blue: 0.30),
                foreground: .white,
                buttonBackground: Color(red: 0.85, green: 0.92, blue: 1.00),
                palette: [
                    Color(red: 0.18, green: 0.25, blue: 0.40),
                    Color(red: 0.45, green: 0.65, blue: 0.95),
                    Color(red: 0.55, green: 0.72, blue: 0.95),
                    Color(red: 0.65, green: 0.78, blue: 0.95),
                    Color(red: 0.75, green: 0.85, blue: 0.95),
                ],
                actionLabel: "Check In",
                completed: false,
                data: randomData(activeProbability: 0.7)
            ),
            Board(
                emoji: "📱",
                title: "No phone after…",
                cardBackground: .white,
                foreground: .black,
                buttonBackground: Color(white: 0.94),
                palette: [
                    Color(white: 0.93),
                    Color(white: 0.40),
                    Color(white: 0.25),
                    Color(white: 0.12),
                    Color(white: 0.0),
                ],
                actionLabel: "Check In",
                completed: false,
                data: randomData(activeProbability: 0.5)
            ),
        ]
    }

    /// 49 days (7 weeks) ending today, each cell active with the given probability,
    /// values 1...4 to map across the four non-empty intensity levels.
    private static func randomData(activeProbability p: Double) -> [Date: Double] {
        var d: [Date: Double] = [:]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for offset in 0...48 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if Double.random(in: 0..<1) < p {
                d[date] = Double(Int.random(in: 1...4))
            }
        }
        return d
    }
}

struct HabitCard: View {
    let board: Board
    let onToggle: () -> Void

    private static let dayCount = 49 // 7 weeks

    private var dateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(Self.dayCount - 1), to: today)!
        return start...today
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 6) {
                Text(board.emoji).font(.title3)
                Text(board.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }

            // Compact heatmap — 7 weeks × 7 days, no scroll, no labels.
            CalendarHeatmap(
                contributions: board.data,
                dateRange: dateRange
            )
            .cellSize(15)
            .cellSpacing(4)
            .scrollEnabled(false)
            .levels(board.palette)
            .showMonthLabels(false)
            .todayHighlightColor(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)

            // Footer button
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: board.completed ? "checkmark.circle.fill" : "circle")
                        .imageScale(.medium)
                    Text(board.actionLabel)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(board.buttonBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(board.cardBackground, in: RoundedRectangle(cornerRadius: 22))
        .foregroundStyle(board.foreground)
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
