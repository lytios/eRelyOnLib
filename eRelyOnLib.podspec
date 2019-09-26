#
# Be sure to run `pod lib lint eRelyOnLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'eRelyOnLib'
  s.version          = '0.1.0'
  s.summary          = 'A short description of eRelyOnLib.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/lytios/eRelyOnLib'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '24290265@qq.com' => '24290265@qq.com' }
  s.source           = { :git => 'https://github.com/lytios/eRelyOnLib.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.ios.vendored_frameworks = 'eRelyOnLib/Classes/framework/MGFaceIDLiveDetect.framework','eRelyOnLib/Classes/framework/MGFaceIDBaseKit.framework'
  
  #s.vendored_framework = 'eHRFaceSDK/Classes/HRFaceSDK.framework'

  s.resources = 'eRelyOnLib/Assets/*.*'
  s.libraries = 'c++'
  #s.vendored_libraries = 'eRelyOnLib/Classes/framework/libBHFaceDetector.a'
 # s.vendored_frameworks =  'SystemConfiguration.framework','CoreMotion.framework','AVFoundation.framework','CoreMedia.framework'
  s.xcconfig = {'OTHER_LDFLAGS'=>'$(inherited)-ObjC','ENABLE_BITCONDE'  =>'NO','HEADER_SEARCH_PATHS' => '${SDK_DIR}/usr/include/libc++' }
s.subspec 'Tool' do |t|
  #s.source_files = 'eRelyOnLib/Classes/file/*'
end
  
  s.dependency 'AFNetworking'
  s.dependency 'SDWebImage'
  s.dependency 'MBProgressHUD'
  s.dependency 'IQKeyboardManager'
  s.dependency 'NIMSDK'
  s.dependency 'Masonry'
  s.dependency 'MJRefresh'
  s.dependency 'MJExtension'
  s.dependency 'eCameraLib'
  s.dependency 'WPAttributedMarkup'
end
