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
                DetailCardView()
            }
            .tabItem { Label("Detail", systemImage: "rectangle.stack") }

            NavigationStack {
                BoardsView()
            }
            .tabItem { Label("Boards", systemImage: "square.grid.2x2") }

            NavigationStack {
                SingleHeatmapView()
            }
            .tabItem { Label("Single", systemImage: "calendar") }

            NavigationStack {
                LayoutSandboxView()
            }
            .tabItem { Label("Sandbox", systemImage: "ruler") }
        }
    }
}

// MARK: - Layout protocol sandbox
//
// Throwaway test bed for the SwiftUI `Layout` protocol approach to
// width-aware cell sizing. The four scenarios below isolate the layout
// behaviors that the previous `@State + GeometryReader` adaptive body
// got wrong:
//
//  1. wide container — verify cells cap at preferredCellSize and the
//     grid is leading-aligned (no auto-centering)
//  2. narrow fixed container — verify cells shrink to fit, grid fills
//     container exactly with no overflow
//  3. inside `.frame(maxWidth: .infinity, alignment: .leading)` —
//     verify Layout returns the right size and alignment is honored
//     (the broken `dc3565f` codepath silently lost this)
//  4. inside an oversized VStack-with-header — verify the grid sizes
//     to the parent's proposal even when a sibling wants more width
//     (the right-shift bug from the user's screenshot)
//
// Once these four panels render correctly on iPhone, the same Layout
// can be lifted into `CalendarHeatmap.adaptiveBody`.

struct LayoutSandboxView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Test 1 — wide container, no width constraint")
                    .font(.caption.weight(.semibold))
                AdaptiveCellGrid()
                    .background(Color.blue.opacity(0.1))

                Text("Test 2 — narrow fixed-width container (160pt)")
                    .font(.caption.weight(.semibold))
                AdaptiveCellGrid()
                    .frame(width: 160)
                    .background(Color.green.opacity(0.1))

                Text("Test 3 — wrapped in .frame(maxWidth: .infinity, alignment: .leading)")
                    .font(.caption.weight(.semibold))
                AdaptiveCellGrid()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))

                Text("Test 4 — inside VStack with sibling header (the right-shift bug)")
                    .font(.caption.weight(.semibold))
                VStack(alignment: .leading, spacing: 8) {
                    Text("👩‍💻 Header sibling").font(.headline)
                    AdaptiveCellGrid()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
            }
            .padding(20)
        }
        .navigationTitle("Sandbox")
    }
}

/// Wrapper that drives the custom `AdaptiveLayout` with sample purple
/// cells so we can eyeball width / alignment / overflow behavior in
/// each test panel.
struct AdaptiveCellGrid: View {
    let weeks: Int = 16
    let rows: Int = 7
    let preferredCellSize: CGFloat = 20
    let minCellSize: CGFloat = 8
    let cellSpacing: CGFloat = 4

    var body: some View {
        AdaptiveLayout(
            weeks: weeks,
            rows: rows,
            preferredCellSize: preferredCellSize,
            minCellSize: minCellSize,
            cellSpacing: cellSpacing
        ) {
            ForEach(0..<(weeks * rows), id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.purple.opacity(0.20 + Double((i * 7) % 4) * 0.20))
            }
        }
    }
}

/// Custom `Layout` that picks `cellSize` from the proposed width in a
/// single pass, returns the resulting natural size to the parent, and
/// places each subview at its computed `(week, row)` position.
///
/// Subviews are expected in row-major order: `index = week * rows + row`.
struct AdaptiveLayout: Layout {
    let weeks: Int
    let rows: Int
    let preferredCellSize: CGFloat
    let minCellSize: CGFloat
    let cellSpacing: CGFloat

    struct Cache {
        var cellSize: CGFloat = 0
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let proposedWidth = proposal.width ?? .infinity
        let cellSize = computeCellSize(for: proposedWidth)
        cache.cellSize = cellSize

