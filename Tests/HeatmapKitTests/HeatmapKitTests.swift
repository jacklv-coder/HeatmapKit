import Testing
import Foundation
@testable import HeatmapKit

// MARK: - Aggregation

@Test
func aggregationSum() {
    #expect(Aggregation.sum.reduce([1, 2, 3]) == 6)
    #expect(Aggregation.sum.reduce([]) == 0)
}

@Test
func aggregationCount() {
    #expect(Aggregation.count.reduce([10, 20]) == 2)
    #expect(Aggregation.count.reduce([]) == 0)
}

@Test
func aggregationMaxMin() {
    #expect(Aggregation.max.reduce([3, 1, 7, 4]) == 7)
    #expect(Aggregation.min.reduce([3, 1, 7, 4]) == 1)
}

@Test
func aggregationAverage() {
    #expect(Aggregation.average.reduce([2, 4, 6]) == 4)
}

// MARK: - Weekday offset

@Test
func weekdayOffsetMondayStart() {
    // firstWeekday = .monday (rawValue 2)
    // Calendar Monday  -> offset 0
    // Calendar Tuesday -> offset 1
    // Calendar Sunday  -> offset 6
    #expect(Weekday.monday.offset(for: 2) == 0)
    #expect(Weekday.monday.offset(for: 3) == 1)
    #expect(Weekday.monday.offset(for: 1) == 6)
}

@Test
func weekdayOffsetSundayStart() {
    // firstWeekday = .sunday (rawValue 1)
    // Calendar Sunday   -> 0
    // Calendar Saturday -> 6
    #expect(Weekday.sunday.offset(for: 1) == 0)
    #expect(Weekday.sunday.offset(for: 7) == 6)
}

// MARK: - HeatmapGrid

@Test
func gridBuildSpansFullRange() {
    // Build a 14-day range (2 weeks) starting on a Monday and confirm the grid
    // contains those days.
    let cal = Calendar(identifier: .gregorian)
    var comps = DateComponents(year: 2026, month: 1, day: 5) // 2026-01-05 is a Monday
    let start = cal.date(from: comps)!
    comps.day = 18 // 2026-01-18, two weeks later
    let end = cal.date(from: comps)!

    let weeks = HeatmapGrid.build(range: start...end, firstWeekday: .monday)
    // 14 days starting on a Monday → exactly 2 weeks
    #expect(weeks.count == 2)
    #expect(weeks[0].days.count == 7)
    #expect(weeks[1].days.count == 7)
    #expect(weeks[0].days.first == start)
}

@Test
func gridPadsLeadingDays() {
    // Range starting mid-week should be padded on the left so each column is 7 days.
    let cal = Calendar(identifier: .gregorian)
    let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 7))! // Wed
    let end = cal.date(from: DateComponents(year: 2026, month: 1, day: 13))!  // Tue

    let weeks = HeatmapGrid.build(range: start...end, firstWeekday: .monday)
    // The first column should start on Mon Jan 5 (2 days before Wed Jan 7)
    let firstDay = weeks.first?.days.first
    let expected = cal.date(from: DateComponents(year: 2026, month: 1, day: 5))
    #expect(firstDay == expected)
}

// MARK: - Effective date range

@Test
@MainActor
func defaultDateRangeIs365Days() {
    let heatmap = CalendarHeatmap(contributions: [:])
    let range = heatmap.effectiveDateRange
    let cal = Calendar.current
    let days = cal.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day
    #expect(days == 364) // inclusive range: 365 distinct days
}

// MARK: - Accessibility labels

@Test
@MainActor
func accessibilityLabelDefaultIncludesDateAndValue() {
    let cal = Calendar(identifier: .gregorian)
    let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
    let heatmap = CalendarHeatmap(contributions: [:])

    let label = heatmap.accessibilityLabelFor(date: date, value: 35)
    // Date format depends on locale, so just assert the value and year are present.
    #expect(label.contains("35"))
    #expect(label.contains("2026"))
}

@Test
@MainActor
func accessibilityLabelHonorsCustomProvider() {
    let cal = Calendar(identifier: .gregorian)
    let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
    let heatmap = CalendarHeatmap(contributions: [:])
        .accessibilityCellLabel { _, value in "value=\(value)" }

    #expect(heatmap.accessibilityLabelFor(date: date, value: 7.5) == "value=7.5")
}

// MARK: - Tooltip text

@Test
@MainActor
func tooltipTextDefaultIsTwoLinesWithDateAndValue() {
    let cal = Calendar(identifier: .gregorian)
    let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
    let heatmap = CalendarHeatmap(contributions: [:])

    let text = heatmap.tooltipText(date: date, value: 35)
    let lines = text.split(separator: "\n")
    #expect(lines.count == 2)
    #expect(text.contains("35"))
    #expect(text.contains("2026"))
}

@Test
@MainActor
func tooltipTextHonorsCustomFormatter() {
    let cal = Calendar(identifier: .gregorian)
    let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
    let heatmap = CalendarHeatmap(contributions: [:])
        .tooltipOnTap { _, value in "v=\(value)" }

    #expect(heatmap.tooltipText(date: date, value: 7.5) == "v=7.5")
}

@Test
@MainActor
func tooltipOnTapEnablesTooltipFlag() {
    let plain = CalendarHeatmap(contributions: [:])
    #expect(plain.showsTooltipOnTap == false)

    let withTooltip = plain.tooltipOnTap()
    #expect(withTooltip.showsTooltipOnTap == true)
    #expect(withTooltip.tooltipFormatter == nil)
}

// MARK: - Aggregation through CalendarHeatmap

@Test
@MainActor
func aggregatedValuesSumsByDay() {
    let cal = Calendar.current
    let day = cal.startOfDay(for: Date())

    let items: [HeatmapDay] = [
        HeatmapDay(date: day, value: 1.0),
        HeatmapDay(date: day, value: 2.5),
    ]

    let heatmap = CalendarHeatmap(
        data: items,
        dateKey: \HeatmapDay.date,
        valueKey: \HeatmapDay.value,
        aggregation: .sum
    )

    #expect(heatmap.aggregatedValues[day] == 3.5)
}
