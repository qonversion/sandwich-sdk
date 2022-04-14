Pod::Spec.new do |s|
  s.name         = 'QonversionSandwich'
  s.version      = '0.0.1'
  s.summary      = 'qonversion.io'
  s.swift_version = '5.0'
  s.description  = <<-DESC
  Qonversion Sandwich SDK is used for bridging in cross-platform SDKs. It is intended for internal purposes only.
  DESC
  s.homepage     = 'https://github.com/qonversion/sandwich-sdk'
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { 'Qonversion Inc.' => 'hi@qonversion.io' }
  s.source       = { :git => 'https://github.com/qonversion/sandwich-sdk.git', :tag => s.version.to_s }
  s.platforms    = { :ios => "9.0" }

  s.source_files = 'ios/sandwich/**/*.{h,m,swift}'

  s.dependency "Qonversion", "2.18.3"
end
