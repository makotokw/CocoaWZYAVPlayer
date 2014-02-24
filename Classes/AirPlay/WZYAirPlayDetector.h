//
//  WZYAirPlayDetector.h
//  WZYAVPlayer
//
//  based on https://github.com/StevePotter/AirPlayDetector
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPVolumeView;

extern NSString *WZYAirPlayAvailabilityChanged;

@interface WZYAirPlayDetector : NSObject

@property (readonly, nonatomic) BOOL isAirPlayAvailabled;

+ (WZYAirPlayDetector*)defaultDetector;

- (void)startMonitoringWithVolumeView:(MPVolumeView *)volumeView;
- (void)startMonitoringWithWindow:(UIWindow *)window;

@end
