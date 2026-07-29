import { NativeModules, Platform } from 'react-native';

const { RNBraintreeDropIn } = NativeModules;

/**
 * Drop-in options that reduce the sheet to a single PayPal button — i.e. exactly
 * what the iOS implementation now does natively, without any Braintree UI.
 * Used so the JS contract stays identical across platforms while Android is still
 * on Drop-in.
 */
const PAYPAL_ONLY_DROPIN_OPTIONS = {
  cardDisabled: true,
  googlePay: false,
  applePay: false,
  vaultManager: false,
  payPal: true,
  darkTheme: true
};

const IOS_SHOW_REMOVED_MESSAGE =
  'BraintreeDropIn.show() is not available on iOS: the Braintree Drop-in SDK has ' +
  'been removed because it pins Braintree to 5.x. Use tokenizePayPal() for PayPal; ' +
  'card payments go through Stripe.';

export default {
  ...RNBraintreeDropIn,

  /**
   * Tokenize a PayPal account via the PayPal Vault flow.
   *
   * Resolves `{ nonce, type, description }`. Rejects with code `USER_CANCELLATION`
   * if the user backs out — the same code the Drop-in implementation used, so
   * existing error handling needs no changes.
   *
   * iOS calls Braintree's PayPal client directly (no Drop-in sheet — the
   * card/PayPal choice is already made in the app's own UI). Android still routes
   * through Drop-in with everything but PayPal disabled, which renders the same
   * single-button sheet. Migrating Android to a native PayPal client later needs no
   * JS change.
   *
   * @param {string} clientToken
   * @returns {Promise<{ nonce: string, type: string, description: string }>}
   */
  tokenizePayPal: clientToken =>
    Platform.OS === 'ios'
      ? RNBraintreeDropIn.tokenizePayPal(clientToken)
      : RNBraintreeDropIn.show({ clientToken, ...PAYPAL_ONLY_DROPIN_OPTIONS }),

  /**
   * Present the Braintree Drop-in UI. Android only — see `tokenizePayPal`.
   */
  show: options => {
    if (Platform.OS === 'ios') {
      return Promise.reject(new Error(IOS_SHOW_REMOVED_MESSAGE));
    }

    return RNBraintreeDropIn.show(options);
  }
};
