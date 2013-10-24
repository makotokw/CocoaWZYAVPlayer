//
//  WZAirPlayDetector.h
//  WZAVPlayer
//
//  based on https://github.com/StevePotter/AirPlayDetector
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPVolumeView;

extern NSString *WZAirPlayAvailabilityChanged;

@interface WZAirPlayDetector : NSObject

@property (readonly, nonatomic) BOOL isAirPlayAvailabled;

+ (WZAirPlayDetector*)defaultDetector;

- (void)startMonitoringWithVolumeView:(MPVolumeView *)volumeView;
- (void)startMonitoringWithWindow:(UIWindow *)window;

@end
