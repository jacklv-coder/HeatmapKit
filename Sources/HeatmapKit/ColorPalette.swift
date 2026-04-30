//
//  ColorPalette.swift
//  HeatmapKit
//

import SwiftUI

/// Built-in color schemes for `CalendarHeatmap`.
///
/// Each palette is a 5-step gradient: index 0 is the empty / no-data color,
/// indices 1-4 are progressively more intense.
///
/// To use your own colors, pass `.levels(_:)` with a `[Color]` array directly.
public enum ColorPalette: Sendable {
    /// GitHub-style green (default).
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

    /// The 5 colors that make up this palette.
    public var colors: [Color] {
        switch self {
        case .green:
            return [
                Color(red: 0.13, green: 0.16, blue: 0.18), // empty
                Color(red: 0.06, green: 0.27, blue: 0.10),
                Color(red: 0.00, green: 0.43, blue: 0.13),
                Color(red: 0.16, green: 0.65, blue: 0.27),
                Color(red: 0.22, green: 0.83, blue: 0.39),
            ]
        case .orange:
            return [
                Color(red: 0.13, green: 0.16, blue: 0.18),
                Color(red: 0.36, green: 0.18, blue: 0.05),
                Color(red: 0.55, green: 0.30, blue: 0.10),
                Color(red: 0.72, green: 0.39, blue: 0.17),
                Color(red: 0.93, green: 0.49, blue: 0.17),
            ]
        case .blue:
            return [
                Color(red: 0.13, green: 0.16, blue: 0.18),
                Color(red: 0.07, green: 0.20, blue: 0.42),
                Color(red: 0.10, green: 0.34, blue: 0.62),
                Color(red: 0.21, green: 0.50, blue: 0.83),
                Color(red: 0.37, green: 0.70, blue: 0.95),
            ]
        case .purple:
            return [
                Color(red: 0.13, green: 0.16, blue: 0.18),
                Color(red: 0.30, green: 0.13, blue: 0.40),
                Color(red: 0.45, green: 0.20, blue: 0.60),
                Color(red: 0.60, green: 0.30, blue: 0.78),
                Color(red: 0.75, green: 0.45, blue: 0.92),
            ]
        case .red:
            return [
                Color(red: 0.13, green: 0.16, blue: 0.18),
                Color(red: 0.40, green: 0.10, blue: 0.10),
                Color(red: 0.60, green: 0.18, blue: 0.18),
                Color(red: 0.80, green: 0.28, blue: 0.28),
                Color(red: 0.95, green: 0.40, blue: 0.40),
            ]
        case .grayscale:
            return [
                Color(white: 0.15),
                Color(white: 0.30),
                Color(white: 0.50),
                Color(white: 0.70),
                Color(white: 0.92),
            ]
        }
    }
}
