//
//  WZYPlayTimeFormatter.m
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

#import "WZYPlayTimeFormatter.h"

@implementation WZYPlayTimeFormatter

+ (NSString*)stringFromInterval:(NSTimeInterval)interval
{
    NSTimeInterval sec = abs(interval);
    NSUInteger hour = (NSUInteger)sec/3600;
    sec -= hour*3600;
    NSUInteger min  = (NSUInteger)sec/60;
    sec -= min*60;
    
    NSString *prefix = ( interval < 0  ) ? @"-" : @"";    
    if (hour >= 1) {
        return [prefix stringByAppendingFormat:@"%d:%02d:%02d", (int)hour, (int)min, (int)sec];
    }
    return [prefix stringByAppendingFormat:@"%d:%02d", (int)min, (int)sec];
}

+ (NSString*)stringFromInterval:(NSTimeInterval)interval style:(WZYPlayTimeFormatterStyle)style
{
    if (style == WZYPlayTimeFormatterStyleMillSecond) {
        // TODO:
        NSTimeInterval sec = abs(interval);
        NSUInteger hour = (NSUInteger)sec/3600;
        sec -= hour*3600;
        NSUInteger min  = (NSUInteger)sec/60;
        sec -= min*60;        
        NSString *prefix = ( interval < 0  ) ? @"-" : @"";
        if (hour >= 1) {
            NSString *format = (sec < 10) ? @"%d:%02d:0%.2lf" : @"%d:%02d:%.2lf";
            return [prefix stringByAppendingFormat:format, hour, min, sec];
        } else {
            NSString *format = (sec < 10) ? @"%d:0%.2lf" : @"%d:%.2lf";
            return [prefix stringByAppendingFormat:format, min, sec];
        }
    }
    return [self stringFromInterval:interval];
}

+ (NSTimeInterval)timeIntervalFromPlayTime:(NSString *)playTime
{
    NSTimeInterval time = 0;
    NSArray *components = [playTime componentsSeparatedByString:@":"];
    
    NSEnumerator *enumerator = [components reverseObjectEnumerator];
    NSString *component;
    NSInteger k = 1;
    
    while ((component = [enumerator nextObject])) {
        time += [component floatValue] * k;
        k *= 60;
    }
    return time;
}

@end
