//
//  MainTabView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-20.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var isShowingAddHabitSheet: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private var theme: AppTheme {
        AppTheme(isDark: isDarkMode)
    }
    
    init() {
        Self.configureBarAppearances()
    }
    
    /// Navigation bar large and inline titles use the theme's primary text colour
    /// (purplish black in light mode, white in dark) instead of the system's pure black.
    /// A dynamic UIColor resolves against the trait collection, so it flips with `preferredColorScheme`.
    private static func configureBarAppearances() {
        let title = UIColor { trait in
            UIColor(AppTheme(isDark: trait.userInterfaceStyle == .dark).textPrimary)
        }
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: title]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: title]
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Main Dashboard
            MainDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Analytics Screen (Middle)
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .background(theme.background.ignoresSafeArea())
        .tint(.themeAccent)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    MainTabView()
}
