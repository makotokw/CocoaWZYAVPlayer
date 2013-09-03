//
//  WZPlayTimeFormatter.h
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZPlayTimeFormatter : NSObject

+ (NSString*)stringFromInterval:(NSTimeInterval)interval;
+ (NSString*)stringFromInterval:(NSTimeInterval)interval style:(WZPlayTimeFormatterStyle)style;


@end
