//
//  CalendarHeatmap.swift
//  HeatmapKit
//

import SwiftUI

// MARK: - Internal Day Bucket

/// Daily aggregated point. Identifiable by its `Date` (start-of-day).
public struct HeatmapDay: Identifiable, Sendable, Hashable {
    public let id: Date
    public let date: Date
    public let value: Double

    public init(date: Date, value: Double) {
        let day = Calendar.current.startOfDay(for: date)
        self.id = day
        self.date = day
        self.value = value
    }
}

// MARK: - CalendarHeatmap

/// A GitHub-style calendar heatmap.
///
/// ```swift
/// CalendarHeatmap(contributions: [today: 5.0])
///     .levels(.orange)
///     .onCellTap { date, value in print("\(date): \(value)") }
/// ```
///
/// The view shows a 7-row grid spanning a date range, where each cell's
/// color intensity reflects the value for that day.
public struct CalendarHeatmap<Item>: View {

    // MARK: - Stored data

    /// User-supplied items. Each item is mapped to a date and a numeric value.
    let items: [Item]
    let dateKey: KeyPath<Item, Date>
    let valueKey: KeyPath<Item, Double>
    let aggregation: Aggregation

    /// Date range to render. `nil` means "last 365 days ending today".
    let dateRange: ClosedRange<Date>?

    // MARK: - Configuration (mutated via modifiers)

    var cellSize: CGFloat = 14
    var cellSpacing: CGFloat = 3
    var cellCornerRadius: CGFloat = 3

    var palette: ColorPalette = .green
    var customLevels: [Color]? = nil
    var customThresholds: [Double]? = nil

    var firstWeekday: Weekday = .monday
    var showMonthLabels: Bool = true
    var showWeekdayLabels: Bool = false

    var todayHighlightColor: Color? = nil
    var todayHighlightWidth: CGFloat = 1.2

    var scrollEnabled: Bool = true
    var defaultScrollEdge: HorizontalEdge = .trailing

    var fitToWidthEnabled: Bool = false
    var minCellSize: CGFloat = 10

    var onCellTap: ((Date, Double) -> Void)? = nil

    var customAccessibilityLabel: ((Date, Double) -> String)? = nil

    var showsTooltipOnTap: Bool = false
    var tooltipFormatter: ((Date, Double) -> String)? = nil

    // MARK: - Local view state

    @State private var activeTooltipDate: Date? = nil

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init (generic)

    /// Create a heatmap from arbitrary `Identifiable` items.
    ///
    /// - Parameters:
    ///   - data: Source items. Multiple items on the same day are combined per `aggregation`.
    ///   - dateKey: KeyPath into `Item` that yields the day this item belongs to.
    ///   - valueKey: KeyPath into `Item` that yields the numeric value.
    ///   - aggregation: How to combine multiple items on the same day. Default `.sum`.
    ///   - dateRange: Range of dates to render. `nil` = last 365 days ending today.
    public init(
        data: [Item],
        dateKey: KeyPath<Item, Date>,
        valueKey: KeyPath<Item, Double>,
        aggregation: Aggregation = .sum,
        dateRange: ClosedRange<Date>? = nil
    ) {
        self.items = data
        self.dateKey = dateKey
        self.valueKey = valueKey
        self.aggregation = aggregation
        self.dateRange = dateRange
    }

    // MARK: - Computed

