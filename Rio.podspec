#
# Be sure to run `pod lib lint Rio.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Rio'
  s.version          = '0.0.29'
  s.summary          = 'A short description of Rio.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/rettersoft/rio-ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Baran Baygan' => 'baran@rettermobile.com' }
  s.source           = { :git => 'https://github.com/rettersoft/rio-ios-sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Rio/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Rio' => ['Rio/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.static_framework = true
  
  s.dependency 'Moya', '~> 14.0'
  s.dependency 'Alamofire', '~> 5.2'
  s.dependency 'ObjectMapper', '~> 3.4'
  s.dependency 'KeychainSwift', '~> 19.0'
  s.dependency 'JWTDecode', '~> 2.4'
  s.dependency 'TrustKit'
  s.dependency 'Firebase', '~> 8.11.0'
  s.dependency 'Firebase/Firestore', '~> 8.11.0'
  s.dependency 'Firebase/Auth', '~> 8.11.0'

  
  
end
