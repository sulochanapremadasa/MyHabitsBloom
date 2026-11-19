//
//  ProManager.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-09-02.
//

import Foundation
import StoreKit
import SwiftUI
import Combine
import WidgetKit

/// Snapshot of the customer's active Pro entitlement, used by Settings to describe
/// the current plan and its renewal state.
struct ProEntitlement: Equatable {
    enum Plan: Equatable {
        case monthly
        case annual
        case lifetime
        
        /// Fallback plan name used when the App Store product hasn't loaded yet.
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }
    }
    
    let productID: String
    let plan: Plan
    /// When the current period ends. Nil for the Lifetime purchase, which never expires.
    let expirationDate: Date?
    /// True while the customer is inside the introductory free-trial period.
    let isFreeTrial: Bool
    /// False once the customer has turned off auto-renew in the App Store.
    let willAutoRenew: Bool
    
    var isLifetime: Bool { plan == .lifetime }
}

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    
    // Persist pro entitlement across the app
//    @AppStorage("isProUser") var isProUser: Bool = false
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Introductory offer eligibility keyed by product ID.
    /// StoreKit only grants the free trial to customers who have never used an
    /// introductory offer in the subscription group, so the paywall must check this
    /// before advertising the trial.
    @Published private(set) var introOfferEligibility: [String: Bool] = [:]
    
    /// Details of the entitlement that currently grants Pro, or nil when the customer isn't Pro.
    /// Lifetime takes precedence when the customer holds both Lifetime and a subscription.
    @Published private(set) var activeEntitlement: ProEntitlement?
    
    /// The auto-renewable subscription that is still active, even when Lifetime is the
    /// entitlement in use. Buying Lifetime does not cancel a subscription, and the app
    /// cannot cancel it on the customer's behalf, so Settings surfaces it for manual cancellation.
    @Published private(set) var activeSubscription: ProEntitlement?
    
    var hasActiveSubscription: Bool { activeSubscription != nil }
    
    /// Products the customer can sensibly buy right now. Lifetime is withheld while a
    /// subscription is active so the customer isn't billed for both.
    var purchasableProducts: [Product] {
        guard hasActiveSubscription else { return products }
        return products.filter { $0.id != lifetimeProductID }
    }
    
    @AppStorage("isProUser", store: UserDefaults(suiteName: "group.com.sulo.HabitBloom")) var isProUser: Bool = false {
        didSet {
            // Force WidgetKit to reload UI when Pro status changes
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private let lifetimeProductID = "com.sulo.HabitBloom.lifetimeV1"
    
    private let productIDs = [
        "com.sulo.HabitBloom.monthlyV1",
        "com.sulo.HabitBloom.annualV1",
        "com.sulo.HabitBloom.lifetimeV1"
    ]
    
    /// The loaded App Store product for a product ID, if products have been fetched.
    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }
    
    private var updatesTask: Task<Void, Never>? = nil

    init() {
        // Start listening for asynchronous App Store transaction updates (e.g. renewals, refunds, family sharing)
        updatesTask = listenForTransactions()
        
        Task {
            await updatePurchasedStatus()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            self.products = fetchedProducts.sorted { $0.price < $1.price }
            await refreshIntroOfferEligibility()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Introductory Offers
    
    /// Asks StoreKit whether the current customer can still redeem the introductory
    /// offer for each subscription product that has one configured.
    func refreshIntroOfferEligibility() async {
        var eligibility: [String: Bool] = [:]
        for product in products {
            guard let subscription = product.subscription,
                  subscription.introductoryOffer != nil else { continue }
            eligibility[product.id] = await subscription.isEligibleForIntroOffer
        }
        introOfferEligibility = eligibility
    }
    
    /// Returns the free-trial introductory offer for a product, but only when the
    /// customer is eligible to receive it. Returns nil for paid intro offers or
    /// when the customer has already used the trial.
    func eligibleFreeTrial(for product: Product) -> Product.SubscriptionOffer? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial,
              introOfferEligibility[product.id] == true else {
            return nil
        }
        return offer
    }
    
    /// Human readable trial length such as "3 days" or "1 week".
    func trialLengthText(for product: Product) -> String? {
        guard let offer = eligibleFreeTrial(for: product) else { return nil }
        let value = offer.period.value
        let unitName: String
        switch offer.period.unit {
        case .day: unitName = "day"
        case .week: unitName = "week"
        case .month: unitName = "month"
        case .year: unitName = "year"
        @unknown default: unitName = "period"
        }
        return "\(value) \(unitName)\(value == 1 ? "" : "s")"
    }
    
    /// Compact trial length for button labels, such as "3-Day".
    func trialLengthLabel(for product: Product) -> String? {
        guard let offer = eligibleFreeTrial(for: product) else { return nil }
        let unitName: String
        switch offer.period.unit {
        case .day: unitName = "Day"
        case .week: unitName = "Week"
        case .month: unitName = "Month"
        case .year: unitName = "Year"
        @unknown default: unitName = "Period"
        }
        return "\(offer.period.value)-\(unitName)"
    }
    
    /// Renewal period suffix such as "/month" or "/year" for a subscription product.
    func renewalPeriodSuffix(for product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return period.value == 1 ? "/day" : "/\(period.value) days"
        case .week: return period.value == 1 ? "/week" : "/\(period.value) weeks"
        case .month: return period.value == 1 ? "/month" : "/\(period.value) months"
        case .year: return period.value == 1 ? "/year" : "/\(period.value) years"
        @unknown default: return nil
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async -> Bool {
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedStatus()
                    // The trial is consumed once a subscription starts, so refresh eligibility.
                    await refreshIntroOfferEligibility()
                    return true
                case .unverified(_, let error):
                    errorMessage = "Verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            return isProUser
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Entitlement Verification
    func updatePurchasedStatus() async {
        var lifetimeTransaction: StoreKit.Transaction?
        var subscriptionTransaction: StoreKit.Transaction?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            guard productIDs.contains(transaction.productID) else {
                continue
            }

            // If the transaction was revoked, the entitlement is no longer valid
            if transaction.revocationDate != nil {
                continue
            }

            if transaction.productID == lifetimeProductID {
                lifetimeTransaction = transaction
            } else if let current = subscriptionTransaction {
                // Family Sharing can surface more than one subscription; keep the one that lasts longest.
                let currentExpiry = current.expirationDate ?? .distantPast
                let candidateExpiry = transaction.expirationDate ?? .distantPast
                if candidateExpiry > currentExpiry {
                    subscriptionTransaction = transaction
                }
            } else {
                subscriptionTransaction = transaction
            }
        }

        var subscription: ProEntitlement?
        if let subscriptionTransaction {
            subscription = await makeSubscriptionEntitlement(for: subscriptionTransaction)
        }

        // Lifetime wins over a subscription because it never expires.
        let entitlement: ProEntitlement?
        if let lifetimeTransaction {
            entitlement = ProEntitlement(
                productID: lifetimeTransaction.productID,
                plan: .lifetime,
                expirationDate: nil,
                isFreeTrial: false,
                willAutoRenew: false
            )
        } else {
            entitlement = subscription
        }

        activeSubscription = subscription
        activeEntitlement = entitlement

        let hasActivePro = entitlement != nil
        if self.isProUser != hasActivePro {
            self.isProUser = hasActivePro
        }
    }
    
    /// Builds the entitlement snapshot for an auto-renewable subscription, pulling the
    /// auto-renew preference from the signed renewal info for the subscription group.
    private func makeSubscriptionEntitlement(for transaction: StoreKit.Transaction) async -> ProEntitlement {
        // Assume renewal until the App Store tells us otherwise so we never show a false "Expires" warning.
        var willAutoRenew = true
        
        if let groupID = transaction.subscriptionGroupID,
           let statuses = try? await Product.SubscriptionInfo.status(for: groupID) {
            // Prefer the status entry for the product the customer is actually entitled to.
            let matchingStatus = statuses.first { status in
                guard case .verified(let renewalInfo) = status.renewalInfo else { return false }
                return renewalInfo.currentProductID == transaction.productID
            } ?? statuses.first
            
            if let matchingStatus, case .verified(let renewalInfo) = matchingStatus.renewalInfo {
                willAutoRenew = renewalInfo.willAutoRenew
            }
        }
        
        let plan: ProEntitlement.Plan = transaction.productID.hasSuffix(".annual") ? .annual : .monthly
        let isFreeTrial = transaction.offer?.paymentMode == StoreKit.Transaction.Offer.PaymentMode.freeTrial
        
        return ProEntitlement(
            productID: transaction.productID,
            plan: plan,
            expirationDate: transaction.expirationDate,
            isFreeTrial: isFreeTrial,
            willAutoRenew: willAutoRenew
        )
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    
                }
                await self.updatePurchasedStatus()
            }
        }
    }
}
