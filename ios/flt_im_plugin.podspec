#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flt_im_plugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flt_im_plugin'
  s.version          = '0.1.0'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }

  s.source_files = "Classes/*.{h,m}"
  s.dependency 'MJExtension', '~> 3.2.2'


  s.subspec 'imsdk' do |sp|
      sp.public_header_files = 'Classes/imsdk/*.h'
      sp.source_files        = 'Classes/imsdk/*.{h,m,c}'
      sp.pod_target_xcconfig = {
        'OTHER_LDFLAGS' => '-ObjC'
      }
  end

  s.subspec 'imlib' do |sp|
     sp.source_files     = 'Classes/imlib/**/*.{h,m,c}'
     sp.dependency 'flt_im_plugin/imsdk'
     sp.dependency 'SDWebImage', '~> 5.1.0'
     sp.dependency 'FMDB', '~> 2.7.0'
     sp.dependency 'Masonry', '~>1.1.0'
  end
#s.subspec 'voips' do |sp|
#sp.source_files     = 'Classes/voips/**/*.{h,m,c}'
# sp.dependency 'flt_im_plugin/imsdk'
# sp.vendored_frameworks = 'frameworks/WebRTC.framework'
#
#sp.resource         = [
# 'Classes/voips/sound/*.{mp3,caf}',
# 'Classes/voips/Images.xcassets',
# ]
#
#sp.pod_target_xcconfig = {
#'OTHER_LDFLAGS' => '$(inherited) -all_load'
# }
# end
  s.subspec 'imkit' do |sp|
    sp.vendored_libraries = 'Classes/imkit/amr/*.a'
    sp.source_files     = 'Classes/imkit/**/*.{h,m,c}'

    sp.resource         = [
      'Classes/imkit/imKitRes/sounds/*.aiff',
      'Classes/imkit/imKitRes/gobelieve.xcassets',
      'Classes/imkit/imKitRes/Emoji.xcassets',
    ]

    sp.pod_target_xcconfig = {
        'OTHER_LDFLAGS' => '$(inherited) -all_load'
    }

    sp.dependency 'flt_im_plugin/imsdk'
    sp.dependency 'flt_im_plugin/imlib'

    sp.dependency 'SDWebImage', '~> 5.1.0'
    sp.dependency 'Toast', '~> 4.0.0'
    sp.dependency 'MBProgressHUD', '~> 0.9.1'
    sp.dependency 'FMDB', '~> 2.7.0'
    sp.dependency 'Masonry', '~>1.1.0'
  end

end