    /// The effective date range, defaulting to the last 365 days.
    var effectiveDateRange: ClosedRange<Date> {
        if let dateRange { return dateRange }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -364, to: today) ?? today
        return start...today
    }

    /// `[startOfDay : aggregatedValue]` after grouping items by day.
    var aggregatedValues: [Date: Double] {
        let cal = Calendar.current
        var buckets: [Date: [Double]] = [:]
        for item in items {
            let day = cal.startOfDay(for: item[keyPath: dateKey])
            buckets[day, default: []].append(item[keyPath: valueKey])
        }
        return buckets.mapValues { aggregation.reduce($0) }
    }

    /// Resolved palette colors. Custom levels (set via `.levels([Color])`)
    /// take precedence; otherwise the active palette is resolved against
    /// the surrounding `colorScheme` so the grid adapts to light/dark mode.
    var effectiveLevels: [Color] {
        customLevels ?? palette.colors(for: colorScheme)
    }

    // MARK: - Body

    @ViewBuilder
    public var body: some View {
        if fitToWidthEnabled {
            adaptiveBody
        } else {
            staticBody
        }
    }

    @ViewBuilder
    private var staticBody: some View {
        let range = effectiveDateRange
        let values = aggregatedValues
        let thresholds = computedThresholds()
        let levels = effectiveLevels
        let weeks = HeatmapGrid.build(
            range: range,
            firstWeekday: firstWeekday
        )

        let content = VStack(alignment: .leading, spacing: 6) {
            if showMonthLabels {
                monthLabelRow(weeks: weeks)
            }
            grid(weeks: weeks, values: values, thresholds: thresholds, levels: levels)
        }

        if scrollEnabled {
            ScrollView(.horizontal, showsIndicators: false) {
                content
            }
            .defaultScrollAnchor(scrollAnchor)
            .scrollTargetBehavior(.viewAligned)
        } else {
            content
        }
    }

    /// Width-aware layout via SwiftUI's `Layout` protocol. The layout sees
    /// the proposal width in `sizeThatFits`, picks `cellSize` from
    /// (preferred → fitted → min), and places each subview at its grid
    /// position in a single pass — no `@State`, no GeometryReader feedback
    /// loop, no auto-centering by SwiftUI's overflow rules.
    ///
    /// Subviews are ordered so `placeSubviews` can index them positionally:
    /// optional 7 weekday labels first, then cells in week-major / day-by-
    /// week order.
    ///
    /// **Trade-off vs the previous adaptive body**: there is no scroll
    /// fallback. If even `minCellSize` can't fit all weeks in the proposed
    /// width, cells stay at `minCellSize` and the heatmap returns a width
    /// larger than the proposal — the parent decides what to do (clip,
    /// allow overflow, or wrap in its own `ScrollView`). For full-year
    /// heatmaps on phone-sized containers, prefer the default
    /// scroll-wrapped path (don't enable `.fitToWidth`).
    private var adaptiveBody: some View {
        let weeks = HeatmapGrid.build(
            range: effectiveDateRange,
            firstWeekday: firstWeekday
        )
        let values = aggregatedValues
        let thresholds = computedThresholds()
        let levels = effectiveLevels
        let today = Calendar.current.startOfDay(for: Date())
        let range = effectiveDateRange

        return AdaptiveHeatmapLayout(
            weekCount: weeks.count,
            preferredCellSize: cellSize,
            minCellSize: minCellSize,
            cellSpacing: cellSpacing,
            showWeekdayLabels: showWeekdayLabels
        ) {
            if showWeekdayLabels {
                ForEach(orderedWeekdaySymbols, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            ForEach(weeks) { week in
                ForEach(week.days, id: \.self) { date in
                    flexCell(
                        date: date,
                        values: values,
                        thresholds: thresholds,
                        levels: levels,
                        today: today,
                        range: range
                    )
                }
            }
        }
    }

    /// `veryShortWeekdaySymbols` reordered to start at `firstWeekday`.
    /// Calendar always emits Sunday at index 0; the rotation here lines
    /// the labels up with the rows produced by `HeatmapGrid.build`.
    private var orderedWeekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { offset -> String in
            let idx = (firstWeekday.rawValue - 1 + offset) % 7
            return symbols[idx]
        }
    }

    /// Pure helper kept around for tests — returns the `cellSize` that the
    /// adaptive layout would pick for a given container width. The
    /// `AdaptiveHeatmapLayout` struct uses the same algorithm internally
    /// inside `sizeThatFits`. Returns `cap = max(preferredCellSize,
    /// minCellSize)` when the container is wide, scales down to fit all
    /// weeks in the mid range, and floors at `minCellSize` when the
    /// container is too narrow for everything to fit.
    func adaptiveCellSize(forContainerWidth proposedWidth: CGFloat) -> CGFloat {
        let weekCount = HeatmapGrid.build(
            range: effectiveDateRange,
            firstWeekday: firstWeekday
        ).count
        return AdaptiveHeatmapLayout.computeCellSize(
            proposedWidth: proposedWidth,
            weekCount: weekCount,
            preferredCellSize: cellSize,
            minCellSize: minCellSize,
            cellSpacing: cellSpacing,
            showWeekdayLabels: showWeekdayLabels
        )
    }

    private var scrollAnchor: UnitPoint {
        defaultScrollEdge == .leading ? .leading : .trailing
    }

    // MARK: - Subviews

    private func grid(
        weeks: [HeatmapGrid.Week],
        values: [Date: Double],
        thresholds: [Double],
        levels: [Color]
    ) -> some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let range = effectiveDateRange

        return HStack(alignment: .top, spacing: cellSpacing) {
            if showWeekdayLabels {
                weekdayLabelColumn
            }
            // Inner HStack so `.scrollTargetLayout()` only marks week
            // columns as snap targets — keeping the weekday-label column
            // (when shown) outside the scroll-snap math.
            HStack(alignment: .top, spacing: cellSpacing) {
                ForEach(weeks) { week in
                    VStack(spacing: cellSpacing) {
                        ForEach(week.days, id: \.self) { date in
                            cell(
                                date: date,
                                values: values,
                                thresholds: thresholds,
                                levels: levels,
                                today: today,
                                range: range
                            )
                        }
                    }
                }
            }
            .scrollTargetLayout()
        }
    }

    @ViewBuilder
    /// Static-body cell — fixed-size via `.frame(width: cellSize, …)`.
    /// Used inside `HStack`/`VStack` arrangements that respect natural
    /// child sizes.
    private func cell(
        date: Date,
        values: [Date: Double],
        thresholds: [Double],
        levels: [Color],
        today: Date,
        range: ClosedRange<Date>
    ) -> some View {
        cellContent(date: date, values: values, thresholds: thresholds,
                    levels: levels, today: today, range: range)
            .frame(width: cellSize, height: cellSize)
    }

    /// Adaptive-body cell — flexible-size, sized by `Layout.placeSubviews`'s
    /// proposal. Identical interactive surface to `cell(...)` minus the
    /// explicit frame.
    private func flexCell(
        date: Date,
        values: [Date: Double],
        thresholds: [Double],
        levels: [Color],
        today: Date,
        range: ClosedRange<Date>
    ) -> some View {
        cellContent(date: date, values: values, thresholds: thresholds,
                    levels: levels, today: today, range: range)
    }

    /// Shared cell visuals + interaction. Sized by the wrapping
    /// `cell`/`flexCell`; `Rectangle` honors whatever size the parent
    /// layout proposes.
    @ViewBuilder
    private func cellContent(
        date: Date,
        values: [Date: Double],
        thresholds: [Double],
        levels: [Color],
        today: Date,
        range: ClosedRange<Date>
    ) -> some View {
        let inRange = range.contains(date)
        let value = values[date] ?? 0
        let isToday = Calendar.current.isDate(date, inSameDayAs: today)

        Rectangle()
            .fill(inRange ? colorFor(value: value, thresholds: thresholds, levels: levels) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous))
            .overlay {
                if isToday, let highlight = todayHighlightColor, inRange {
                    RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                        .stroke(highlight, lineWidth: todayHighlightWidth)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if inRange {
                    if showsTooltipOnTap {
                        activeTooltipDate = (activeTooltipDate == date) ? nil : date
                    }
                    onCellTap?(date, value)
                }
            }
            .accessibilityLabel(Text(inRange ? accessibilityLabelFor(date: date, value: value) : ""))
            .accessibilityHidden(!inRange)
            .accessibilityAddTraits(inRange && (onCellTap != nil || showsTooltipOnTap) ? .isButton : [])
            .popover(
                isPresented: Binding(
                    get: { showsTooltipOnTap && activeTooltipDate == date },
                    set: { presented in
                        if !presented { activeTooltipDate = nil }
                    }
                ),
                arrowEdge: .top
            ) {
                Text(tooltipText(date: date, value: value))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .presentationCompactAdaptation(.popover)
            }
    }

    private func monthLabelRow(weeks: [HeatmapGrid.Week]) -> some View {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = cal.locale ?? Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM")

        return HStack(spacing: cellSpacing) {
            if showWeekdayLabels {
                Color.clear.frame(width: cellSize)
            }
            ForEach(weeks) { week in
                if let label = week.monthLabel(formatter: formatter, calendar: cal) {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize()
                        .frame(width: cellSize, height: 12, alignment: .leading)
                } else {
                    Color.clear.frame(width: cellSize, height: 12)
                }
            }
        }
    }

    private var weekdayLabelColumn: some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        // Calendar.veryShortWeekdaySymbols starts at Sunday (index 0).
        // Reorder by `firstWeekday`.
        let ordered = (0..<7).map { offset -> String in
            let idx = (firstWeekday.rawValue - 1 + offset) % 7
            return symbols[idx]
        }

        return VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { i in
                Text(ordered[i])
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }

    // MARK: - Helpers

    /// Build the VoiceOver label for an in-range cell.
    /// Honors `customAccessibilityLabel` when provided; otherwise emits a
    /// localized "{long date}, {value}" string using the user's current locale.
    func accessibilityLabelFor(date: Date, value: Double) -> String {
        if let custom = customAccessibilityLabel {
            return custom(date, value)
        }
        let dateString = date.formatted(date: .long, time: .omitted)
        let valueString = value.formatted()
        return "\(dateString), \(valueString)"
    }

    /// Build the tooltip body for a cell. Honors `tooltipFormatter` when
    /// provided; otherwise emits a two-line "{long date}\n{value}" string.
    func tooltipText(date: Date, value: Double) -> String {
        if let formatter = tooltipFormatter {
            return formatter(date, value)
        }
        let dateString = date.formatted(date: .long, time: .omitted)
        let valueString = value.formatted()
        return "\(dateString)\n\(valueString)"
    }

    /// Map a value to a color level using thresholds.
    /// thresholds.count == levels.count - 1. value < thresholds[0] => levels[0].
    private func colorFor(value: Double, thresholds: [Double], levels: [Color]) -> Color {
        guard !levels.isEmpty else { return .clear }
        if levels.count == 1 { return levels[0] }
        for (i, t) in thresholds.enumerated() {
            if value < t { return levels[i] }
        }
        return levels.last!
    }

    /// Computes thresholds from data when `customThresholds == nil`.
    private func computedThresholds() -> [Double] {
        if let customThresholds { return customThresholds }
        let levelCount = effectiveLevels.count
        guard levelCount > 1 else { return [] }

        let dataMax = aggregatedValues.values.max() ?? 0

        // Need (levelCount - 1) thresholds. Indexing convention:
        //   value < thresholds[0]              -> level 0 (empty)
        //   thresholds[i-1] <= value < t[i]    -> level i
        //   value >= thresholds.last           -> level (levelCount-1)
        //
        // We treat `0 < value < firstThreshold` as level 1 (any positive activity is "some").
        // So thresholds[0] = small positive epsilon (effectively "any > 0"),
        // remaining (levelCount - 2) thresholds split (epsilon, dataMax] evenly.

        if dataMax <= 0 {
            // No data — produce thresholds that put everything at level 0.
            return Array(repeating: Double.greatestFiniteMagnitude, count: levelCount - 1)
        }

        let epsilon = 0.0001
        var thresholds: [Double] = [epsilon]
        let remainingBuckets = levelCount - 2
        if remainingBuckets > 0 {
            let step = dataMax / Double(remainingBuckets + 1)
            for i in 1...remainingBuckets {
                thresholds.append(step * Double(i))
            }
        }
        return thresholds
    }
}

