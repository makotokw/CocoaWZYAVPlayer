//
//  WZPlayTimeFormatter.m
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import "WZPlayTimeFormatter.h"

@implementation WZPlayTimeFormatter

+ (NSString*)stringFromInterval:(NSTimeInterval)interval
{
    NSTimeInterval sec = abs(interval);
    NSUInteger hour = (NSUInteger)sec/3600;
    sec -= hour*3600;
    NSUInteger min  = (NSUInteger)sec/60;
    sec -= min*60;
    
    NSString *prefix = ( interval < 0  ) ? @"-" : @"";    
    if (hour >= 1) {
        return [prefix stringByAppendingFormat:@"%d:%02d:%02d", hour, min, (int)sec];
    }
    return [prefix stringByAppendingFormat:@"%d:%02d", min, (int)sec];
}

+ (NSString*)stringFromInterval:(NSTimeInterval)interval style:(WZPlayTimeFormatterStyle)style
{
    if (style == WZPlayTimeFormatterStyleMillSecond) {
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
