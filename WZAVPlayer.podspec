Pod::Spec.new do |s|
  s.name     = "WZAVPlayer"
  s.version  = "0.1"
  s.summary  = "UI Control to play video."
  s.homepage = "https://github.com/makotokw/WZAVPlayer"
  s.license  = { :type => 'MIT License', :file => 'LICENSE' }
  s.author   = { "Makoto Kawasaki" => "makoto.kw@gmail.com" }
  s.source   = { :git => "https://github.com/makotokw/WZAVPlayer.git", :tag => '0.1' }
  s.platform = :ios, '5.0'

  s.subspec 'Core' do |sub|
    sub.requires_arc  = true
    sub.source_files  = 'WZAVPlayer/*.{h,m}'
    sub.resources     = 'WZAVPlayer/WZAVPlayerResources.bundle', 'WZAVPlayer/*.xib'
    sub.frameworks    = 'AVFoundation', 'CoreMedia'
    sub.prefix_header_contents = <<EOC
#ifdef __OBJC__
    #import <WZAVPlayer.h>
#endif
EOC
  end

  s.subspec 'HUD' do |sub|
    sub.dependency 'MBProgressHUD'
  end

  s.dependency 'WZAVPlayer/HUD'
  s.dependency 'WZAVPlayer/Core'

end