// MARK: - Adaptive layout

/// SwiftUI `Layout` that drives `CalendarHeatmap.adaptiveBody`. The layout
/// receives the parent's proposed width in `sizeThatFits`, picks a
/// `cellSize` from (preferred → fitted-to-fill → minimum) in one pass,
/// and places each subview at its grid coordinate. No `@State`, no
/// PreferenceKey — `Layout` was designed for this.
///
/// Subviews are passed in this order (caller's responsibility):
///   1. Optional 7 weekday-label `Text` views (only when `showWeekdayLabels`)
///   2. Cells in week-major / day-by-week order (`week 0 day 0…6`,
///      `week 1 day 0…6`, …)
///
/// The layout proposes `(cellSize, cellSize)` to every subview; the
/// flexible `Rectangle`/`Text` content scales to that proposal.
///
/// Lives at file scope because nested types inside the generic
/// `CalendarHeatmap<Item>` can't carry the static storage that some Swift
/// constructs require — keeping this out simplifies cross-version safety.
struct AdaptiveHeatmapLayout: Layout {
    let weekCount: Int
    let preferredCellSize: CGFloat
    let minCellSize: CGFloat
    let cellSpacing: CGFloat
    let showWeekdayLabels: Bool

    static let rows = 7

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
        let resolved = Self.computeCellSize(
            proposedWidth: proposedWidth,
            weekCount: weekCount,
            preferredCellSize: preferredCellSize,
            minCellSize: minCellSize,
            cellSpacing: cellSpacing,
            showWeekdayLabels: showWeekdayLabels
        )
        cache.cellSize = resolved

