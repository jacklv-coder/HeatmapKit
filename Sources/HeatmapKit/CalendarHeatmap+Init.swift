//
//  CalendarHeatmap+Init.swift
//  HeatmapKit
//
//  Convenience initializers when data is already pre-aggregated by day.
//

import Foundation

public extension CalendarHeatmap where Item == HeatmapDay {

    /// Convenience initializer for data that is already aggregated by day.
    ///
    /// ```swift
    /// CalendarHeatmap(contributions: [today: 5.0, yesterday: 3.0])
    /// ```
    ///
    /// - Parameters:
    ///   - contributions: A dictionary mapping a `Date` (any time-of-day; will be
    ///     normalized via `Calendar.startOfDay`) to its aggregated value.
    ///   - dateRange: Range of dates to render. `nil` = last 365 days ending today.
    init(
        contributions: [Date: Double],
        dateRange: ClosedRange<Date>? = nil
    ) {
        let items = contributions.map { HeatmapDay(date: $0.key, value: $0.value) }
        self.init(
            data: items,
            dateKey: \HeatmapDay.date,
            valueKey: \HeatmapDay.value,
            aggregation: .sum,
            dateRange: dateRange
        )
    }
}
