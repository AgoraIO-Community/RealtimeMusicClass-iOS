#
# Be sure to run `pod lib lint AgoraViewKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AgoraViewKit'
  s.version          = '0.1.0.0'
  s.summary          = 'A short description of AgoraViewKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/HeZhengQing/AgoraViewKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'HeZhengQing' => 'hezhengqing@agora.io' }
  s.source           = { :git => 'https://github.com/HeZhengQing/AgoraViewKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'AgoraViewKit/Classes/**/*'
  s.dependency 'SwifterSwift'
  s.dependency 'SnapKit'
  
  s.subspec "Resources" do |ss|
    ss.resource_bundles = {
      'AgoraViewKit' => ['AgoraViewKit/Assets/**/*.{xcassets,strings,gif,mp3}']
    }
  end
  
end