        let labelsWidth: CGFloat = showWeekdayLabels ? resolved + cellSpacing : 0
        let cellsWidth =
            CGFloat(weekCount) * resolved + CGFloat(max(weekCount - 1, 0)) * cellSpacing
        let totalWidth = labelsWidth + cellsWidth
        let totalHeight =
            CGFloat(Self.rows) * resolved + CGFloat(Self.rows - 1) * cellSpacing
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let resolved = cache.cellSize > 0
            ? cache.cellSize
            : Self.computeCellSize(
                proposedWidth: proposal.width ?? bounds.width,
                weekCount: weekCount,
                preferredCellSize: preferredCellSize,
                minCellSize: minCellSize,
                cellSpacing: cellSpacing,
                showWeekdayLabels: showWeekdayLabels
            )
        let cellProposal = ProposedViewSize(width: resolved, height: resolved)
        let cellOriginX = bounds.minX + (showWeekdayLabels ? resolved + cellSpacing : 0)

        var index = 0

        if showWeekdayLabels {
            for row in 0..<Self.rows {
                guard index < subviews.count else { return }
                let y = bounds.minY + CGFloat(row) * (resolved + cellSpacing)
                subviews[index].place(
                    at: CGPoint(x: bounds.minX, y: y),
                    anchor: .topLeading,
                    proposal: cellProposal
                )
                index += 1
            }
        }

