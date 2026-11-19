//
//  OnboardingView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-11-10.
//

import SwiftUI

/// A three step introduction shown the first time the app launches.
struct OnboardingView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    /// Called when the user taps Skip or Get Started.
    let onFinish: () -> Void
    
    @State private var currentPage: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "leaf.fill",
            gradient: [Color.themeAccent, Color.purple],
            title: "Build habits that stick",
            subtitle: "Create daily routines and check them off with a single tap. Small steps, every day, add up to big change."
        ),
        OnboardingPage(
            icon: "flame.fill",
            gradient: [Color.orange, Color.pink],
            title: "Track streaks and stay consistent",
            subtitle: "Watch your streaks grow and keep your momentum going with a clear view of every day you show up."
        ),
        OnboardingPage(
            icon: "chart.bar.xaxis.ascending",
            gradient: [Color.green, Color.teal],
            title: "Insights, widgets and reminders",
            subtitle: "See your progress with analytics, check off habits right from your Home Screen, and never miss a day with reminders."
        )
    ]
    
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            // Soft decorative glow that shifts color with the current page
            Circle()
                .fill(
                    LinearGradient(
                        colors: pages[currentPage].gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .opacity(isDarkMode ? 0.45 : 0.35)
                .offset(y: -180)
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Top bar with Skip
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("Skip") {
                            onFinish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.opacity)
                    }
                }
                .frame(height: 44)
                .animation(.easeInOut(duration: 0.2), value: isLastPage)
                
                // Paged content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, theme: theme)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.themeAccent : theme.trackRing)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.bottom, 28)
                
                // Primary action
                Button {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                } label: {
                    Text(isLastPage ? "Get Started" : "Next")
                        .font(.headline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(Color.themeAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.themeAccent.opacity(0.35), radius: 14, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let icon: String
    let gradient: [Color]
    let title: String
    let subtitle: String
}

// MARK: - Single Page

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(Color(theme.cardBackground))
                    .frame(width: 168, height: 168)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
                
                Image(systemName: page.icon)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textPrimary)
                
                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
