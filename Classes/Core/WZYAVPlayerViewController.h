//
//  WZYAVPlayerViewController.h
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "WZYAVPlayerView.h"
#import "WZYAVContent.h"

@interface WZYAVPlayerViewController : UIViewController<WZYAVPlayerViewDelegate>

@property (nonatomic, copy) NSString *contentTitle;
@property (nonatomic, copy) NSURL *contentURL;
@property (retain, readonly) AVPlayer *player;
@property (nonatomic, retain) WZYAVPlayerView *playerView;

@property (assign, readwrite) BOOL backButtonHidden;
@property (copy) WZYAVPlayerBlock backBlock;

- (id)showProgressWithText:(NSString *)text;
- (void)hideProgress;

- (void)play;
- (void)pause;
- (void)close;

- (void)requireAudioPlayback;
- (void)reopen;
- (void)tryAutoPlayWithDelay:(NSTimeInterval)delay;

- (void)refreshForReadyToPlayIfPlaying;
- (void)refreshForReadyToPlayIfPlayingWithDelay:(NSTimeInterval)delay;

@end

@interface WZYAVPlayerViewController (Protected)

- (NSTimeInterval)playerInitialPlayPosition;
- (void)playerDidPrepare;
- (void)playerDidReadyPlayback;
- (void)playerDidBeginPlayback;
- (void)playerDidEndPlayback;
- (void)playerDidReachEndPlayback;
- (void)playerDidReplaceFromPlayer:(AVPlayer *)oldPlayer;
- (void)playerFailedToPrepareForPlayback:(NSError *)error;

@end
