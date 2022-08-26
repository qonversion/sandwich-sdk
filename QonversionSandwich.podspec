Pod::Spec.new do |s|
  excluded_files = ['ios/sandwich/AutomationsSandwich.swift', 'ios/sandwich/AutomationsEventListener.swift', 'ios/sandwich/AutomationsMappers.swift']
  s.name         = 'QonversionSandwich'
  s.version      = '0.0.7'
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
  s.platforms    = { :ios => "9.0", :osx => "10.12", :tvos => "9.0", :watchos => "6.2" }
  
  s.osx.exclude_files         = excluded_files
  s.tvos.exclude_files        = excluded_files
  s.watchos.exclude_files     = excluded_files

  s.source_files = 'ios/sandwich/**/*.{h,m,swift}'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.dependency "Qonversion", "2.20.0"
end
