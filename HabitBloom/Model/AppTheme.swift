//
//  AppTheme.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-29.
//
import SwiftUI

struct AppTheme {
    let isDark: Bool

    // MARK: Surfaces

    var background: Color {
        isDark ? .darkPurplishBackground : .lightPurplishBackground
    }

    var cardBackground: Color {
        isDark ? .darkCardBackground : .lightCardBackground
    }

    /// Subdued fill used for ring tracks, icon badge circles and empty tiles.
    var trackRing: Color {
        isDark ? .darkTrackRing : .lightTrackRing
    }

    var proBanner: Color {
        isDark ? .darkProBanner : .lightProBanner
    }

    var proBannerStroke: Color {
        isDark ? .darkProBannerStroke : .lightProBannerStroke
    }

    var divider: Color {
        isDark ? .darkDivider : .lightDivider
    }

    // MARK: Text

    var textPrimary: Color {
        isDark ? .white : .lightTextPrimary
    }

    var textSecondary: Color {
        isDark ? .darkTextSecondary : .lightTextSecondary
    }

    // MARK: Accents

    var accent: Color { .themeAccent }

    /// Softer lavender tone for supporting text that should still read as "accent".
    var accentSoft: Color {
        isDark ? .darkAccentSoft : .lightAccentSoft
    }

    var destructive: Color { .themeDestructive }

    var warning: Color { .themeWarning }

    var colorScheme: ColorScheme {
        isDark ? .dark : .light
    }

    var dateSelect: Color { accent }
}
