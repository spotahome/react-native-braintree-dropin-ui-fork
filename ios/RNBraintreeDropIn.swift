import Foundation
import React
import Braintree

/// Braintree payments native module.
///
/// This replaces the previous `BraintreeDropIn` integration on iOS. Drop-in 9.x is
/// hard-pinned to `Braintree ~> 5.27`, and Braintree 5.x fails to compile once the
/// iOS deployment target reaches 15 (`UIApplication.windows` is deprecated there and
/// Braintree ships `-Werror`). That pin is what kept the app on an older Expo/RN.
/// Dropping Drop-in frees us to build against Braintree 6.x, where that code is gone.
///
/// Written in Swift deliberately: Braintree 6.x is Swift-first and several of the
/// PayPal types (e.g. `BTPayPalRecurringBillingPlanType`) are plain Swift enums that
/// are not representable in Objective-C, so `BTPayPalVaultRequest`'s designated
/// initializer does not bridge. Objective-C would mean guessing at bridged selectors.
@objc(RNBraintreeDropIn)
class RNBraintreeDropIn: NSObject {

    /// `BTPayPalClient` owns the `ASWebAuthenticationSession` driving the PayPal
    /// browser switch. If it deallocates mid-flow the session is torn down and the
    /// completion never fires, so it is retained until the flow finishes.
    private var payPalClient: BTPayPalClient?

    /// Retained for the duration of the tokenization request for the same reason.
    private var cardClient: BTCardClient?

    @objc static func requiresMainQueueSetup() -> Bool {
        false
    }

    // MARK: - PayPal

    /// Tokenizes a PayPal account through the PayPal Vault flow and resolves
    /// `{ nonce, type, description }`.
    ///
    /// No native payment UI is presented beyond PayPal's own web authentication
    /// sheet. The card-vs-PayPal choice is made in the app's own JS UI before this
    /// is called, so the Drop-in sheet it replaces was a redundant second tap.
    @objc(tokenizePayPal:resolver:rejecter:)
    func tokenizePayPal(
        _ clientToken: String,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let apiClient = BTAPIClient(authorization: clientToken) else {
            reject("INVALID_CLIENT_TOKEN", "The client token seems invalid", nil)
            return
        }

        let client = BTPayPalClient(apiClient: apiClient)
        payPalClient = client

        client.tokenize(BTPayPalVaultRequest()) { [weak self] nonce, error in
            self?.payPalClient = nil

            if let error {
                // Keeps the code the Drop-in implementation used, so the app's
                // existing cancellation branch keeps working untouched.
                if let payPalError = error as? BTPayPalError, payPalError == .canceled {
                    reject("USER_CANCELLATION", "The user cancelled", nil)
                } else {
                    reject("PAYPAL_TOKENIZATION_FAILED", error.localizedDescription, error)
                }
                return
            }

            guard let nonce else {
                reject("PAYPAL_NO_NONCE", "PayPal returned no payment method nonce", nil)
                return
            }

            resolve([
                "nonce": nonce.nonce,
                "type": nonce.type,
                // Drop-in exposed the PayPal account email as `paymentDescription`;
                // the app renders this in the saved-payment-method row.
                "description": nonce.email ?? "PayPal"
            ])
        }
    }

    // MARK: - Cards

    /// Tokenizes raw card details and resolves the resulting nonce string.
    ///
    /// Unchanged in contract from the previous implementation. Note this performs no
    /// 3D Secure verification — see README before using it for a custom card form.
    @objc(tokenizeCard:info:resolver:rejecter:)
    func tokenizeCard(
        _ clientToken: String,
        info cardInfo: [String: Any],
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        guard
            let number = cardInfo["number"] as? String,
            let expirationMonth = cardInfo["expirationMonth"] as? String,
            let expirationYear = cardInfo["expirationYear"] as? String,
            let cvv = cardInfo["cvv"] as? String,
            let postalCode = cardInfo["postalCode"] as? String
        else {
            reject("INVALID_CARD_INFO", "Invalid card info", nil)
            return
        }

        guard let apiClient = BTAPIClient(authorization: clientToken) else {
            reject("INVALID_CLIENT_TOKEN", "The client token seems invalid", nil)
            return
        }

        let card = BTCard()
        card.number = number
        card.expirationMonth = expirationMonth
        card.expirationYear = expirationYear
        card.cvv = cvv
        card.postalCode = postalCode

        let client = BTCardClient(apiClient: apiClient)
        cardClient = client

        client.tokenize(card) { [weak self] nonce, error in
            self?.cardClient = nil

            guard let nonce else {
                reject("TOKENIZE_ERROR", error?.localizedDescription ?? "Error tokenizing card.", error)
                return
            }

            resolve(nonce.nonce)
        }
    }
}
