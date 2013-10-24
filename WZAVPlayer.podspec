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
    sub.source_files  = 'Classes/WZAVPlayer/Core/*.{h,m}'    
    sub.frameworks    = 'AVFoundation', 'CoreMedia'
    sub.dependency 'BlocksKit', '~> 1.8.3'
  end

  s.subspec 'AirPlay' do |sub|
    sub.requires_arc  = true
    sub.source_files  = 'Classes/WZAVPlayer/AirPlay/*.{h,m}'
    sub.frameworks    = 'MediaPlayer'
  end

  s.subspec 'HUD' do |sub|
    sub.dependency 'MBProgressHUD'
  end

  s.subspec 'Player' do |sub|
    sub.dependency 'WZAVPlayer/HUD'
    sub.dependency 'WZAVPlayer/Core'
    sub.dependency 'WZAVPlayer/AirPlay'
    sub.resources               = 'Resources/*.bundle', 'Resources/*.xib'
    sub.prefix_header_contents  = <<EOC
#ifdef __OBJC__
    #import <WZAVPlayer/WZAVPlayer.h>
#endif
EOC
  end

end
