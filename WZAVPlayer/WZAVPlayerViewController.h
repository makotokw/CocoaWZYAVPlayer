//
//  WZAVPlayerViewController.h
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "WZAVPlayerView.h"
#import "WZAVContent.h"

@interface WZAVPlayerViewController : UIViewController<WZAVPlayerViewDelegate>

@property (nonatomic, copy) NSString *contentTitle;
@property (nonatomic, copy) NSURL *contentURL;
@property (retain, readonly) AVPlayer *player;
@property (nonatomic, retain) WZAVPlayerView *playerView;

@property (assign, readwrite) BOOL backButtonHidden;
@property (copy) WZAVPlayerBlock backBlock;

- (id)showProgressWithText:(NSString *)text;
- (void)hideProgress;

- (void)play;
- (void)pause;
- (void)close;

- (void)refreshForReadyToPlayIfPlaying;
- (void)refreshForReadyToPlayIfPlayingWithDelay:(NSTimeInterval)delay;

@end

@interface WZAVPlayerViewController (Protected)

- (NSTimeInterval)playerInitialPlayPosition;
- (void)playerDidPrepare;
- (void)playerDidReadyPlayback;
- (void)playerDidBeginPlayback;
- (void)playerDidEndPlayback;
- (void)playerDidReachEndPlayback;
- (void)playerFailedToPrepareForPlayback:(NSError *)error;

@end
