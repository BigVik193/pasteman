import StoreKit
import Foundation
import Combine

@MainActor
class InAppPurchaseManager: NSObject, ObservableObject {
    static let shared = InAppPurchaseManager()
    
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    
    private let productIds = ["com.vikrambattalapalli.coffee"]
    
    enum PurchaseState {
        case idle
        case loading
        case purchased
        case failed(Error)
    }
    
    override init() {
        super.init()
        Task {
            await requestProducts()
            await listenForTransactions()
        }
    }
    
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIds)
            
            await MainActor.run {
                self.products = storeProducts
            }
            
            if storeProducts.isEmpty {
                print("Warning: No products were loaded. Check your product IDs and App Store Connect configuration.")
            } else {
                print("Successfully loaded \(storeProducts.count) products: \(storeProducts.map { $0.id })")
            }
            
        } catch {
            print("Failed to load products: \(error)")
            
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .networkError:
                    print("Network error loading products - check internet connection")
                case .systemError:
                    print("System error loading products - try again later")
                default:
                    print("StoreKit error: \(storeKitError)")
                }
            }
        }
    }
    
    func purchase(_ product: Product) async {
        purchaseState = .loading
        
        do {
            // Ensure app is active for purchase dialog
            await MainActor.run {
                NSApp.activate(ignoringOtherApps: true)
            }
            
            // For macOS 13+, use standard purchase method
            // UI context is handled automatically by the system
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Deliver content before finishing transaction
                await deliverPurchase(for: transaction)
                await transaction.finish()
                
                purchaseState = .purchased
                showThankYouAlert()
                
            case .userCancelled:
                purchaseState = .idle
                print("User cancelled purchase")
                
            case .pending:
                purchaseState = .idle
                print("Purchase is pending - family approval required")
                
            @unknown default:
                purchaseState = .idle
                print("Unknown purchase result")
            }
        } catch {
            purchaseState = .failed(error)
            print("Purchase error: \(error)")
            
            // More specific error handling
            if let storeError = error as? StoreKitError {
                switch storeError {
                case .networkError:
                    showErrorAlert("Network error. Please check your internet connection and try again.")
                case .systemError:
                    showErrorAlert("System error. Please try again later.")
                case .notAvailableInStorefront:
                    showErrorAlert("This purchase is not available in your region.")
                case .notEntitled:
                    showErrorAlert("You're not entitled to make this purchase.")
                default:
                    showErrorAlert("Purchase failed: \(error.localizedDescription)")
                }
            } else {
                showErrorAlert("Purchase failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func deliverPurchase(for transaction: Transaction) async {
        // Validate the transaction is legitimate
        guard transaction.environment == .production || transaction.environment == .sandbox else {
            print("Invalid transaction environment")
            return
        }
        
        // Record purchase in your system
        print("Delivering purchase for product: \(transaction.productID)")
        
        // Here you would typically:
        // 1. Grant premium features
        // 2. Update user's purchase status
        // 3. Sync with your backend if you have one
    }
    
    func buyCoffee() async {
        guard let coffeeProduct = products.first(where: { $0.id == "com.vikrambattalapalli.coffee" }) else {
            // Try to reload products
            await requestProducts()
            
            guard let coffeeProduct = products.first(where: { $0.id == "com.vikrambattalapalli.coffee" }) else {
                showErrorAlert("Product not available. Please try again later.")
                return
            }
            
            await purchase(coffeeProduct)
            return
        }
        
        await purchase(coffeeProduct)
    }
    
    func restorePurchases() async {
        do {
            // Sync the latest transaction data from the App Store
            try await AppStore.sync()
            
            // Process any unfinished transactions
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Restore the purchase
                    await deliverPurchase(for: transaction)
                    
                    print("Restored purchase: \(transaction.productID)")
                    
                    await MainActor.run {
                        self.purchaseState = .purchased
                    }
                    
                } catch {
                    print("Failed to verify restored transaction: \(error)")
                }
            }
            
            print("Purchase restoration completed")
            
        } catch {
            print("Failed to restore purchases: \(error)")
            showErrorAlert("Failed to restore purchases: \(error.localizedDescription)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                
                // Handle different transaction types (macOS 13+ compatible)
                switch transaction.productType {
                case .consumable:
                    print("Processing consumable purchase: \(transaction.productID)")
                    await deliverPurchase(for: transaction)
                case .nonConsumable:
                    print("Processing non-consumable purchase: \(transaction.productID)")
                    await deliverPurchase(for: transaction)
                case .autoRenewable:
                    print("Processing auto-renewable subscription: \(transaction.productID)")
                    await deliverPurchase(for: transaction)
                case .nonRenewable:
                    print("Processing non-renewable subscription: \(transaction.productID)")
                    await deliverPurchase(for: transaction)
                default:
                    print("Unknown product type for transaction: \(transaction.productID)")
                    await deliverPurchase(for: transaction)
                }
                
                // Always finish the transaction after processing
                await transaction.finish()
                
                // Update UI state
                await MainActor.run {
                    self.purchaseState = .purchased
                }
                
            } catch {
                print("Failed to process transaction update: \(error)")
            }
        }
    }
    
    private func showThankYouAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Thank You! ☕️"
            alert.informativeText = "Thanks for supporting Pasteman development! Your contribution helps keep the app free and improving."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "You're Welcome!")
            alert.runModal()
        }
    }
    
    private func showErrorAlert(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Purchase Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

enum StoreError: Error {
    case failedVerification
    case noUIContext
    case productNotFound
    case networkUnavailable
}