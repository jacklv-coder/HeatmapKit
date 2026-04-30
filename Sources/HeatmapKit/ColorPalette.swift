//
//  ColorPalette.swift
//  HeatmapKit
//

import SwiftUI

/// Built-in color schemes for `CalendarHeatmap`.
///
/// Each palette ships separate light- and dark-mode variants so the grid
/// looks at home in either appearance — `CalendarHeatmap` automatically
/// picks the one matching the surrounding `colorScheme` environment.
///
/// Each variant is a 5-step gradient: index 0 is the empty / no-data
/// color; indices 1-4 are progressively more intense.
///
/// To use your own colors, pass `.levels(_:)` with a `[Color]` array.
public enum ColorPalette: Sendable {
    /// GitHub-style green (default). Light variant matches github.com's
    /// contribution graph in light mode; dark variant matches dark mode.
    case green
    /// Warm orange palette.
    case orange
    /// Cool blue palette.
    case blue
    /// Vibrant purple palette.
    case purple
    /// Crimson red palette.
    case red
    /// Neutral grayscale (good for monochrome contexts).
    case grayscale

    /// The 5 colors that make up this palette for the given color scheme.
    public func colors(for scheme: ColorScheme) -> [Color] {
        let isLight = scheme == .light
        switch self {
        case .green:     return isLight ? Self.greenLight     : Self.greenDark
        case .orange:    return isLight ? Self.orangeLight    : Self.orangeDark
        case .blue:      return isLight ? Self.blueLight      : Self.blueDark
        case .purple:    return isLight ? Self.purpleLight    : Self.purpleDark
        case .red:       return isLight ? Self.redLight       : Self.redDark
        case .grayscale: return isLight ? Self.grayscaleLight : Self.grayscaleDark
        }
    }

    /// **Deprecated.** Returns the dark variant for backward compatibility.
    /// Use `colors(for:)` so the palette adapts to color scheme.
    @available(*, deprecated, message: "Use colors(for:) — the palette is now adaptive.")
    public var colors: [Color] {
        colors(for: .dark)
    }

    // MARK: - Green (matches the GitHub contribution graph)

    private static let greenLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0 empty
        Color(red: 0.608, green: 0.914, blue: 0.659),  // #9be9a8
        Color(red: 0.251, green: 0.769, blue: 0.388),  // #40c463
        Color(red: 0.188, green: 0.631, blue: 0.306),  // #30a14e
        Color(red: 0.129, green: 0.431, blue: 0.224),  // #216e39
    ]

    private static let greenDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22 empty
        Color(red: 0.055, green: 0.267, blue: 0.161),  // #0e4429
        Color(red: 0.000, green: 0.427, blue: 0.196),  // #006d32
        Color(red: 0.149, green: 0.651, blue: 0.255),  // #26a641
        Color(red: 0.224, green: 0.827, blue: 0.325),  // #39d353
    ]

    // MARK: - Orange

    private static let orangeLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0
        Color(red: 0.996, green: 0.843, blue: 0.667),  // #fed7aa
        Color(red: 0.992, green: 0.729, blue: 0.455),  // #fdba74
        Color(red: 0.976, green: 0.451, blue: 0.086),  // #f97316
        Color(red: 0.761, green: 0.255, blue: 0.047),  // #c2410c
    ]

    private static let orangeDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22
        Color(red: 0.486, green: 0.176, blue: 0.071),  // #7c2d12
        Color(red: 0.761, green: 0.255, blue: 0.047),  // #c2410c
        Color(red: 0.976, green: 0.451, blue: 0.086),  // #f97316
        Color(red: 0.984, green: 0.573, blue: 0.235),  // #fb923c
    ]

    // MARK: - Blue

    private static let blueLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0
        Color(red: 0.749, green: 0.859, blue: 0.996),  // #bfdbfe
        Color(red: 0.376, green: 0.647, blue: 0.980),  // #60a5fa
        Color(red: 0.231, green: 0.510, blue: 0.965),  // #3b82f6
        Color(red: 0.114, green: 0.306, blue: 0.847),  // #1d4ed8
    ]

    private static let blueDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22
        Color(red: 0.118, green: 0.227, blue: 0.541),  // #1e3a8a
        Color(red: 0.114, green: 0.306, blue: 0.847),  // #1d4ed8
        Color(red: 0.231, green: 0.510, blue: 0.965),  // #3b82f6
        Color(red: 0.376, green: 0.647, blue: 0.980),  // #60a5fa
    ]

    // MARK: - Purple

    private static let purpleLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0
        Color(red: 0.914, green: 0.835, blue: 1.000),  // #e9d5ff
        Color(red: 0.753, green: 0.518, blue: 0.988),  // #c084fc
        Color(red: 0.659, green: 0.333, blue: 0.969),  // #a855f7
        Color(red: 0.494, green: 0.133, blue: 0.808),  // #7e22ce
    ]

    private static let purpleDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22
        Color(red: 0.345, green: 0.106, blue: 0.561),  // #581c87
        Color(red: 0.494, green: 0.133, blue: 0.808),  // #7e22ce
        Color(red: 0.659, green: 0.333, blue: 0.969),  // #a855f7
        Color(red: 0.753, green: 0.518, blue: 0.988),  // #c084fc
    ]

    // MARK: - Red

    private static let redLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0
        Color(red: 0.996, green: 0.792, blue: 0.792),  // #fecaca
        Color(red: 0.973, green: 0.443, blue: 0.443),  // #f87171
        Color(red: 0.937, green: 0.267, blue: 0.267),  // #ef4444
        Color(red: 0.725, green: 0.110, blue: 0.110),  // #b91c1c
    ]

    private static let redDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22
        Color(red: 0.498, green: 0.114, blue: 0.114),  // #7f1d1d
        Color(red: 0.725, green: 0.110, blue: 0.110),  // #b91c1c
        Color(red: 0.937, green: 0.267, blue: 0.267),  // #ef4444
        Color(red: 0.973, green: 0.443, blue: 0.443),  // #f87171
    ]

    // MARK: - Grayscale

    private static let grayscaleLight: [Color] = [
        Color(red: 0.922, green: 0.929, blue: 0.941),  // #ebedf0
        Color(red: 0.820, green: 0.835, blue: 0.859),  // #d1d5db
        Color(red: 0.612, green: 0.639, blue: 0.686),  // #9ca3af
        Color(red: 0.294, green: 0.333, blue: 0.388),  // #4b5563
        Color(red: 0.122, green: 0.161, blue: 0.216),  // #1f2937
    ]

    private static let grayscaleDark: [Color] = [
        Color(red: 0.086, green: 0.106, blue: 0.133),  // #161b22
        Color(red: 0.224, green: 0.255, blue: 0.318),  // #394150
        Color(red: 0.412, green: 0.451, blue: 0.502),  // #6b7280
        Color(red: 0.612, green: 0.639, blue: 0.686),  // #9ca3af
        Color(red: 0.820, green: 0.835, blue: 0.859),  // #d1d5db
    ]
}
