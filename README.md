# HeatmapKit

> A modern SwiftUI calendar heatmap and contribution graph component — visualize time-series data the way GitHub shows your contributions.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20watchOS%2010%20%7C%20tvOS%2017%20%7C%20visionOS%201-blue.svg)](https://github.com/jacklv-coder/HeatmapKit)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

> ⚠️ **Status: Work in Progress**
> The first public release (v0.1) is under active development. APIs may change.

## Why HeatmapKit?

Most existing heatmap libraries for Apple platforms target UIKit and have not been updated for years. HeatmapKit is built **SwiftUI-first**, supports the full Apple platform family (iOS / macOS / watchOS / tvOS / visionOS), and ships modern interactions like horizontal scrolling, automatic locale-aware month labels, and tap callbacks.

## Features

- 🍎 **Pure SwiftUI** — declarative API, no UIKit bridging
- 📅 **Calendar heatmap** — GitHub-style 7×N grid, perfect for contributions / habits / activity
- ↔️ **Horizontal scrolling** — long ranges scroll naturally; default-anchors to the most recent week
- 🎨 **Fully customizable** — cell size, spacing, color levels, thresholds
- 🌍 **Localized labels** — month/weekday labels follow `Calendar.current.locale`
- 👆 **Tap-to-detail** — opt-in callbacks per cell
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
        CalendarHeatmap(
            contributions: sampleData,
            dateRange: oneYearAgo...today
        )
    }

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var oneYearAgo: Date {
        Calendar.current.date(byAdding: .day, value: -364, to: today)!
    }

    private var sampleData: [Date: Double] {
        // Map each day to a value (e.g. minutes focused, commits made, etc.)
        [today: 35.0]
    }
}
```

## Customization (planned)

```swift
CalendarHeatmap(contributions: data, dateRange: range)
    .cellSize(14)
    .cellSpacing(3)
    .levels(.orange)             // built-in palettes: .green / .orange / .blue
    .thresholds([1, 5, 10, 20])  // value bucketing per level
    .showMonthLabels(true)
    .onCellTap { date, value in
        print("\(date): \(value)")
    }
```

> APIs above are illustrative — final shape may change before v0.1.

## Roadmap

- [ ] v0.1 — `CalendarHeatmap` core (grid, scroll, default palettes)
- [ ] v0.2 — Built-in detail tooltip on tap, accessibility labels
- [ ] v0.3 — Shareable image renderer (system share sheet)
- [ ] v0.4 — Additional layouts: weekly heatmap, hour×weekday matrix
- [ ] Localization audit (RTL, non-Gregorian calendars)

## Contributing

Issues and pull requests are welcome. The project is in its early days, so feedback on API shape is especially valuable.

## License

[MIT](LICENSE) © 2026 jacklv-coder
