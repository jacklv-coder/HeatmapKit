//
//  CalendarHeatmap+Snapshot.swift
//  HeatmapKit
//
//  Render the heatmap to an image for sharing, saving, or uploading.
//

import SwiftUI

public extension CalendarHeatmap {

    /// Render the heatmap to a `CGImage` for sharing, saving, or uploading.
    ///
    /// The grid is rendered without its horizontal `ScrollView` so the full
    /// date range is captured at intrinsic width — even if it would normally
    /// scroll on screen.
    ///
    /// ```swift
    /// if let cg = heatmap.snapshot(scale: 3, background: Color.black) {
    ///     let image = Image(decorative: cg, scale: 3)
    ///     ShareLink(item: image,
    ///               preview: SharePreview("My activity", image: image))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scale: Render scale (typically 1, 2, or 3). Defaults to 3 for
    ///     crisp output on retina displays.
    ///   - background: Optional fill drawn behind the grid with 12pt
    ///     padding. Pass `nil` (default) for a transparent background.
    /// - Returns: A `CGImage`, or `nil` if rendering failed.
    @MainActor
    func snapshot(
        scale: CGFloat = 3,
        background: Color? = nil
    ) -> CGImage? {
        var capture = self
        capture.scrollEnabled = false

        let content: AnyView
        if let background {
            content = AnyView(
                capture
                    .padding(12)
                    .background(background)
            )
        } else {
            content = AnyView(capture)
        }

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return renderer.cgImage
    }
}
