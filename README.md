# HeatmapKit

> A modern SwiftUI calendar heatmap and contribution graph component — visualize time-series data the way GitHub shows your contributions.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20watchOS%2010%20%7C%20tvOS%2017%20%7C%20visionOS%201-blue.svg)](https://github.com/jacklv-coder/HeatmapKit)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

## Why HeatmapKit?

Most existing heatmap libraries for Apple platforms target UIKit and have not been updated for years. HeatmapKit is built **SwiftUI-first**, supports the full Apple platform family (iOS / macOS / watchOS / tvOS / visionOS), and ships modern interactions like horizontal scrolling, automatic locale-aware month labels, and tap callbacks.

## Features

- 🍎 **Pure SwiftUI** — declarative API, no UIKit bridging
- 📅 **Calendar heatmap** — GitHub-style 7×N grid, perfect for contributions / habits / activity
- ↔️ **Horizontal scrolling** — long ranges scroll naturally; default-anchors to the most recent week
- 🎨 **6 built-in palettes** plus full custom-color support
- ⚖️ **Auto or custom thresholds** — let HeatmapKit bucket values from `data.max()`, or supply your own cutoffs
- 🌍 **Localized labels** — month/weekday labels follow `Calendar.current.locale`
- 👆 **Tap-to-detail** — opt-in callback per cell, plus a built-in popover tooltip
- ♿ **VoiceOver-ready** — every cell ships an accessibility label, customizable per app
- 🪶 **Zero dependencies** — Apple frameworks only

## Requirements

| Platform | Minimum |
|----------|---------|
| iOS      | 17.0    |
| macOS    | 14.0    |
| watchOS  | 10.0    |
| tvOS     | 17.0    |
| visionOS | 1.0     |
| Swift    | 5.9     |
| Xcode    | 15      |

## Installation

### Swift Package Manager

Add the dependency in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jacklv-coder/HeatmapKit", from: "0.1.0")
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the URL.

## Quick Start

```swift
import SwiftUI
import HeatmapKit

struct ContentView: View {
    var body: some View {
        // Defaults to the last 365 days ending today.
        CalendarHeatmap(contributions: sampleData)
    }

    private var sampleData: [Date: Double] {
        // Map each day to a value (e.g. minutes focused, commits made, etc.)
        let today = Calendar.current.startOfDay(for: Date())
        return [today: 35.0]
    }
}
```

### Custom date range

```swift
let cal = Calendar.current
let today = cal.startOfDay(for: Date())
let start = cal.date(byAdding: .day, value: -90, to: today)!

CalendarHeatmap(contributions: data, dateRange: start...today)
```

### Working with your own model

If your data isn't already a `[Date: Double]` map, point HeatmapKit at any value type using key paths:

```swift
struct Session {
    var date: Date
    var minutes: Double
}

let sessions: [Session] = ...

CalendarHeatmap(
    data: sessions,
    dateKey: \.date,
    valueKey: \.minutes,
    aggregation: .sum  // .sum / .count / .max / .min / .average
)
```

Multiple items on the same day are combined per `aggregation`.

## Customization

```swift
CalendarHeatmap(contributions: data)
    .cellSize(14)
    .cellSpacing(3)
    .cellCornerRadius(3)
    .levels(.orange)               // .green / .orange / .blue / .purple / .red / .grayscale
    .thresholds([1, 5, 10, 20])    // explicit cutoffs (count = levels.count - 1)
    .firstWeekday(.monday)
    .showMonthLabels(true)
    .showWeekdayLabels(false)
    .todayHighlightColor(.primary) // pass nil to disable today's outline
    .scrollEnabled(true)
    .defaultScrollEdge(.trailing)  // anchor to most recent on first appearance
    .onCellTap { date, value in
        print("\(date): \(value)")
    }
    .tooltipOnTap { date, value in
        // Built-in popover. Tap the same cell again — or outside — to dismiss.
        // Default emits "{long date}\n{value}"; this example overrides it.
        let day = date.formatted(date: .abbreviated, time: .omitted)
        return "\(day) — \(Int(value)) min"
    }
    .accessibilityCellLabel { date, value in
        // VoiceOver announces this for each in-range cell.
        // Default emits "{long date}, {value}" — override to inject units / wording.
        let day = date.formatted(date: .abbreviated, time: .omitted)
        return value == 0 ? "\(day), no activity"
                          : "\(day), \(Int(value)) minutes focused"
    }
```

### Bring your own palette

```swift
CalendarHeatmap(contributions: data)
    .levels([
        Color.gray.opacity(0.15),  // empty / no-data
        Color.pink.opacity(0.4),
        Color.pink.opacity(0.7),
        Color.pink,
    ])
```

The first color is the empty / no-data shade; the rest are progressively more intense. The number of colors you pass determines the level count. Without `.thresholds(_:)`, HeatmapKit splits `data.max()` evenly across the remaining buckets.

## Roadmap

- [x] v0.1 — `CalendarHeatmap` core: grid, horizontal scroll, 6 palettes, custom thresholds, tap callback, today highlight, locale-aware month/weekday labels
- [x] v0.2 — VoiceOver labels per cell, customizable via `.accessibilityCellLabel`
- [x] v0.3 — Built-in detail tooltip on tap, customizable via `.tooltipOnTap`
- [ ] v0.4 — Shareable image renderer (system share sheet)
- [ ] v0.5 — Additional layouts: weekly heatmap, hour×weekday matrix
- [ ] Localization audit (RTL, non-Gregorian calendars)

## Contributing

Issues and pull requests are welcome. The project is in its early days, so feedback on API shape is especially valuable.

## License

[MIT](LICENSE) © 2026 jacklv-coder
