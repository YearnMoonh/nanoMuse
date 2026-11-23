//
//  NanoMuseLiquidGlass.swift
//  nanoMuse
//
//  Shared Liquid Glass surfaces for the Muse shell. On iOS 26 and later, floating
//  controls adopt Apple's native SwiftUI `glassEffect(_:in:)` so scrolling messages
//  refract and shift luminance naturally behind them. On earlier iOS releases (back
//  to the iOS 16.0 deployment target) and whenever Reduce Transparency is enabled,
//  every surface falls back to the shell's established material or opaque fill.
//

import SwiftUI

/// Feature gate shared by scrims and vignettes that lighten when native Liquid Glass
/// is active so scrolling content remains visible behind floating glass controls.
enum NanoMuseGlassSupport {
    static var isNativeAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}

/// Applies Apple's native Liquid Glass to a floating Muse control on iOS 26+, with
/// Reduce Transparency and earlier iOS material fallbacks.
struct NanoMuseLiquidGlassSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    var interactive: Bool = false
    var fallbackFill: Color = NanoMuseTones.surface
    var fallbackMaterialOpacity: Double = 0.55
    var fallbackBorder: Bool = true
    var fallbackShadow: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(shape.fill(fallbackFill))
                .overlay(shape.strokeBorder(NanoMuseTones.hairline, lineWidth: 1))
                .shadow(color: fallbackShadow ? .black.opacity(scheme == .dark ? 0 : 0.14) : .clear, radius: 3, y: 1)
                .contentShape(shape)
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
                .contentShape(shape)
        } else {
            content
                .background {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(fallbackFill.opacity(fallbackMaterialOpacity))
                }
                .overlay {
                    if fallbackBorder {
                        shape.strokeBorder(NanoMuseTones.hairline, lineWidth: 1)
                    }
                }
                .shadow(color: fallbackShadow ? .black.opacity(scheme == .dark ? 0 : 0.14) : .clear, radius: 3, y: 1)
                .contentShape(shape)
        }
    }
}

/// Liquid Glass container for Muse's composer pill. Keeps `[T-popup-white-patch]`
/// intact by painting directly into `shape` (never a rectangular backing layer)
/// and clipping child views to the same continuous rounded contour.
struct NanoMuseComposerGlassSurface<S: InsettableShape>: ViewModifier {
    let shape: S

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(shape.fill(NanoMuseTones.bubble))
                .overlay(shape.strokeBorder(NanoMuseTones.hairline, lineWidth: 1))
                .clipShape(shape)
                .contentShape(shape)
                .shadow(color: Color.black.opacity(scheme == .dark ? 0 : 0.08), radius: 4, x: 0, y: 2)
        } else if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: shape)
                .clipShape(shape)
                .contentShape(shape)
        } else {
            content
                .background(shape.fill(NanoMuseTones.bubble))
                .clipShape(shape)
                .contentShape(shape)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
}

extension View {
    /// Styles a floating Muse control with native Liquid Glass on iOS 26+ and
    /// automatic Reduce Transparency / legacy iOS fallbacks.
    func nmLiquidGlass<S: InsettableShape>(
        in shape: S,
        interactive: Bool = false,
        fallbackFill: Color = NanoMuseTones.surface,
        fallbackMaterialOpacity: Double = 0.55,
        fallbackBorder: Bool = true,
        fallbackShadow: Bool = false
    ) -> some View {
        modifier(
            NanoMuseLiquidGlassSurface(
                shape: shape,
                interactive: interactive,
                fallbackFill: fallbackFill,
                fallbackMaterialOpacity: fallbackMaterialOpacity,
                fallbackBorder: fallbackBorder,
                fallbackShadow: fallbackShadow
            )
        )
    }
}
