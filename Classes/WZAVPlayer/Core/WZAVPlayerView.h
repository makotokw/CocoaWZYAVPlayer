//
//  WZAVPlayerView.h
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WZAVPlayerDefines.h"

@class WZAVPlayerView;
@protocol WZAVPlayerViewDelegate <NSObject>
- (void)playerViewLiveDidChanged:(WZAVPlayerView *)view changeToValue:(BOOL)isLive;
- (void)playerViewSeekingBegan:(WZAVPlayerView *)view;
- (void)playerViewSeekingCompletation:(WZAVPlayerView *)view;
@end

@interface WZAVPlayerView : UIView <UIGestureRecognizerDelegate>

@property (weak) id<WZAVPlayerViewDelegate> delegate;

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
@property (assign, readwrite) NSTimeInterval estimateDuration;
@property (assign, readonly) BOOL isPlayerOpened;
@property (assign, readonly) BOOL isPlaying; // playing, except buffering
@property (assign, readonly) BOOL isPaused; // paused, except buffering
@property (assign, readonly) BOOL canSeeking;
@property (assign, readonly) BOOL isSeeking;
@property (assign, readwrite) BOOL isSliderAvailableTrackEnabled;

@property (assign, readwrite) BOOL backButtonHidden;
@property (copy) WZAVPlayerBlock backBlock;

- (IBAction)beginScrubbing:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;
- (IBAction)toggleFullscreenStyle:(id)sender;

- (void)seekToTime:(NSTimeInterval)time completionHandler:(WZAVPlayerBlock)completionHandler;
- (void)seekFromCurrentTime:(NSTimeInterval)interval completionHandler:(WZAVPlayerBlock)completionHandler;

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