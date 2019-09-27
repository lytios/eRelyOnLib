

Pod::Spec.new do |s|
  s.name             = 'eRelyOnLibFile'
  s.version          = '1.0.7'
  s.summary          = 'A short description of eRelyOnLibFile.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/lytios/eRelyOnLib'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '24290265@qq.com' => '24290265@qq.com' }
  s.source           = { :git => 'https://github.com/lytios/eRelyOnLib.git', :tag => 'v1.0.7' }
  s.ios.deployment_target = '8.0'
  s.libraries = 'c++'
  s.source_files = 'eRelyOnLib/Classes/file/**/*'
  s.vendored_libraries = 'eRelyOnLib/Classes/framework/libBHFaceDetector.a'
  s.frameworks = 'SystemConfiguration', 'CoreMotion' , 'AVFoundation' , 'CoreMedia'
end
