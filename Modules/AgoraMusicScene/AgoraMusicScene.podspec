#
# Be sure to run `pod lib lint AgoraMusicScene.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AgoraMusicScene'
  s.version          = '0.1.0.0'
  s.summary          = 'A short description of AgoraMusicScene.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/HeZhengQing/AgoraMusicScene'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'HeZhengQing' => 'hezhengqing@agora.io' }
  s.source           = { :git => 'https://github.com/HeZhengQing/AgoraMusicScene.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'AgoraMusicScene/Classes/**/*'
  
  s.dependency 'SwifterSwift'
  s.dependency 'SnapKit'
  s.dependency 'AgoraMusicEngine'
  s.dependency 'Zip' # 歌词组件
  s.dependency 'AgoraSceneEntranceModule'
  s.dependency 'AgoraViewKit'
  s.dependency 'Whiteboard'
  
  s.subspec "Chorus" do |ss|
    ss.source_files = 'AgoraMusicScene/Classes/Chorus/**/*.swift'
    
  end
  
  s.subspec "Ensemble" do |ss|
    ss.source_files = 'AgoraMusicScene/Classes/Ensemble/**/*.swift'
    
  end
  
  s.subspec "Practice" do |ss|
    ss.source_files = 'AgoraMusicScene/Classes/Practice/**/*.swift'
  end
  
  s.subspec "Resources" do |ss|
    ss.resource_bundles = {
      "AgoraMusicScene" => ['AgoraMusicScene/Assets/**/*.{xcassets,strings,gif,mp3,lrc,xml,json}']
    }
  end
  
end
