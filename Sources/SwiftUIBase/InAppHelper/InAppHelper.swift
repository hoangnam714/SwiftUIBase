//
//  InAppHelper.swift
//  SwiftUIBase
//
//  Created by Aland on 12/5/26.
//

import Foundation
import StoreKit
import SwiftyStoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletion = (Result<[SKProduct], Error>) -> Void
public typealias PurchaseCompletion = (Result<SKProduct?, Error>) -> Void
public typealias RestoreCompletion = (Result<[String], Error>) -> Void
public typealias IntCompletion = (Result<Int, Error>) -> Void

public enum IAPError: Error, LocalizedError {
    case nothingToRestore

    public var errorDescription: String? {
        switch self {
        case .nothingToRestore: return "Nothing to restore"
        }
    }
}

public enum IAPPurchaseError: Error, LocalizedError {
    case unknown, clientInvalid, paymentCancelled, paymentInvalid, paymentNotAllowed
    case storeProductNotAvailable, cloudServicePermissionDenied
    case cloudServiceNetworkConnectionFailed, cloudServiceRevoked, deferred
    case other(Error)

    public var errorDescription: String? {
        switch self {
        case .unknown: return "Unknown error. Please contact support"
        case .clientInvalid: return "Not allowed to make the payment"
        case .paymentCancelled: return "Payment Cancelled"
        case .paymentInvalid: return "The purchase identifier was invalid"
        case .paymentNotAllowed: return "The device is not allowed to make the payment"
        case .storeProductNotAvailable: return "The product is not available in the current storefront"
        case .cloudServicePermissionDenied: return "Access to cloud service information is not allowed"
        case .cloudServiceNetworkConnectionFailed: return "Could not connect to the network"
        case .cloudServiceRevoked: return "User has revoked permission to use this cloud service"
        case .deferred: return "Purchase is pending approval (Ask to Buy / Family Sharing)"
        case .other(let err): return err.localizedDescription
        }
    }

    public static func from(_ error: Error) -> IAPPurchaseError {
        guard let sk = error as? SKError else { return .other(error) }
        switch sk.code {
        case .unknown: return .unknown
        case .clientInvalid: return .clientInvalid
        case .paymentCancelled: return .paymentCancelled
        case .paymentInvalid: return .paymentInvalid
        case .paymentNotAllowed: return .paymentNotAllowed
        case .storeProductNotAvailable: return .storeProductNotAvailable
        case .cloudServicePermissionDenied: return .cloudServicePermissionDenied
        case .cloudServiceNetworkConnectionFailed: return .cloudServiceNetworkConnectionFailed
        case .cloudServiceRevoked: return .cloudServiceRevoked
        default: return .other(sk)
        }
    }
}

@MainActor
public final class InappHelper {
    public static let shared = InappHelper()

    public struct IAPProduct: Equatable, Hashable {
        public let id: ProductIdentifier
        public let displayNameKey: String
        
        public init(id: ProductIdentifier, displayNameKey: String) {
            self.id = id
            self.displayNameKey = displayNameKey
        }
    }
    
    /// Product list must be provided by the host app before using this helper.
    public var products: [IAPProduct] = []

    /// App-specific shared secret from App Store Connect (Subscriptions → App-Specific Shared Secret).
    public var sharedSecret: String = ""

    private let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
    
    private var didCallFinishPendingTransactions = false

    private init() {}

    // MARK: - Fetch product metadata

    public func requestProducts(completion: @escaping ProductsRequestCompletion) {
        validateProductsConfigured()
        validateFinishPendingTransactionsCalled()
        let subscriptionIDs = Set(products.map(\.id))
        SwiftyStoreKit.retrieveProductsInfo(subscriptionIDs) { result in
            if let error = result.error {
                completion(.failure(error))
            } else {
                let products = Array(result.retrievedProducts)
                    .sorted { $0.price.compare($1.price) == .orderedAscending }
                completion(.success(products))
            }
        }
    }