        for week in 0..<weekCount {
            let x = cellOriginX + CGFloat(week) * (resolved + cellSpacing)
            for row in 0..<Self.rows {
                guard index < subviews.count else { return }
                let y = bounds.minY + CGFloat(row) * (resolved + cellSpacing)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: cellProposal
                )
                index += 1
            }
        }
    }

    /// Pure cell-size selector. Exposed `static` so
    /// `CalendarHeatmap.adaptiveCellSize(forContainerWidth:)` and tests
    /// can call it without instantiating the layout.
    static func computeCellSize(
        proposedWidth: CGFloat,
        weekCount: Int,
        preferredCellSize: CGFloat,
        minCellSize: CGFloat,
        cellSpacing: CGFloat,
        showWeekdayLabels: Bool
    ) -> CGFloat {
        guard proposedWidth.isFinite, proposedWidth > 0, weekCount > 0 else {
            return preferredCellSize
        }
        // Estimate label width using preferred cellSize (we don't know the
        // resolved size yet — it's what we're computing). Tiny over- or
        // under-estimate; in practice the label glyph at font 9 fits well
        // inside any sensible cellSize.
        let labelsWidth: CGFloat =
            showWeekdayLabels ? preferredCellSize + cellSpacing : 0
        let availableForGrid = proposedWidth - labelsWidth
        guard availableForGrid > 0 else { return minCellSize }

        let totalSpacing = CGFloat(max(weekCount - 1, 0)) * cellSpacing
        let cellsAvailable = availableForGrid - totalSpacing
        guard cellsAvailable > 0 else { return minCellSize }

        let allFitSize = cellsAvailable / CGFloat(weekCount)
        let cap = max(preferredCellSize, minCellSize)

        if allFitSize >= cap { return cap }
        if allFitSize >= minCellSize { return allFitSize }
        return minCellSize
    }
}

// MARK: - HeatmapGrid (internal layout helper)

enum HeatmapGrid {
    struct Week: Identifiable, Hashable {
        let id: Int
        let days: [Date] // 7 dates aligned to firstWeekday
    }

    /// Builds the columns of the grid for the given range.
    /// Each column is 7 dates from `firstWeekday`, padded with days outside `range`
    /// so each column is always 7 cells.
    static func build(range: ClosedRange<Date>, firstWeekday: Weekday) -> [Week] {
        let cal = Calendar.current

        // Anchor: align lower bound back to its `firstWeekday`.
        let lowerWeekday = cal.component(.weekday, from: range.lowerBound)
        let leadingPadding = firstWeekday.offset(for: lowerWeekday)
        guard let gridStart = cal.date(byAdding: .day, value: -leadingPadding, to: range.lowerBound)
        else { return [] }

        // Total days from gridStart to upperBound (inclusive)
        let totalDays = (cal.dateComponents([.day], from: gridStart, to: range.upperBound).day ?? 0) + 1
        let weekCount = Int(ceil(Double(totalDays) / 7.0))

        var weeks: [Week] = []
        for w in 0..<weekCount {
            var days: [Date] = []
            for d in 0..<7 {
                let offset = w * 7 + d
                if let date = cal.date(byAdding: .day, value: offset, to: gridStart) {
                    days.append(date)
                }
            }
            weeks.append(Week(id: w, days: days))
        }
        return weeks
    }
}

extension HeatmapGrid.Week {
    /// Returns the month label if this week's first date is the first occurrence of its month
    /// across the grid. Lib uses this to label only the boundary week.
    /// (Lightweight strategy — lib provides only the label for the leftmost-day-of-month week.)
    func monthLabel(formatter: DateFormatter, calendar: Calendar) -> String? {
        guard let first = days.first else { return nil }
        let day = calendar.component(.day, from: first)
        // Only label when the first day of the week falls in the first 7 days of a month
        // AND it's the earliest such week we see — caller-side dedup is unnecessary because
        // a month's "first week" is unique.
        guard day <= 7 else { return nil }
        return formatter.string(from: first)
    }
}
