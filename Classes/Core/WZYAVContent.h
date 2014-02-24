//
//  WZYAVContent.h
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

@interface WZYAVContent : NSObject

@property(retain, readwrite) NSURL *location;
@property(retain, readwrite) NSString *title;
@property(assign, readwrite) NSTimeInterval duration;
@property(assign, readwrite) NSTimeInterval playPosition;
@property(assign, readwrite) NSTimeInterval initialPlaybackTime;
@property(assign, readwrite) NSTimeInterval endPlaybackTime;

@end