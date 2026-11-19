//
//  PaywallView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-14.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var proManager = ProManager.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    
    /// Plans shown on the paywall. Lifetime is hidden while a subscription is active, because
    /// buying it wouldn't stop the subscription from billing.
    private var availableProducts: [Product] {
        proManager.purchasableProducts
    }
    
    /// The first product that still offers the customer a free trial, used for hero copy.
    private var trialProduct: Product? {
        availableProducts.first { proManager.eligibleFreeTrial(for: $0) != nil }
    }
    
    /// Trial length label ("3-Day") for the currently selected plan, if it has an eligible trial.
    private var selectedTrialLabel: String? {
        guard let product = selectedProduct else { return nil }
        return proManager.trialLengthLabel(for: product)
    }
    
    /// Text shown under the CTA describing what the customer is agreeing to.
    private var purchaseDisclosure: String? {
        guard let product = selectedProduct else { return nil }
        let suffix = proManager.renewalPeriodSuffix(for: product) ?? ""
        if let trialLength = proManager.trialLengthText(for: product) {
            return "\(trialLength) free, then \(product.displayPrice)\(suffix). Auto-renews until cancelled. Cancel anytime in Settings."
        }
        if product.subscription != nil {
            return "\(product.displayPrice)\(suffix). Auto-renews until cancelled. Cancel anytime in Settings."
        }
        return nil
    }
    
    var body: some View {
        NavigationStack{
            ZStack{
                ScrollView{
                    VStack (spacing: 24) {
                        
                        // 1. Hero / Header Section
                        VStack (spacing: 12) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.accentSoft, theme.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 16)
                            
                            Text("Unlock Habit Tracker Pro")
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundStyle(theme.textPrimary)
                            
                            if let trialProduct, let trialLength = proManager.trialLengthText(for: trialProduct) {
                                Text("Try every Pro feature free for \(trialLength). Cancel anytime.")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            } else {
                                Text("Build unlimited routines and stay consistent every day with zero limitations.")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // 2. Pro Features List
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "infinity", color: theme.accent, title: "Unlimited Habits", subtitle: "Track more than 8 habits simultaneously.")
                            FeatureRow(icon: "square.stack.3d.up.fill", color: theme.accentSoft, title: "Interactive Home Widgets", subtitle: "Check off habits right from your Lock & Home screen.")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", color: .green, title: "Advanced Analytics & Heatmaps", subtitle: "Deep insights and monthly consistency trends.")
//                            FeatureRow(icon: "icloud.fill", color: .cyan, title: "iCloud Sync", subtitle: "Seamlessly backup and sync across all your Apple devices.")
                            FeatureRow(icon: "arrow.down.document.fill", color: .cyan, title: "Export to CSV", subtitle: "Universal text format that almost any program can open.")
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(theme.cardBackground)))
                        .padding(.horizontal)
                        
                        // 3. Subscription Options Selector
                        if proManager.isLoading{
                            ProgressView("Loading plans...")
                                .padding(.vertical, 30)
                        }else if availableProducts.isEmpty {
                            VStack(spacing: 8) {
                                Text("Unable to load plans")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                Button("Retry") {
                                    Task { await proManager.loadProducts() }
                                }
                            }
                            .padding(.vertical, 20)
                        }else{
                            VStack(spacing: 12) {
                                ForEach(availableProducts, id: \.id) { product in
                                    ProductOptionCard(
                                        product: product,
                                        trialLength: proManager.trialLengthText(for: product),
                                        renewalSuffix: proManager.renewalPeriodSuffix(for: product),
                                        isSelected: selectedProduct?.id == product.id
                                    ) {
                                        selectedProduct = product
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        // Error Banner
                        if let errorMessage = proManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(theme.destructive)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // 4. Action CTA Button
                        
                        VStack(spacing: 10) {
                            Button {
                                guard let product = selectedProduct else { return }
                                Task {
                                    isPurchasing = true
                                    let success = await proManager.purchase(product)
                                    isPurchasing = false
                                    if success {
                                        dismiss()
                                    }
                                }
                            } label: {
                                ZStack {
                                    if isPurchasing {
                                        ProgressView().tint(.white)
                                    } else if let selectedTrialLabel {
                                        Text("Start \(selectedTrialLabel) Free Trial")
                                            .font(.headline)
                                            .bold()
                                    } else {
                                        Text("Continue")
                                            .font(.headline)
                                            .bold()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedProduct == nil ? theme.trackRing : theme.accent)
                                .foregroundColor(selectedProduct == nil ? theme.textSecondary : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(selectedProduct == nil || isPurchasing)
                            
                            // Renewal disclosure for the selected plan
                            if let purchaseDisclosure {
                                Text(purchaseDisclosure)
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.horizontal)
                        
                        
                        // 5. Restore & Terms Legal Footer
                        HStack(spacing: 16) {
                            Button("Restore Purchases") {
                                Task {
                                    isPurchasing = true
                                    let restored = await proManager.restorePurchases()
                                    isPurchasing = false
                                    if restored {
                                        dismiss()
                                    }
                                }
                            }
                            
//                            Text("•")
//                            
//                            Link("Terms of Service", destination: URL(string: "https://habitbloom.com/terms")!)
                            
                            Text("•")
                            
                            Link("Privacy Policy", destination: URL(string: "https://aplivox.com/privacy/myhabitsbloom")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                        .padding(.bottom, 20)
                        
                    }
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(theme.textSecondary)
                            .font(.title2)
                    }

                }
            }
            .background(theme.background.ignoresSafeArea())
            .task {
                await proManager.loadProducts()
                // Auto-select the Monthly plan so the free trial is featured first,
                // skipping whichever plan the customer is already subscribed to.
                if selectedProduct == nil {
                    let currentPlanID = proManager.activeSubscription?.productID
                    let candidates = availableProducts.filter { $0.id != currentPlanID }
                    selectedProduct = candidates.first(where: { $0.id.contains("monthly") }) ?? candidates.first
                }
            }
            .tint(.themeAccent)
            .preferredColorScheme(theme.colorScheme)
            
        }
    }
    
}




// MARK: - Supporting Views

/// Single Feature Row

struct FeatureRow : View {
    let icon :String
    let color : Color
    let title : String
    let subtitle : String
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View{
        HStack(spacing: 14){
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(theme.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        
    }
}


/// Product Selection Option Card

struct ProductOptionCard : View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    let product: Product
    /// Localized trial length such as "3 days" when the customer is eligible for a free trial.
    let trialLength: String?
    /// Renewal period suffix such as "/month" for subscription products.
    let renewalSuffix: String?
    let isSelected: Bool
    let onSelect:() -> Void
    
    var isAnnual: Bool {
        product.id.contains("annual")
    }
    var body: some View {
        
        Button(action: onSelect) {
            HStack{
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .bold()
                            .foregroundStyle(theme.textPrimary)
                        
                        if let trialLength {
                            Text("\(trialLength.uppercased()) FREE")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.themeAccent)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        } else if isAnnual {
                            Text("SAVE Almost 80%")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let trialLength {
                        Text("\(trialLength) free")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(theme.textPrimary)
                        Text("then \(product.displayPrice)\(renewalSuffix ?? "")")
                            .font(.caption2)
                            .foregroundStyle(theme.textSecondary)
                    } else {
                        Text(product.displayPrice)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(theme.textPrimary)
                        
                        if let renewalSuffix {
                            Text(renewalSuffix)
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(theme.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        
    }
}

#Preview {
    PaywallView()
}
