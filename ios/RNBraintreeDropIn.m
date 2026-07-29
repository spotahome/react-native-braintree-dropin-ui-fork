#import <React/RCTBridgeModule.h>

// Bridging shim only — the implementation lives in RNBraintreeDropIn.swift.
// The module name is kept as `RNBraintreeDropIn` so `NativeModules.RNBraintreeDropIn`
// and the app's Expo config plugin keep resolving without changes.
@interface RCT_EXTERN_MODULE(RNBraintreeDropIn, NSObject)

RCT_EXTERN_METHOD(tokenizePayPal:(NSString *)clientToken
                        resolver:(RCTPromiseResolveBlock)resolve
                        rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(tokenizeCard:(NSString *)clientToken
                            info:(NSDictionary *)cardInfo
                        resolver:(RCTPromiseResolveBlock)resolve
                        rejecter:(RCTPromiseRejectBlock)reject)

@end
