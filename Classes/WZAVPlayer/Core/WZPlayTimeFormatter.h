//
//  WZPlayTimeFormatter.h
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WZAVPlayerDefines.h"

@interface WZPlayTimeFormatter : NSObject

+ (NSString*)stringFromInterval:(NSTimeInterval)interval;
+ (NSString*)stringFromInterval:(NSTimeInterval)interval style:(WZPlayTimeFormatterStyle)style;

/**
 *  convert PlayTime(00:00:00) into seconds
 */
+ (NSTimeInterval)timeIntervalFromPlayTime:(NSString *)playTime;

@end
