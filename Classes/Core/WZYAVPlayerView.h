//
//  WZYAVPlayerView.h
//  WZYAVPlayer
//
//  Copyright (c) 2012 makoto_kw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WZYAVPlayerDefines.h"

@class WZYAVPlayerView;
@protocol WZYAVPlayerViewDelegate <NSObject>
- (void)playerViewLiveDidChanged:(WZYAVPlayerView *)view changeToValue:(BOOL)isLive;
- (void)playerViewSeekingBegan:(WZYAVPlayerView *)view;
- (void)playerViewSeekingCompletation:(WZYAVPlayerView *)view;
@end

@interface WZYAVPlayerView : UIView <UIGestureRecognizerDelegate>

@property (weak) id<WZYAVPlayerViewDelegate> delegate;

@property (nonatomic, retain) AVPlayer *player;

@property (nonatomic, retain) IBOutlet UIView *headerView;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;

@property (nonatomic, retain) IBOutlet UIView *controlView;
@property (nonatomic, retain) UIImage *playButtonImage, *pauseButtonImage;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UISlider *scrubber;

@property (retain, readwrite) NSString *title;
@property (assign, readonly) NSTimeInterval currentPosition;
@property (assign, readwrite) NSTimeInterval estimateDuration;
@property (assign, readonly) BOOL isPlayerOpened;
@property (assign, readonly) BOOL isPlaying; // playing, except buffering
@property (assign, readonly) BOOL isPaused; // paused, except buffering
@property (assign, readonly) BOOL canSeeking;
@property (assign, readonly) BOOL isSeeking;
@property (assign, readwrite) BOOL isSliderAvailableTrackEnabled;

@property (assign, readwrite) BOOL backButtonHidden;
@property (copy) WZYAVPlayerBlock backBlock;

- (IBAction)beginScrubbing:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;
- (IBAction)toggleFullscreenStyle:(id)sender;

- (void)seekToTime:(NSTimeInterval)time completionHandler:(WZYAVPlayerBlock)completionHandler;
- (void)seekFromCurrentTime:(NSTimeInterval)interval completionHandler:(WZYAVPlayerBlock)completionHandler;

- (void)presentOverlayWithDuration:(NSTimeInterval)duration;
- (void)dismissOverlayWithDuration:(NSTimeInterval)duration;
- (void)toggleOverlayWithDuration:(NSTimeInterval)duration;
- (CMTime)playerCurrentPosition;
- (CMTime)playerItemDuration;
- (void)addPlayerTimeObserverForInterval:(NSTimeInterval)interval;

- (UIColor *)subViewBackgroundColor;
- (void)setVideoFillMode:(NSString *)fillMode;

- (void)enableScreenTapRecognizer;
- (void)disableScreenTapRecognizer;

- (void)play;
- (void)pause;
- (void)close;

- (void)enableControls;
- (void)disableControls;
- (void)refreshControls;
- (void)enableSeekControls;
- (void)disableSeekControls;

- (void)resetStatus;
- (void)resetPlayPosition;
- (void)refreshPlayPosition;
- (void)resetIdleTimer;
- (void)beginPlayerTimeObserver;
- (void)endPlayerTimeObserver;

- (NSTimeInterval)idleTimeIntervalToHideOlverlay;

@end