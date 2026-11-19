//
//  HabitBloomApp.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-11.
//

import SwiftUI
import SwiftData

@main
struct HabitBloomApp: App {
    @State private var showPaywall = false
    @Environment(\.scenePhase) private var scenePhase
    
    /// Set once the user finishes or skips the first-launch onboarding.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .sheet(isPresented: $showPaywall) {
                            PaywallView()
                        }
                        .onOpenURL { url in
                            if url == URL(string: "habitbloom://paywall")! { //to open paywall view from widget kit for free users.
                                showPaywall = true
                            }
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            if newPhase == .active {
                                Task {
                                    await ProManager.shared.updatePurchasedStatus()
                                }
                            }
                        }
                        .transition(.opacity)
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(try! SharedModelContainer.create())
    }
}
