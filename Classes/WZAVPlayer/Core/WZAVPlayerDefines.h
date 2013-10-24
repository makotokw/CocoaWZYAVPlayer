//
//  WZAVPlayerDefines.h
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

// WZLog macro
#ifndef WZLog
#define WZLog(...) NSLog(__VA_ARGS__)
#endif

// WZLogD macro
#ifndef WZLogD
#if DEBUG
#define WZLogD(...) NSLog(__VA_ARGS__)
#else
#define WZLogD(...) ;
#endif
#endif

typedef void (^WZAVPlayerBlock)();
typedef void (^WZAVPlayerAsyncBlock)(NSError *error);

typedef enum : NSInteger {
    WZPlayTimeFormatterStyleDefault = 0,
    WZPlayTimeFormatterStyleMillSecond = 1,
} WZPlayTimeFormatterStyle;