    /// Paywall rows and product lookup, in `IAPProduct` enum order.
    public func makePackageDescriptions(from products: [SKProduct]) -> (packages: [PackageDescription], productsByID: [String: SKProduct]) {
        validateProductsConfigured()
        validateFinishPendingTransactionsCalled()
        var map: [String: SKProduct] = [:]
        map.reserveCapacity(products.count)
        for p in products {
            map[p.productIdentifier] = p
        }
        var packs: [PackageDescription] = []
        for kind in self.products {
            guard let p = map[kind.id] else { continue }
            packs.append(
                PackageDescription(
                    productID: p.productIdentifier,
                    name: periodDisplayName(for: kind),
                    type: kind,
                    price: localizedPrice(for: p),
                    subtitle: "",
                    newSubtitle: "",
                    numberOfUnits: introductoryFreeTrialDayCount(for: p)
                )
            )
        }
        return (packs, map)
    }

    // MARK: - Purchase

    public func purchase(productId: String, completion: @escaping PurchaseCompletion) {
        validateProductsConfigured()
        validateFinishPendingTransactionsCalled()
        SwiftyStoreKit.purchaseProduct(productId, quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                completion(.success(purchase.product))
            case .error(let error):
                completion(.failure(IAPPurchaseError.from(error)))
            case .deferred:
                completion(.failure(IAPPurchaseError.deferred))
            @unknown default:
                completion(.failure(IAPPurchaseError.unknown))
            }
        }
    }

    // MARK: - Finish pending transactions

    public func finishPendingTransactions(completion: IntCompletion? = nil) {
        validateProductsConfigured()
        didCallFinishPendingTransactions = true
        var finishedCount = 0
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for p in purchases {
                switch p.transaction.transactionState {
                case .purchased, .restored:
                    if p.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(p.transaction)
                        finishedCount += 1
                    }
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
            completion?(.success(finishedCount))
        }
    }

    // MARK: - Restore

    public func restorePurchasedProducts(completion: @escaping RestoreCompletion) {
        validateProductsConfigured()
        validateFinishPendingTransactionsCalled()
        let subscriptionIDs = Set(products.map(\.id))
        SwiftyStoreKit.restorePurchases(atomically: true) { [weak self] results in
            guard let self else { return }
            if let firstError = results.restoreFailedPurchases.first?.0 {
                completion(.failure(firstError))
                return
            }
            let validator = AppleReceiptValidator(service: .production, sharedSecret: self.sharedSecret)
            SwiftyStoreKit.verifyReceipt(using: validator, forceRefresh: true) { result in
                switch result {
                case .success(let receipt):
                    let activeIds: [String]
                    if case .purchased(_, let items) = SwiftyStoreKit.verifySubscriptions(
                        ofType: .autoRenewable,
                        productIds: subscriptionIDs,
                        inReceipt: receipt
                    ) {
                        activeIds = items.map(\.productId)
                    } else {
                        activeIds = []
                    }
                    if activeIds.isEmpty {
                        completion(.failure(IAPError.nothingToRestore))
                    } else {
                        completion(.success(activeIds))
                    }
                case .error(let err):
                    completion(.failure(err))
                @unknown default:
                    completion(.failure(IAPError.nothingToRestore))
                }
            }
        }
    }

    // MARK: - Private

    private func localizedPrice(for product: SKProduct) -> String {
        currencyFormatter.locale = product.priceLocale
        return currencyFormatter.string(from: product.price) ?? ""
    }

    private func periodDisplayName(for kind: IAPProduct) -> String {
        NSLocalizedString(kind.displayNameKey, comment: "Subscription period")
    }

    private func introductoryFreeTrialDayCount(for product: SKProduct) -> Int? {
        guard let intro = product.introductoryPrice, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        let n = period.numberOfUnits
        switch period.unit {
        case .day: return n
        case .week: return n * 7
        case .month: return n * 30
        case .year: return n * 365
        @unknown default: return n
        }
    }
    
    private func validateProductsConfigured() {
        if products.isEmpty {
            fatalError("InappHelper.products is empty. Configure it in AppDelegate before using InappHelper.")
        }
    }
    
    private func validateFinishPendingTransactionsCalled() {
        if !didCallFinishPendingTransactions {
            fatalError("finishPendingTransactions() must be called in AppDelegate before using other InappHelper APIs.")
        }
    }
}

// MARK: - Paywall UI model

public struct PackageDescription: Identifiable, Equatable {
    public var id: String { productID }
    public var productID: String
    public var name: String
    public var type: InappHelper.IAPProduct
    public var price: String
    public var subtitle: String
    public var newSubtitle: String
    public var numberOfUnits: Int?
}

