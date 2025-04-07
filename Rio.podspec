#
# Be sure to run `pod lib lint Rio.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Rio'
  s.version          = '0.0.63'
  s.summary          = 'An iOS SDK for seamless integration with Retter’s Rio backend.'
  s.description      = <<-DESC
Rio is an SDK that simplifies integrating Retter’s Rio platform into your iOS app.
                       DESC

  s.homepage         = 'https://github.com/rettersoft/rio-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Baran Baygan' => 'baran@rettermobile.com' }
  s.source           = { :git => 'https://github.com/rettersoft/rio-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'Rio/Classes/**/*'
  
  s.resource_bundles = {
    'RioBundle' => [
        '**/Assets/*'
    ]
  }

  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.swift_version = '5.0'
  
  s.static_framework = true
  
  s.dependency 'Moya', '~> 14.0'
  s.dependency 'Alamofire', '~> 5.9.0'
  s.dependency 'KeychainSwift', '~> 22.0'
  s.dependency 'JWTDecode', '~> 2.4'
  s.dependency 'Firebase', '~> 11.11.0'
  s.dependency 'Firebase/Firestore', '~> 11.11.0'
  s.dependency 'Firebase/Auth', '~> 11.11.0'

end
