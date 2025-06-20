Pod::Spec.new do |s|
  s.name         = 'QonversionSandwich'
  s.version      = '6.0.5'
  s.summary      = 'qonversion.io'
  s.swift_version = '5.0'
  s.description  = <<-DESC
  Qonversion Sandwich SDK is used for bridging in cross-platform SDKs. It is intended for internal purposes only.
  DESC
  s.homepage     = 'https://github.com/qonversion/sandwich-sdk'
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { 'Qonversion Inc.' => 'hi@qonversion.io' }
  s.source       = { :git => 'https://github.com/qonversion/sandwich-sdk.git', :tag => s.version.to_s }
  s.framework    = 'StoreKit'
  s.platforms    = {
    "ios" => "13.0",
    "osx" => "10.13"
  }
  s.source_files = 'ios/sandwich/**/*.{h,m,swift}'
  s.ios.dependency "NoCodes", "0.1.2"
  s.dependency "Qonversion", "5.13.3"
  s.module_name = 'QonversionSandwich'
end
