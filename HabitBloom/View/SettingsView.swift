//
//  SettingsView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-20.
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    // MARK: - State Properties
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("silentHoursEnabled") private var silentHoursEnabled = false
    @AppStorage("silentStartHour") private var silentStartHour = 22
    @AppStorage("silentStartMinute") private var silentStartMinute = 0
    @AppStorage("silentEndHour") private var silentEndHour = 5
    @AppStorage("silentEndMinute") private var silentEndMinute = 0
    @AppStorage("iCloudBackupEnabled") private var iCloudBackupEnabled = true
    @AppStorage("isProUser", store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)) var isProUser = false
    
    @ObservedObject private var proManager = ProManager.shared
    
    @State private var showProSheet = false
    @State private var showClearStorageAlert =  false
    @State private var showExportProAlert = false
    @State private var showIconProAlert = false
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false
    @State private var showRestoreResult = false
    @State private var restoreResultMessage = ""
    
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    // MARK: - Subscription helpers
    private var entitlement: ProEntitlement? { proManager.activeEntitlement }
    
    /// Plan name from the App Store product, falling back to the plan type before products load.
    private var planName: String {
        guard let entitlement else { return "Pro" }
        return proManager.product(for: entitlement.productID)?.displayName ?? entitlement.plan.displayName
    }
    
    /// Price line such as "$1.99/month" or "$10.99 one-time", once the product has loaded.
    private var planPriceText: String? {
        guard let entitlement,
              let product = proManager.product(for: entitlement.productID) else { return nil }
        if entitlement.isLifetime {
            return "\(product.displayPrice) one-time"
        }
        return product.displayPrice + (proManager.renewalPeriodSuffix(for: product) ?? "")
    }
    
    /// Renewal, trial-end, or expiry line for the current plan.
    private var planStatusText: String? {
        guard let entitlement else { return nil }
        if entitlement.isLifetime { return "Pay once, yours forever" }
        guard let date = entitlement.expirationDate else { return nil }
        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        switch (entitlement.isFreeTrial, entitlement.willAutoRenew) {
        case (true, true): return "Free trial ends \(formatted)"
        case (true, false): return "Free trial ends \(formatted) · Won't renew"
        case (false, true): return "Renews \(formatted)"
        case (false, false): return "Expires \(formatted)"
        }
    }
    
    /// True when the customer turned off auto-renew, so the plan will lapse at the end of the period.
    private var planIsLapsing: Bool {
        guard let entitlement, !entitlement.isLifetime else { return false }
        return !entitlement.willAutoRenew
    }
    
    /// A subscription that keeps renewing even though Lifetime is now the active entitlement.
    /// Apple doesn't let the app cancel it, so the customer has to do that in the App Store.
    private var overlappingSubscription: ProEntitlement? {
        guard entitlement?.isLifetime == true,
              let subscription = proManager.activeSubscription,
              subscription.willAutoRenew else { return nil }
        return subscription
    }
    
    private func planDisplayName(for subscription: ProEntitlement) -> String {
        proManager.product(for: subscription.productID)?.displayName ?? subscription.plan.displayName
    }
    
    /// Short plan summary for the status card; the dated detail lives in the Current Plan row.
    private var proCardSubtitle: String {
        guard let entitlement else { return "All features unlocked" }
        if entitlement.isLifetime { return "Lifetime access" }
        if entitlement.isFreeTrial { return "\(planName) plan · Free trial" }
        if planIsLapsing { return "\(planName) plan · Not renewing" }
        return "\(planName) plan"
    }
    
    /// Badge text on the status card.
    private var proCardBadge: String {
        if entitlement?.isFreeTrial == true { return "Trial" }
        return planIsLapsing ? "Ending" : "Active"
    }
    
    // Helper bindings for DatePickers
    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { makeDate(hour: silentStartHour, minute: silentStartMinute) },
            set: { newDate in
                let comp = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                silentStartHour = comp.hour ?? 22
                silentStartMinute = comp.minute ?? 0
            }
        )
    }
    
    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { makeDate(hour: silentEndHour, minute: silentEndMinute) },
            set: { newDate in
                let comp = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                silentEndHour = comp.hour ?? 5
                silentEndMinute = comp.minute ?? 0
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Pro Banner / Status
                        if isProUser {
                            proStatusCard
                            subscriptionSection
                        } else {
                            Button {
                                showProSheet =  true
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "crown")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(theme.accent, in: Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upgrade to MyHabitsBloom Pro")
                                            .font(.headline)
                                            .foregroundStyle(theme.textPrimary)
                                        Text("Unlimited habits · Analytics · Export")
                                            .font(.caption)
                                            .foregroundStyle(theme.accentSoft)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(theme.accent)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(theme.proBanner)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(theme.proBannerStroke, lineWidth: 1)
                                        )
                                )
                            }
                            
                        }
                        
                        // MARK: - Appearance Section
                        
                        SettingsSection(title: "Appearance") {
                            SettingsToggleRow(icon: "moon.fill", iconColor: theme.accent, title: "Dark Mode", isOn: $isDarkMode)
                            
                            //                        Divider().overlay(theme.divider)
                            //
                            //                        SettingsProRow(
                            //                            icon: "paintpalette.fill",
                            //                            iconColor: .orange,
                            //                            title: "Custom App Icon"
                            //                        ) {
                            //                            if isProUser {
                            //                                // Navigate to custom icon picker
                            //                            } else {
                            //                                showIconProAlert = true
                            //                            }
                            //                        }
                            
                            
                            
                            
                            
                        }
                        
                        // MARK: - Notifications Section
                        SettingsSection(title: "NOTIFICATIONS") {
                            SettingsToggleRow(
                                icon: "bell",
                                iconColor: theme.warning,
                                title: "Push Notifications",
                                isOn: $notificationsEnabled
                            )
                            
                            Divider().overlay(theme.divider)
                            
                            HStack {
                                SettingsIcon(name: "moon.stars", color: theme.accent)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Silent Hours")
                                        .font(.body)
                                        .foregroundStyle(theme.textPrimary)
                                }
                                
                                Spacer()
                                
                                Text("\(startTimeBinding.wrappedValue, style: .time) - \(endTimeBinding.wrappedValue, style: .time)")
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                                
                                Toggle("", isOn: $silentHoursEnabled)
                                    .labelsHidden()
                                
                            }
                            .padding(.vertical, 4)
                            
                            VStack{
                                if silentHoursEnabled {
                                    DatePicker("Start Time", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                                    DatePicker("End Time", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                                }
                            }.padding(.horizontal,40)
    
                        }
                        
                        // MARK: - Data & Privacy Section
                        SettingsSection(title: "DATA & PRIVACY") {
//                            SettingsToggleRow(
//                                icon: "shield.fill",
//                                iconColor: .green,
//                                title: "iCloud Backup",
//                                isOn: $iCloudBackupEnabled
//                            )
                            
//                            Divider().overlay(theme.divider)
                            
                            if isProUser {
                                ShareLink(
                                    item: HabitDataCSV(habits: habits),
                                    preview: SharePreview("Habit Data Export", image: Image(systemName: "square.and.arrow.down"))
                                ) {
                                    HStack {
                                        SettingsIcon(name: "square.and.arrow.down", color: theme.accent)
                                        Text("Export Data (CSV)")
                                            .foregroundStyle(theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.bold())
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            } else {
                                SettingsProRow(
                                    icon: "square.and.arrow.down",
                                    iconColor: theme.accent,
                                    title: "Export Data (CSV)"
                                ) {
                                    showExportProAlert = true
                                }
                            }
                            
                            Divider().overlay(theme.divider)
                            
                            // Clear Local Storage Row
                            Button(role: .destructive) {
                                showClearStorageAlert = true
                            } label: {
                                HStack {
                                    SettingsIcon(name: "trash", color: theme.destructive)
                                    Text("Clear Local Storage")
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Text("Clear")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(theme.destructive)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                    }
                }
                
            }
           
        }
        .navigationTitle("Settings")
        .tint(.themeAccent)
        .preferredColorScheme(theme.colorScheme)
        .background(theme.background.ignoresSafeArea())
        // MARK: - Alerts & Sheets
        .alert("Habitat Pro Feature", isPresented: $showExportProAlert) {
            Button("Upgrade to Pro") { showProSheet = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Exporting habit history to CSV requires a MyHabitsBloom Pro subscription.")
        }
        .alert("MyHabitsBloom Pro Feature", isPresented: $showIconProAlert) {
            Button("Upgrade to Pro") { showProSheet = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Custom App Icons are exclusive to MyHabitsBloom Pro members.")
        }
        .alert("Clear Local Storage?", isPresented: $showClearStorageAlert) {
            Button("Delete All Data", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action will permanently remove all habits and completion logs. It cannot be undone.")
        }
        .sheet(isPresented: $showProSheet) {
            PaywallView()
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .onChange(of: showManageSubscriptions) { _, isPresented in
            // Turning auto-renew off in the App Store sheet doesn't emit a transaction, so re-check on dismiss.
            if !isPresented {
                Task { await proManager.updatePurchasedStatus() }
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreResultMessage)
        }
        .task(id: isProUser) {
            // Products supply the plan name and price; entitlement supplies renewal details.
            guard isProUser else { return }
            if proManager.products.isEmpty {
                await proManager.loadProducts()
            }
            await proManager.updatePurchasedStatus()
        }
        .onChange(of: notificationsEnabled) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        .onChange(of: silentHoursEnabled) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        .onChange(of: silentStartHour) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        .onChange(of: silentStartMinute) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        .onChange(of: silentEndHour) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        .onChange(of: silentEndMinute) { _, _ in
            NotificationManager.syncAllNotifications(habits: habits)
        }
        
        
    }
    // MARK: - Pro Status Card
    private var proStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .padding(12)
                .background(theme.accent, in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MyHabitsBloom Pro")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                Text(proCardSubtitle)
                    .font(.caption)
                    .foregroundStyle(theme.accentSoft)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                Text(proCardBadge)
            }
            .font(.caption.bold())
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.accent.opacity(0.15), in: Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.proBanner)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(theme.proBannerStroke, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription") {
            // Current plan with renewal / trial / expiry detail
            HStack {
                SettingsIcon(name: "creditcard", color: theme.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Plan")
                        .foregroundStyle(theme.textPrimary)
                    if let planStatusText {
                        Text(planStatusText)
                            .font(.caption)
                            .foregroundStyle(planIsLapsing ? theme.warning : theme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(planName)
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.textPrimary)
                    if let planPriceText {
                        Text(planPriceText)
                            .font(.caption2)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .padding(.vertical, 4)
            
            if let overlappingSubscription {
                // Lifetime is active but a subscription is still billing; point the customer to cancel it.
                Divider().overlay(theme.divider)
                
                HStack(alignment: .top) {
                    SettingsIcon(name: "exclamationmark.triangle", color: theme.warning)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(planDisplayName(for: overlappingSubscription)) plan still renews")
                            .foregroundStyle(theme.textPrimary)
                        Text(overlappingRenewalMessage(for: overlappingSubscription))
                            .font(.caption)
                            .foregroundStyle(theme.warning)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Divider().overlay(theme.divider)
                
                SettingsActionRow(
                    icon: "storefront",
                    iconColor: theme.accent,
                    title: "Cancel in App Store"
                ) {
                    showManageSubscriptions = true
                }
            } else if entitlement?.isLifetime != true {
                // Lifetime never renews, so there is nothing to manage or switch in the App Store.
                Divider().overlay(theme.divider)
                
                SettingsActionRow(
                    icon: "storefront",
                    iconColor: theme.accent,
                    title: "Manage in App Store"
                ) {
                    showManageSubscriptions = true
                }
                
                Divider().overlay(theme.divider)
                
                SettingsActionRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: theme.accentSoft,
                    title: "Change Plan"
                ) {
                    showProSheet = true
                }
            }
            
            Divider().overlay(theme.divider)
            
            SettingsActionRow(
                icon: "arrow.clockwise",
                iconColor: theme.warning,
                title: "Restore Purchases",
                isBusy: isRestoring
            ) {
                restorePurchases()
            }
        }
    }
    
    private func overlappingRenewalMessage(for subscription: ProEntitlement) -> String {
        let cancelHint = "You already own Lifetime, so cancel it in the App Store to avoid further charges."
        guard let date = subscription.expirationDate else { return cancelHint }
        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        let renewal = subscription.isFreeTrial ? "Billing starts \(formatted)." : "Next charge \(formatted)."
        return "\(renewal) \(cancelHint)"
    }
    
    private func restorePurchases() {
        Task {
            isRestoring = true
            let restored = await proManager.restorePurchases()
            isRestoring = false
            if restored {
                restoreResultMessage = "Your MyHabitsBloom Pro purchase is active on this device."
            } else {
                restoreResultMessage = proManager.errorMessage
                    ?? "No active MyHabitsBloom Pro purchase was found for this Apple Account."
            }
            showRestoreResult = true
        }
    }
    
    private func makeDate(hour: Int, minute: Int) -> Date {
        var comp = DateComponents()
        comp.hour = hour
        comp.minute = minute
        return Calendar.current.date(from: comp) ?? Date()
    }
    // MARK: - Storage Cleanup Logic
    private func clearAllData() {
        for habit in habits {
            modelContext.delete(habit)
        }
        try? modelContext.save()
    }
    
}

struct SettingsSection <Content: View>: View {
    
    let title : String
    @ViewBuilder let content: () -> Content
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.bold())
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
                .padding(.leading, 8)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
//            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(theme.cardBackground)))
        }
    }
}

struct SettingsIcon: View {
    let name: String
    let color: Color
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        Image(systemName: name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(theme.trackRing, in: Circle())
    }
}

struct SettingsToggleRow : View {
    let icon: String
    let iconColor : Color
    let title: String
    @Binding var isOn: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        HStack {
            SettingsIcon(name: icon, color: iconColor)
            Text(title)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

/// Tappable settings row with a chevron, or a spinner while its action is running.
struct SettingsActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isBusy: Bool = false
    let action: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        Button(action: action) {
            HStack {
                SettingsIcon(name: icon, color: iconColor)
                Text(title)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                if isBusy {
                    ProgressView()
                        .tint(theme.textSecondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(isBusy)
    }
}

struct SettingsProRow : View {
    let icon: String
    let iconColor : Color
    let title: String
    let action : () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    var body: some View {
        Button(action: action) {
            HStack {
                SettingsIcon(name: icon, color: iconColor)
                Text(title)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("Pro")
                        .font(.caption.bold())
                }
                .foregroundStyle(theme.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
                
            }
            .padding(.vertical, 4)
        }

    }
}

#Preview {
    SettingsView()
}
