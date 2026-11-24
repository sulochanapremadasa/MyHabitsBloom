//
//  Color.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-29.
//

import SwiftUI

// MARK: - Color Palette Extension
//
// Indigo / periwinkle palette. Dark mode sits on a near-black navy canvas with
// dark indigo cards; light mode sits on a pale lavender canvas with white cards.

extension Color {

    // Accent (shared by both modes)
    static let themeAccent = Color(red: 0.48, green: 0.44, blue: 0.94)       // #7B70F0 periwinkle
    static let darkAccentSoft = Color(red: 0.62, green: 0.58, blue: 0.90)    // #9E94E6 lavender text on dark
    static let lightAccentSoft = Color(red: 0.42, green: 0.38, blue: 0.80)   // #6B61CC lavender text on light

    // Backgrounds
    static let darkPurplishBackground = Color(red: 0.082, green: 0.071, blue: 0.141)  // #151224 (matches launch screen)
    static let lightPurplishBackground = Color(red: 0.953, green: 0.949, blue: 0.980) // #F3F2FA

    // Cards & Containers
    static let darkCardBackground = Color(red: 0.133, green: 0.118, blue: 0.224)  // #221E39
    static let lightCardBackground = Color.white

    // Subdued fills: progress-ring tracks, icon badge circles, empty heatmap tiles
    static let darkTrackRing = Color(red: 0.180, green: 0.161, blue: 0.290)   // #2E294A
    static let lightTrackRing = Color(red: 0.925, green: 0.918, blue: 0.973)  // #ECEAF8

    // Disabled outline: habit matrix days the habit isn't scheduled on
    static let darkDisabledOutline = Color(red: 0.239, green: 0.216, blue: 0.369)   // #3D375E
    static let lightDisabledOutline = Color(red: 0.851, green: 0.839, blue: 0.922)  // #D9D6EB

    // Pro banner surface and hairline
    static let darkProBanner = Color(red: 0.196, green: 0.173, blue: 0.376)        // #322C60
    static let darkProBannerStroke = Color(red: 0.290, green: 0.263, blue: 0.525)  // #4A4386
    static let lightProBanner = Color(red: 0.906, green: 0.890, blue: 0.984)       // #E7E3FB
    static let lightProBannerStroke = Color(red: 0.776, green: 0.753, blue: 0.941) // #C6C0F0

    // Text Colors
    static let lightTextPrimary = Color(red: 0.124, green: 0.013, blue: 0.227)   // #1c0333purplish black
    static let lightTextSecondary = Color(red: 0.553, green: 0.533, blue: 0.659) // #8D88A8
    static let darkTextSecondary = Color(red: 0.545, green: 0.529, blue: 0.651)  // #8B87A6

    // Dividers
    static let darkDivider = Color.white.opacity(0.06)
    static let lightDivider = Color(red: 0.082, green: 0.071, blue: 0.141).opacity(0.06)

    // Semantic
    static let themeDestructive = Color(red: 0.94, green: 0.44, blue: 0.40) // #F07067 coral
    static let themeWarning = Color(red: 0.96, green: 0.76, blue: 0.30)     // #F5C24D amber
}
