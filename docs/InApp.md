# In-App Purchase (`InappHelper`)

Subscription helper built on [SwiftyStoreKit](https://github.com/bizz84/SwiftyStoreKit), shared across paywall and restore flows.

## Requirements

- iOS app target (StoreKit)
- Product IDs created in App Store Connect
- **App-Specific Shared Secret** (Subscriptions → App-Specific Shared Secret) — required for restore/receipt verification

## Required configuration

Accessing `InappHelper.shared` alone does **not** crash. Validation runs when you call a public API.

| Step | Required | When checked | What happens if skipped |
|------|----------|--------------|-------------------------|
| Set `helper.products` | **Yes** | Every public API | `fatalError`: *"InappHelper.products is empty. Configure it in AppDelegate before using InappHelper."* |
| Call `finishPendingTransactions()` | **Yes** | `requestProducts`, `makePackageDescriptions`, `purchase`, `restorePurchasedProducts` | `fatalError`: *"finishPendingTransactions() must be called in AppDelegate before using other InappHelper APIs."* |
| Set `helper.sharedSecret` | **Yes** (for restore) | `restorePurchasedProducts()` only | No `fatalError` — restore completes with an error in the completion handler |

**Rule:** After `let helper = InappHelper.shared`, assign `helper.products` with at least one entry **before** calling any API (including `finishPendingTransactions()`). An empty `products` array crashes immediately on the first API call.

**Note:** `sharedSecret` defaults to `""`. There is no `fatalError` for a missing secret today — only `restorePurchasedProducts()` uses it, and verification fails via the completion callback instead.

Call setup **once** at app launch (typically in `AppDelegate` or `@main` App init):

```swift
import SwiftUIBase

func configureInApp() {
    let helper = InappHelper.shared

    // REQUIRED — must not be empty; order defines paywall display order
    helper.products = [
        .init(id: "com.yourapp.weekly", displayNameKey: "iap_weekly"),
        .init(id: "com.yourapp.monthly", displayNameKey: "iap_monthly"),
        .init(id: "com.yourapp.yearly", displayNameKey: "iap_yearly"),
    ]

    // REQUIRED — App-Specific Shared Secret from App Store Connect
    helper.sharedSecret = "your_app_specific_shared_secret"

    // REQUIRED — must be called before any other InappHelper API
    helper.finishPendingTransactions { result in
        switch result {
        case .success(let count):
            print("Finished \(count) pending transaction(s)")
        case .failure(let error):
            print("finishPendingTransactions error: \(error)")
        }
    }
}
```

`displayNameKey` is a localization key (e.g. `"iap_weekly"` → `"Weekly"` in `Localizable.strings`).

## Basic flow

```
App launch
    └── configureInApp()          // products + sharedSecret + finishPendingTransactions
Paywall opens
    └── requestProducts()         // fetch SKProduct from App Store
    └── makePackageDescriptions() // map to PackageDescription for UI
User selects a plan
    └── purchase(productId:)      // purchase subscription
User taps Restore
    └── restorePurchasedProducts() // verify receipt, return active product IDs
```

## 1. Fetch products

```swift
InappHelper.shared.requestProducts { result in
    switch result {
    case .success(let skProducts):
        let (packages, productsByID) = InappHelper.shared.makePackageDescriptions(from: skProducts)
        // packages: [PackageDescription] — use to render paywall
        // productsByID: [String: SKProduct] — lookup by product ID
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

`PackageDescription` fields:

| Field | Description |
|-------|-------------|
| `productID` | Product identifier |
| `name` | Display name (localized via `displayNameKey`) |
| `type` | Matching `InappHelper.IAPProduct` |
| `price` | Locale-formatted price (e.g. `"$4.99"`) |
| `numberOfUnits` | Free trial length in days, if available; otherwise `nil` |
| `subtitle`, `newSubtitle` | Optional copy — assign in your UI layer |

## 2. Purchase subscription

```swift
InappHelper.shared.purchase(productId: "com.yourapp.monthly") { result in
    switch result {
    case .success(let product):
        // Purchase succeeded — unlock premium
        print("Purchased: \(product?.productIdentifier ?? "")")
    case .failure(let error as IAPPurchaseError):
        switch error {
        case .paymentCancelled:
            break // User cancelled — no alert needed
        default:
            print(error.localizedDescription)
        }
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

## 3. Restore purchases

```swift
InappHelper.shared.restorePurchasedProducts { result in
    switch result {
    case .success(let activeProductIDs):
        // activeProductIDs: subscriptions still active
        unlockPremium(for: activeProductIDs)
    case .failure(IAPError.nothingToRestore):
        print("Nothing to restore")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

Restore flow:
1. Calls `SwiftyStoreKit.restorePurchases`
2. Verifies production receipt with `sharedSecret` (must be set beforehand)
3. Checks active auto-renewable subscriptions
4. Returns list of active product IDs

## Paywall ViewModel example

```swift
@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var packages: [PackageDescription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var productsByID: [String: SKProduct] = [:]

    func loadProducts() {
        isLoading = true
        InappHelper.shared.requestProducts { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let skProducts):
                    let mapped = InappHelper.shared.makePackageDescriptions(from: skProducts)
                    self.packages = mapped.packages
                    self.productsByID = mapped.productsByID
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func purchase(_ package: PackageDescription) {
        InappHelper.shared.purchase(productId: package.productID) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    // Navigate or dismiss paywall
                    break
                case .failure(let error as IAPPurchaseError):
                    switch error {
                    case .paymentCancelled:
                        break
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func restore() {
        InappHelper.shared.restorePurchasedProducts { result in
            Task { @MainActor in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

## Error handling

### `IAPPurchaseError`

| Case | Meaning |
|------|---------|
| `paymentCancelled` | User dismissed the payment sheet |
| `paymentNotAllowed` | Device or parental controls block IAP |
| `storeProductNotAvailable` | Product unavailable in current storefront |
| `deferred` | Ask to Buy — awaiting approval |
| `other(Error)` | Other StoreKit error |

### `IAPError`

| Case | Meaning |
|------|---------|
| `nothingToRestore` | Receipt has no active subscription |

## Integration checklist

- [ ] Create subscription products in App Store Connect
- [ ] Assign product IDs to `InappHelper.shared.products` **before any other API call**
- [ ] Add localization keys for each `displayNameKey`
- [ ] Set `sharedSecret` from App Store Connect
- [ ] Call `finishPendingTransactions()` at app launch
- [ ] Test with a sandbox account
- [ ] Handle `paymentCancelled` silently (no error alert)
