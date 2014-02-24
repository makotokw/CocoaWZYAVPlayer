//
//  WZYAVPlayerDefines.h
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

// WZYLog macro
#ifndef WZYLog
#define WZYLog(...) NSLog(__VA_ARGS__)
#endif

// WZYLogD macro
#ifndef WZYLogD
#if DEBUG
#define WZYLogD(...) NSLog(__VA_ARGS__)
#else
#define WZYLogD(...) ;
#endif
#endif

typedef void (^WZYAVPlayerBlock)();
typedef void (^WZYAVPlayerAsyncBlock)(NSError *error);

typedef enum : NSInteger {
    WZYPlayTimeFormatterStyleDefault = 0,
    WZYPlayTimeFormatterStyleMillSecond = 1,
} WZYPlayTimeFormatterStyle;
