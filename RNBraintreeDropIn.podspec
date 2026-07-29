Pod::Spec.new do |s|
  s.name         = "RNBraintreeDropIn"
  s.version      = "2.0.0-rc.0"
  s.summary      = "RNBraintreeDropIn"
  s.description  = <<-DESC
                  React Native bridge for Braintree payments.
                  PayPal tokenization and card tokenization against Braintree iOS 6.x.
                  The deprecated BraintreeDropIn SDK is no longer used; see README.
                   DESC
  s.homepage     = "https://github.com/spotahome/react-native-braintree-dropin-ui-fork"
  s.license      = "MIT"
  s.author             = { "author" => "lagrange.louis@gmail.com" }

  # Braintree 6.x requires iOS 14.0. That is below the floor already set by modern
  # React Native / Expo (15.1), so it adds no constraint of its own.
  s.platform     = :ios, "14.0"
  s.source       = { :git => "https://github.com/spotahome/react-native-braintree-dropin-ui-fork.git", :tag => s.version.to_s }

  s.source_files  = "ios/**/*.{h,m,swift}"
  s.requires_arc  = true
  s.swift_version = "5.9"

  s.dependency    'React-Core'

  # Braintree 6.x only. BraintreeDropIn is deliberately absent: Drop-in 9.x pins
  # `Braintree ~> 5.27`, and Braintree 5.x does not compile at an iOS 15+ deployment
  # target. Cards go through Stripe in the app; PayPal uses BTPayPalClient directly.
  s.dependency    'Braintree/Core',   '~> 6.32'
  s.dependency    'Braintree/PayPal', '~> 6.32'
  s.dependency    'Braintree/Card',   '~> 6.32'
end
