//
//  WZAirPlayDetector.m
//  WZAVPlayer
//
//  based on https://github.com/StevePotter/AirPlayDetector
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import "WZAirPlayDetector.h"

#import <MediaPlayer/MediaPlayer.h>

NSString *WZAirPlayAvailabilityChanged = @"WZAirPlayAvailabilityChanged";

NSString *const kAlphaKey = @"alpha";

@implementation WZAirPlayDetector
{
    UIButton *_routeButton;
}

@synthesize isAirPlayAvailabled = _isAirPlayAvailabled;

+ (WZAirPlayDetector *)defaultDetector
{
    static WZAirPlayDetector *defaultDetector = nil;
    
    @synchronized(self) {
        if (!defaultDetector) {
            defaultDetector = [[WZAirPlayDetector alloc] init];
        }
        
        return defaultDetector;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        _isAirPlayAvailabled = NO;
    }
    
    return self;
}

- (UIButton *)findRouteButtonIntoVolumeView:(MPVolumeView *)volumeView
{
    for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            return (UIButton *)view;
        }
    }
    return nil;
}

- (void)startMonitoringWithVolumeView:(MPVolumeView *)volumeView
{
    if (_routeButton) {
        [_routeButton removeObserver:self forKeyPath:kAlphaKey];
    }
    _isAirPlayAvailabled = NO;
    _routeButton         = [self findRouteButtonIntoVolumeView:volumeView];
    [_routeButton addObserver:self forKeyPath:kAlphaKey options:NSKeyValueObservingOptionNew context:nil];
}

- (void)startMonitoringWithWindow:(UIWindow *)window;
{
    // here is the real trick.  place an MPVolumeView in the window and monitor for changes in the airplay button's alpha property.  note that this depends on the MPVolumeView's view hierarchy so it must be tested for each iOS release
    // this was made possible by the awesome sample from http://stackoverflow.com/questions/5388884/airplay-button-on-custom-view-problems
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -1000, 100, 100)];
    volumeView.showsVolumeSlider = NO;
    volumeView.showsRouteButton  = YES;
    [window addSubview:volumeView]; // if you don't add to a window, nothing will ever happen
    
    [self startMonitoringWithVolumeView:volumeView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![object isKindOfClass:[UIButton class]]) {
        return;
    }
    
    BOOL isAvailabled = [[change valueForKey:NSKeyValueChangeNewKey] floatValue] == 1.0;
    
    if (isAvailabled != _isAirPlayAvailabled) {
        _isAirPlayAvailabled = isAvailabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:WZAirPlayAvailabilityChanged object:self];
    }
}

- (void)dealloc
{
    [_routeButton removeObserver:self forKeyPath:kAlphaKey];
}

@end
