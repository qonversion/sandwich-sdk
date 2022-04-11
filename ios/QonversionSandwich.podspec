Pod::Spec.new do |s|
  s.name         = 'QonversionSandwich'
  s.version      = '0.0.1'
  s.summary      = 'qonversion.io'
  s.description  = <<-DESC
  Qonversion Sandwich SDK is used for bridging in cross-platform SDKs. It is intended for internal purposes only.
  DESC
  s.homepage     = 'https://github.com/qonversion/qonversion-ios-sdk'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Qonversion Inc.' => 'hi@qonversion.io' }
  s.source       = { :git => 'https://github.com/qonversion/qonversion-ios-sdk.git', :tag => 'develop' }
  s.platforms    = { :ios => "9.0" }

  s.default_subspecs = 'Main'

  s.subspec 'Main' do |ss|
    ss.source_files = '**/sandwich/**/*.{h,m,swift}'
  end

  s.dependency "Qonversion", "2.18.3"
end