        let totalWidth =
            CGFloat(weeks) * cellSize + CGFloat(max(weeks - 1, 0)) * cellSpacing
        let totalHeight =
            CGFloat(rows) * cellSize + CGFloat(max(rows - 1, 0)) * cellSpacing

        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        // Recompute on placement in case proposal in placeSubviews
        // differs from sizeThatFits (rare, but guard against it).
        let cellSize = cache.cellSize > 0
            ? cache.cellSize
            : computeCellSize(for: proposal.width ?? bounds.width)
        let cellProposal = ProposedViewSize(width: cellSize, height: cellSize)

        for (i, subview) in subviews.enumerated() {
            let week = i / rows
            let row = i % rows
            let x = bounds.minX + CGFloat(week) * (cellSize + cellSpacing)
            let y = bounds.minY + CGFloat(row) * (cellSize + cellSpacing)
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: cellProposal
            )
        }
    }

    private func computeCellSize(for proposedWidth: CGFloat) -> CGFloat {
        guard proposedWidth.isFinite, proposedWidth > 0, weeks > 0 else {
            return preferredCellSize
        }
        let totalSpacing = CGFloat(max(weeks - 1, 0)) * cellSpacing
        let availableForCells = max(0, proposedWidth - totalSpacing)
        let allFitSize = availableForCells / CGFloat(weeks)

        if allFitSize >= preferredCellSize { return preferredCellSize }
        if allFitSize >= minCellSize { return allFitSize }
        return minCellSize
    }
}

// MARK: - Detail card demo (one big card per board)

/// One large card per board, mirroring the Boards-tab grid one-to-one
/// so users can see the same set of habits in two visual styles. Each
/// card uses the board's own theme (background + palette) but renders
/// at a much larger cell size with weekday labels — the wide-detail
/// counterpart to the compact `HabitCard` in the Boards tab.
struct DetailCardView: View {
    @State private var boards = Board.samples()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(boards) { board in
                    BigBoardCard(board: board)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detail")
    }
}

struct BigBoardCard: View {
    let board: Board

    /// 16 weeks — matches the reference screenshot window
    /// (approximately 110 days).
    private static let dayCount = 16 * 7

    private var dateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(Self.dayCount - 1), to: today)!
        return start...today
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 6) {
                Text(board.emoji).font(.title3)
                Text(board.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }

            // Heatmap with weekday labels on the left. fitToWidth lets
            // each cell grow to fill the card width on iPad / wide
            // screens and shrink (down to 8pt) on a phone-narrow card.
            CalendarHeatmap(
                contributions: board.data,
                dateRange: dateRange
            )
            .cellSize(20)
            .cellSpacing(4)
            .scrollEnabled(false)
            .levels(board.palette)
            .showWeekdayLabels(true)
            .showMonthLabels(false)
            .todayHighlightColor(nil)
            .fitToWidth(minCellSize: 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(board.cardBackground, in: RoundedRectangle(cornerRadius: 28))
        .foregroundStyle(board.foreground)
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
        // `.fitToWidth(...)` so cells fill the card exactly: wide
        // containers cap at preferred (14pt), mid containers shrink
        // proportionally to fit all 53 weeks, narrow containers size
        // cells so a whole-week window fills the viewport at `min` and
        // scroll the rest of the history into view — no left-edge
        // clipping (the trailing-anchor snap math is wired into the
        // cellSize choice). See `.fitToWidth(_:)` doc.
        CalendarHeatmap(contributions: data)
            .levels(palette)
            .showWeekdayLabels(weekdayLabels)
            .fitToWidth(minCellSize: 14)
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
                emoji: "☕",
                title: "Limit coffee",
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

    /// 16 weeks (112 days) ending today, each cell active with the given
    /// probability, values 1...4 to map across the four non-empty intensity
    /// levels. Range is wide enough to cover both the small `HabitCard`
    /// (last 49 days) and the wide `BigBoardCard` (full 112 days).
    private static func randomData(activeProbability p: Double) -> [Date: Double] {
        var d: [Date: Double] = [:]
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for offset in 0...111 {
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
