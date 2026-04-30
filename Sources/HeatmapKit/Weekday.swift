//
//  Weekday.swift
//  HeatmapKit
//

import Foundation

/// Day of the week used as the start of a column in `CalendarHeatmap`.
///
/// Raw values match `Calendar.firstWeekday` (1 = Sunday … 7 = Saturday),
/// allowing direct interop with `Calendar`.
public enum Weekday: Int, Sendable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    /// 0-based offset from this weekday for an arbitrary `Calendar.weekday` value.
    /// E.g., if `self == .monday`, then `Calendar.weekday == 2` returns 0.
    func offset(for calendarWeekday: Int) -> Int {
        ((calendarWeekday - rawValue) % 7 + 7) % 7
    }
}
