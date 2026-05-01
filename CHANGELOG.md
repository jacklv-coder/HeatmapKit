# Changelog

All notable changes to HeatmapKit are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] — 2026-05-01

### Added
- `.fitToWidth(minCellSize:)` — width-aware adaptive layout. Cells size to the container between `minCellSize` and `cellSize`; scroll fallback engages only when even the floor doesn't fit. Narrow renders snap to whole-week boundaries via `.scrollTargetBehavior(.viewAligned)` ([#8](https://github.com/jacklv-coder/HeatmapKit/pull/8)).
- Runnable iOS demo app under `Demo/HeatmapKitDemo` — palette switching, tooltips, accessibility labels, share button via `snapshot(scale:background:)` ([#5](https://github.com/jacklv-coder/HeatmapKit/pull/5)).
- Boards tab in the demo — Streaks-style habit cards built on `CalendarHeatmap` ([#9](https://github.com/jacklv-coder/HeatmapKit/pull/9)).

### Changed
- Built-in `.green` palette now mirrors github.com light/dark variants exactly; the other five palettes also pick up adaptive light/dark shades ([#6](https://github.com/jacklv-coder/HeatmapKit/pull/6)).
- `todayHighlightColor` now defaults to `nil` (no outline), matching github.com. Opt back in with `.todayHighlightColor(.primary)` ([#7](https://github.com/jacklv-coder/HeatmapKit/pull/7)).

### Fixed
- Adaptive heatmap now sizes to actual content height, eliminating dead vertical space when `fitToWidth` is active ([#10](https://github.com/jacklv-coder/HeatmapKit/pull/10)).

## [0.4.0] — 2026-04-30

### Added
- `.snapshot(scale:background:)` — renders the full grid (without its scroll wrapper) to a `CGImage`, ready for `ShareLink`, `Image(decorative:scale:)`, `UIImage(cgImage:)`, or `CGImageDestination` ([#4](https://github.com/jacklv-coder/HeatmapKit/pull/4)).

## [0.3.0] — 2026-04-30

### Added
- Built-in detail tooltip on tap, customizable via `.tooltipOnTap { date, value in … }`. Tap the same cell again — or outside — to dismiss ([#3](https://github.com/jacklv-coder/HeatmapKit/pull/3)).

## [0.2.0] — 2026-04-30

### Added
- Per-cell VoiceOver labels via `.accessibilityCellLabel { date, value in … }` ([#2](https://github.com/jacklv-coder/HeatmapKit/pull/2)).

## [0.1.0] — 2026-04-30

### Added
- Initial release: `CalendarHeatmap` core — 7×N grid, horizontal scroll, 6 palettes (`.green`, `.orange`, `.blue`, `.purple`, `.red`, `.grayscale`), custom thresholds, tap callback, today highlight, locale-aware month/weekday labels.
- Key-path initializer `CalendarHeatmap(data:dateKey:valueKey:aggregation:)` for arbitrary value types, with `.sum` / `.count` / `.max` / `.min` / `.average` aggregation.

[0.5.0]: https://github.com/jacklv-coder/HeatmapKit/releases/tag/v0.5.0
[0.4.0]: https://github.com/jacklv-coder/HeatmapKit/releases/tag/v0.4.0
[0.3.0]: https://github.com/jacklv-coder/HeatmapKit/releases/tag/v0.3.0
[0.2.0]: https://github.com/jacklv-coder/HeatmapKit/releases/tag/v0.2.0
[0.1.0]: https://github.com/jacklv-coder/HeatmapKit/releases/tag/v0.1.0
