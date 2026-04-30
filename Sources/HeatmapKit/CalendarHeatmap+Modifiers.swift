//
//  CalendarHeatmap+Modifiers.swift
//  HeatmapKit
//

import SwiftUI

public extension CalendarHeatmap {

    // MARK: - Cell appearance

    /// Sets the side length of each day cell in points. Default: 14.
    func cellSize(_ size: CGFloat) -> CalendarHeatmap {
        var copy = self
        copy.cellSize = size
        return copy
    }

    /// Sets the gap (in points) between adjacent cells. Default: 3.
    func cellSpacing(_ spacing: CGFloat) -> CalendarHeatmap {
        var copy = self
        copy.cellSpacing = spacing
        return copy
    }

    /// Sets the corner radius of each cell. Default: 3.
    func cellCornerRadius(_ radius: CGFloat) -> CalendarHeatmap {
        var copy = self
        copy.cellCornerRadius = radius
        return copy
    }

    // MARK: - Colors

    /// Use one of the built-in palettes.
    func levels(_ palette: ColorPalette) -> CalendarHeatmap {
        var copy = self
        copy.palette = palette
        copy.customLevels = nil
        return copy
    }

    /// Use a custom array of colors. The array's count determines the number
    /// of intensity levels. The first color is used for empty / no-data cells.
    func levels(_ colors: [Color]) -> CalendarHeatmap {
        var copy = self
        copy.customLevels = colors
        return copy
    }

    /// Provide explicit value thresholds for the level cutoffs.
    /// Length must equal `levels.count - 1` (e.g., 4 thresholds for 5 levels).
    /// Pass `nil` to revert to auto-derived thresholds based on `data.max()`.
    func thresholds(_ values: [Double]?) -> CalendarHeatmap {
        var copy = self
        copy.customThresholds = values
        return copy
    }

    // MARK: - Calendar

    /// First day of the week. Default: `.monday`.
    func firstWeekday(_ weekday: Weekday) -> CalendarHeatmap {
        var copy = self
        copy.firstWeekday = weekday
        return copy
    }

    /// Whether to show the month labels above the grid. Default: `true`.
    func showMonthLabels(_ show: Bool) -> CalendarHeatmap {
        var copy = self
        copy.showMonthLabels = show
        return copy
    }

    /// Whether to show the weekday labels on the left. Default: `false`.
    func showWeekdayLabels(_ show: Bool) -> CalendarHeatmap {
        var copy = self
        copy.showWeekdayLabels = show
        return copy
    }

    // MARK: - Today highlight

    /// Color used to outline today's cell. Pass `nil` (the default) to
    /// leave today unhighlighted, matching GitHub's contribution graph.
    /// Pass `.primary` (or any other color) to opt in.
    func todayHighlightColor(_ color: Color?) -> CalendarHeatmap {
        var copy = self
        copy.todayHighlightColor = color
        return copy
    }

    /// Stroke width of the today indicator. Default: 1.2.
    func todayHighlightWidth(_ width: CGFloat) -> CalendarHeatmap {
        var copy = self
        copy.todayHighlightWidth = width
        return copy
    }

    // MARK: - Scrolling

    /// Whether the grid is wrapped in a horizontal `ScrollView`. Default: `true`.
    /// When disabled the grid is laid out fixed; you'll typically need to size it yourself.
    func scrollEnabled(_ enabled: Bool) -> CalendarHeatmap {
        var copy = self
        copy.scrollEnabled = enabled
        return copy
    }

    /// Which edge to anchor to on first appearance. Default: `.trailing` (most recent).
    func defaultScrollEdge(_ edge: HorizontalEdge) -> CalendarHeatmap {
        var copy = self
        copy.defaultScrollEdge = edge
        return copy
    }

    /// Adapt cell size to the container width: cells grow up to the value
    /// passed via `.cellSize(_:)` (the upper bound), shrink down to
    /// `minCellSize` (the lower bound), and only fall back to a horizontal
    /// scroll when even `minCellSize` doesn't fit.
    ///
    /// Effect at common widths (with `.cellSize(14)`, default spacing 3,
    /// 53-week range, `minCellSize: 10`):
    /// - **Wide** (≥ ~900pt, e.g. iPad / Mac window): cells at 14pt, no
    ///   scroll, full year visible
    /// - **Mid** (~500–900pt): cells shrink between 10 and 14pt, no scroll
    /// - **Narrow** (< ~500pt, e.g. iPhone): cells stay at 10pt, horizontal
    ///   scroll for older history
    ///
    /// When this modifier is set, the scroll fallback always activates if
    /// `minCellSize` doesn't fit, regardless of `.scrollEnabled(_:)`.
    func fitToWidth(minCellSize: CGFloat = 10) -> CalendarHeatmap {
        var copy = self
        copy.fitToWidthEnabled = true
        copy.minCellSize = minCellSize
        return copy
    }

    // MARK: - Interaction

    /// Callback fired when the user taps an in-range cell.
    /// Receives the `Date` (start of day) and the aggregated `Double` value (0 if no data).
    func onCellTap(_ action: @escaping (Date, Double) -> Void) -> CalendarHeatmap {
        var copy = self
        copy.onCellTap = action
        return copy
    }

    // MARK: - Accessibility

    /// Provide a custom VoiceOver label for each in-range cell.
    ///
    /// Receives the cell's `Date` (start of day) and the aggregated `Double` value
    /// (0 when the day has no data). If unset, HeatmapKit emits a localized
    /// `"{long date}, {value}"` string using `Calendar.current.locale`.
    ///
    /// Use this to inject domain context (units, "no data" wording, etc.):
    ///
    /// ```swift
    /// CalendarHeatmap(contributions: data)
    ///     .accessibilityCellLabel { date, value in
    ///         let day = date.formatted(date: .abbreviated, time: .omitted)
    ///         return value == 0 ? "\(day), no activity"
    ///                           : "\(day), \(Int(value)) minutes focused"
    ///     }
    /// ```
    func accessibilityCellLabel(_ provider: @escaping (Date, Double) -> String) -> CalendarHeatmap {
        var copy = self
        copy.customAccessibilityLabel = provider
        return copy
    }

    // MARK: - Tooltip

    /// Show a built-in popover with date + value when a cell is tapped.
    ///
    /// Tap the same cell again — or tap outside — to dismiss. Pass a
    /// `formatter` closure to customize the rendered string; the default
    /// is a two-line `"{long date}\n{value}"` using the current locale.
    /// `onCellTap` (if set) still fires alongside the tooltip.
    ///
    /// On compact size classes, the popover adapts to a small bubble via
    /// `presentationCompactAdaptation(.popover)`.
    ///
    /// ```swift
    /// CalendarHeatmap(contributions: data)
    ///     .tooltipOnTap { date, value in
    ///         let day = date.formatted(date: .abbreviated, time: .omitted)
    ///         return "\(day) — \(Int(value)) min"
    ///     }
    /// ```
    func tooltipOnTap(_ formatter: ((Date, Double) -> String)? = nil) -> CalendarHeatmap {
        var copy = self
        copy.showsTooltipOnTap = true
        copy.tooltipFormatter = formatter
        return copy
    }
}
