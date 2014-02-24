//
//  WZYPlayTimeFormatter.h
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WZYAVPlayerDefines.h"

@interface WZYPlayTimeFormatter : NSObject

+ (NSString*)stringFromInterval:(NSTimeInterval)interval;
+ (NSString*)stringFromInterval:(NSTimeInterval)interval style:(WZYPlayTimeFormatterStyle)style;

/**
 *  convert PlayTime(00:00:00) into seconds
 */
+ (NSTimeInterval)timeIntervalFromPlayTime:(NSString *)playTime;

@end
