Pod::Spec.new do |s|
  s.name     = "WZYAVPlayer"
  s.version  = "0.1.1"
  s.summary  = "UI Controls to play video."
  s.homepage = "https://github.com/makotokw/CocoaWZYAVPlayer"
  s.license  = { :type => 'MIT License', :file => 'LICENSE' }
  s.author   = { "Makoto Kawasaki" => "makoto.kw@gmail.com" }
  s.source   = { :git => "https://github.com/makotokw/CocoaWZYAVPlayer.git", :tag => 'v0.1.1' }
  s.platform = :ios, '6.0'

  s.subspec 'Core' do |sub|
    sub.requires_arc  = true
    sub.source_files  = 'Classes/Core/*.{h,m}'
    sub.frameworks    = 'AVFoundation', 'CoreMedia'
    sub.dependency 'WZYPlayerSlider'
    sub.dependency 'MBProgressHUD'
    sub.dependency 'BlocksKit/UIKit', '~> 2.0'
  end

  s.subspec 'AirPlay' do |sub|
    sub.requires_arc  = true
    sub.source_files  = 'Classes/AirPlay/*.{h,m}'
    sub.frameworks    = 'MediaPlayer'
  end

  s.subspec 'Player' do |sub|
    sub.resources               = 'Resources/*.bundle', 'Resources/*.xib'
    sub.prefix_header_contents  = <<EOC
#ifdef __OBJC__
    #import <WZYAVPlayer/WZYAVPlayer.h>
#endif
EOC
    sub.dependency 'WZYAVPlayer/Core'
    sub.dependency 'WZYAVPlayer/AirPlay'
  end

  s.default_subspecs = 'Player'
end
