Pod::Spec.new do |s|
  s.name         = 'QonversionSandwich'
  s.version      = '7.4.0'
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
    "osx" => "10.15"
  }
  s.source_files = 'ios/sandwich/**/*.{h,m,swift}'
  s.dependency "Qonversion", "6.5.0"
  s.module_name = 'QonversionSandwich'
end
