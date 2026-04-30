//
//  Aggregation.swift
//  HeatmapKit
//

import Foundation

/// Strategy for aggregating multiple data points that fall on the same day.
///
/// Mirrors the `groupY` option from cal-heatmap.
public enum Aggregation: Sendable {
    /// Add all values together. Default for `CalendarHeatmap`.
    case sum
    /// Count the number of items, ignoring values.
    case count
    /// Take the maximum value.
    case max
    /// Take the minimum value.
    case min
    /// Take the arithmetic mean.
    case average

    /// Reduce a list of values into a single value according to the strategy.
    /// Returns 0 for an empty list.
    public func reduce(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        switch self {
        case .sum:
            return values.reduce(0, +)
        case .count:
            return Double(values.count)
        case .max:
            return values.max() ?? 0
        case .min:
            return values.min() ?? 0
        case .average:
            return values.reduce(0, +) / Double(values.count)
        }
    }
}
