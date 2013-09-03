//
//  WZAVPlayerView.m
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import "WZAVPlayerView.h"
#import "WZPlayerSlider.h"
#import "WZPlayTimeFormatter.h"

#define kMaxIdleTimeSecondsToHideOlverlay 6.0
#define kInitialTimeString @"--:--"

@interface WZAVPlayerView()
@end

@implementation WZAVPlayerView

{
    AVPlayer *_player;
    
    WZPlayerSlider *_playerSlider;
    
    BOOL _backButtonHidden;
    
	float _playerRateBeforeScrubbing;
    BOOL _scrubbing;
    NSTimeInterval _seekingToTime;
    NSTimeInterval _playPositionAtEnd;
	id _timeObserver;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    
    NSTimer *_idleTimer;
}

@dynamic player;
@dynamic title;
@dynamic backButtonHidden;
@dynamic isPlayerOpened;
@dynamic isPlaying;
@synthesize isPaused = _isPaused;
@dynamic isSeeking;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor blackColor];
    
    _headerView.alpha = 0.0;
    _controlView.alpha = 0.0;
    _titleLabel.text = @"";
    _currentTimeLabel.text = kInitialTimeString;
    _durationLabel.text = kInitialTimeString;
        
    UIColor *backgroundColor = [self subViewBackgroundColor];
    if (backgroundColor) {
        _headerView.backgroundColor = backgroundColor;
        _controlView.backgroundColor = backgroundColor;
    }
    
    _backButton.titleLabel.text = nil;
    [_backButton setImage:[UIImage imageNamed:@"WZAVPlayerResources.bundle/back.png"] forState:UIControlStateNormal];
    
    _playButtonImage = [UIImage imageNamed:@"WZAVPlayerResources.bundle/play.png"];
    _pauseButtonImage = [UIImage imageNamed:@"WZAVPlayerResources.bundle/pause.png"];
    
    [_playButton setTitle:nil forState:UIControlStateNormal];
    [_playButton setImage:_playButtonImage forState:UIControlStateNormal];
    
    if ([_scrubber.class isSubclassOfClass:[WZPlayerSlider class]]) {
        _playerSlider = (WZPlayerSlider *)_scrubber;
    }
        
    [self bindTouchEventsToScrubber];
    [self disableControls];
    [self enableScreenTapRecognizer];    
    [self layoutInHeaderView];
}

- (void)bindTouchEventsToScrubber
{    
    [_scrubber addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [_scrubber addTarget:self action:@selector(scrubing:) forControlEvents:UIControlEventTouchDragInside];
    [_scrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchCancel];
    [_scrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [_scrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
	[self removePlayerTimeObserver];
}

+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
	return _player;
}

- (void)setPlayer:(AVPlayer*)player
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.player = player;
    if (_player) {
        [self endPlayerTimeObserver];
    }
    _player = player;
}

- (UIColor *)subViewBackgroundColor
{
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

- (NSString *)title
{
    return _titleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
}

- (UIResponder *)nextResponder
{
    [self resetIdleTimer];
    return [super nextResponder];
}

- (NSTimeInterval)idleTimeIntervalToHideOlverlay
{
    return kMaxIdleTimeSecondsToHideOlverlay;
}

- (void)resetIdleTimer
{    
    if (!_idleTimer) {
        if ((_controlView.alpha != 0.0 || _headerView.alpha != 0.0) && ![self isScrubbing]) {
            _idleTimer = [NSTimer scheduledTimerWithTimeInterval:[self idleTimeIntervalToHideOlverlay]
                                                          target:self
                                                        selector:@selector(idleTimerExceeded)
                                                        userInfo:nil
                                                         repeats:NO];
        }
    }
    else {
        _idleTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:[self idleTimeIntervalToHideOlverlay]];
    }
}

- (void)idleTimerExceeded
{
    _idleTimer = nil;
    if ( (_controlView.alpha != 0.0 || _headerView.alpha != 0.0) && ![self isScrubbing] && [self isPlaying]) {
        [self toggleOverlayWithDuration:0.5];
    }
}

- (void)presentOverlayWithDuration:(NSTimeInterval)duration
{
    if (_headerView.alpha == 0.0) {
        [self toggleOverlayWithDuration:duration];
    }
}

- (void)dismissOverlayWithDuration:(NSTimeInterval)duration
{
    if (_headerView.alpha == 1.0) {
        [self toggleOverlayWithDuration:duration];
    }
}

- (void)toggleOverlayWithDuration:(NSTimeInterval)duration
{
    __weak WZAVPlayerView *me = self;
    [UIView animateWithDuration:duration
                     animations:^{
                         if (_headerView.alpha == 0.0) {
                             _headerView.alpha = 1.0;
                         } else {
                             _headerView.alpha = 0.0;
                         }
                         if (_controlView.alpha == 0.0) {
                             _controlView.alpha = 1.0;
                         } else {
                             _controlView.alpha = 0.0;
                         }
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             if (_controlView.alpha != 0.0) {
                                 [me resetIdleTimer];
                             }
                         }
                     }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // test if our control subview is on-screen
    if (touch.view != self) {
        if ([touch.view isDescendantOfView:self]) {
            // we touched our control surface
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}

-(IBAction)viewDidTapped:(id)sender
{
    [self toggleOverlayWithDuration:0.25];
}

- (void)enableScreenTapRecognizer
{
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTapped:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];
    }
}

- (void)disableScreenTapRecognizer
{
    if (_tapGestureRecognizer) {
        [self removeGestureRecognizer:_tapGestureRecognizer];
        [_tapGestureRecognizer removeTarget:self action:@selector(viewDidTapped:)];
        _tapGestureRecognizer = nil;
    }
}

- (void)setVideoFillMode:(NSString *)fillMode
{
	AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
	playerLayer.videoGravity = fillMode;
}

- (CMTime)playerItemDuration
{
	AVPlayerItem *playerItem = _player.currentItem;
	if (playerItem.status == AVPlayerItemStatusReadyToPlay)
	{
		return (playerItem.duration);
	}
	
	return (kCMTimeInvalid);
}

- (NSTimeInterval)playerItemAvailableDuration;
{
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    if (loadedTimeRanges.count == 0) {
        return 0.0;
    }
    CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

- (BOOL)isPlaying
{
    WZLogD(@"WZAVPlayerView.isPlaying: AVPlayer.rate = %lf", _player.rate);
	return _playerRateBeforeScrubbing != 0.f || _player.rate != 0.f;
}

- (BOOL)isPlayerOpened
{
    return (_player != nil);
}

- (BOOL)backButtonHidden
{
    return _backButtonHidden;
}

- (void)setBackButtonHidden:(BOOL)hidden
{
    if (_backButtonHidden != hidden) {
        _backButtonHidden = hidden;
        [self layoutInHeaderView];
    }
}

- (void)layoutInHeaderView
{
    CGSize parentViewSize = _headerView.frame.size;
    if (_backButtonHidden) {
        _backButton.hidden = YES;        
        _titleLabel.frame = CGRectMake(20, 9,
                                       parentViewSize.width - 40,
                                       _titleLabel.frame.size.height);        
    } else {
        _backButton.hidden = NO;
        _titleLabel.frame = CGRectMake(48, 9,
                                       parentViewSize.width - 68,
                                       _titleLabel.frame.size.height);
    }
}

#pragma mark -
#pragma mark Control

- (void)play
{
    [_player play];
    _isPaused = NO;
    [self refreshControls];
}

- (void)pause
{
    [_player pause];
    _isPaused = YES;
    [self refreshControls];
}

- (void)close
{
    self.player = nil;
    self.title = nil;
    _isPaused = NO;
    [self refreshControls];
    [self resetPlayPosition];
    [self disableControls];
}

- (void)refreshControls
{
    if (!self.isPaused) {
        [_playButton setImage:_pauseButtonImage forState:UIControlStateNormal];
        [self refreshPlayPosition];
    } else {
        [_playButton setImage:_playButtonImage forState:UIControlStateNormal];
        [self refreshPlayPosition];
    }
}

- (void)enableControls
{
    _playButton.enabled = YES;
    _durationLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.textColor = [UIColor whiteColor];
    [self enableSeekControls];
}

- (void)disableControls
{
    _playButton.enabled = NO;
    _durationLabel.textColor = [UIColor grayColor];
    _currentTimeLabel.textColor = [UIColor grayColor];
    [self disableSeekControls];
}

- (void)enableSeekControls
{
    _scrubber.enabled = YES;
}

- (void)disableSeekControls
{
    _scrubber.enabled = NO;
}

- (IBAction)toggleFullscreenStyle:(id)sender
{
    // TODO:
}

#pragma mark -
#pragma mark playposition

- (void)beginPlayerTimeObserver
{
	double interval = .1f;
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) {
		return;
	}
    if (!_scrubber) {
        return;
    }
    
    [self addPlayerTimeObserverForInterval:interval];
}

- (void)endPlayerTimeObserver
{
    [self removePlayerTimeObserver];
}

- (void)addPlayerTimeObserverForInterval:(NSTimeInterval)interval
{
    if (!_timeObserver) {
        __weak WZAVPlayerView *me = self;
        _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                              queue:NULL
                                                         usingBlock:^(CMTime time)
                         {
                             [me refreshPlayPosition];
                         }];
    }
}

- (void)removePlayerTimeObserver
{
    if (_timeObserver)
	{
		[_player removeTimeObserver:_timeObserver];
		_timeObserver = nil;
	}
}

- (void)resetStatus
{
    _isPaused = NO;
}

- (void)resetPlayPosition
{
    _playPositionAtEnd = 0.0f;
    _scrubber.value = 0.0;
    _currentTimeLabel.text = kInitialTimeString;
    _durationLabel.text = kInitialTimeString;
}

- (void)rememberEndPosition
{
    _playPositionAtEnd = CMTimeGetSeconds([_player currentTime]);
}

- (void)refreshPlayPosition
{    
    // wrong duration in play failed
    if (_player.status == AVPlayerStatusFailed
        || _player.status == AVPlayerStatusUnknown) {
        return;
    }
    
    if ([self isScrubbing] || [self isSeeking]) {
        return;
    }
    
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) {
        _scrubber.minimumValue = 0.0;
        [self disableSeekControls];
		return;
	}
    
    double duration = CMTimeGetSeconds(playerDuration);
    double time = CMTimeGetSeconds([_player currentTime]);
    
    if (CMTIME_IS_INDEFINITE(playerDuration)) {
        [self disableSeekControls];
        _playerSlider.availableDuration = 0.0;
        _playerSlider.duration = time;
    } else {
        [self enableSeekControls];
        if (_isSliderAvailableTrackEnabled) {
            _playerSlider.availableDuration = [self playerItemAvailableDuration];
        } else {
            _playerSlider.availableDuration = duration;
        }        
        _playerSlider.duration = duration;
    }
    
    if (!isfinite(time) && !isfinite(duration)) {
        _currentTimeLabel.text = kInitialTimeString;
        _durationLabel.text = kInitialTimeString;
    } else {
        if (isfinite(time) && time > 0.0f) {
            if (isfinite(duration) && duration > 0.0f) {
                if (_playPositionAtEnd > 0.0f && time >= _playPositionAtEnd) {
                    // hack
                    time = duration;
                }
                _currentTimeLabel.text = [WZPlayTimeFormatter stringFromInterval:time];
                _durationLabel.text = [WZPlayTimeFormatter stringFromInterval:-duration+time];
                float minValue = [_scrubber minimumValue];
                float maxValue = [_scrubber maximumValue];            
                [_scrubber setValue:(maxValue - minValue) * time / duration + minValue];
            } else {                
                _currentTimeLabel.text = [WZPlayTimeFormatter stringFromInterval:time];
                _durationLabel.text = kInitialTimeString;
                [_scrubber setValue:1.0f];
            }
        }
    }
}

- (IBAction)beginScrubbing:(id)sender
{
    _scrubbing = YES;
    if (!_playerSlider) {
        _playerRateBeforeScrubbing = [_player rate];
        if (_playerRateBeforeScrubbing > 0.f) {
            [_player setRate:0.f];
        }
    }	
    [self resetIdleTimer];
}

- (IBAction)scrubing:(id)sender
{
    if (!_scrubbing) {
        [self beginScrubbing:sender];
    } else {
        [self scrub:sender];
    }
}

- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]])
    {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            if (![self isScrubbing]) {
                [self seekToTime:time];
            } else {
                if (_playerSlider && _playerSlider.isPopoverEnabled) {
                    // TODO:
                } else {
                    _currentTimeLabel.text = [WZPlayTimeFormatter stringFromInterval:time];
                    _durationLabel.text = [WZPlayTimeFormatter stringFromInterval:-duration+time];
                }
            }
        }
    }
    [self resetIdleTimer];
}

- (IBAction)endScrubbing:(id)sender
{
    [self resetIdleTimer];
    
	if (_playerRateBeforeScrubbing) {
		_player.rate = _playerRateBeforeScrubbing;
		_playerRateBeforeScrubbing = 0.f;
	}
    
    _scrubbing = NO;
    [self scrub:sender];
}

- (BOOL)isScrubbing
{
	return _scrubbing;
}

- (BOOL)isSeeking
{
    return (_seekingToTime != 0.0f);
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(WZAVPlayerBlock)completionHandler
{
    _seekingToTime = time;
    __weak WZAVPlayerView *me = self;
    [me.delegate playerViewSeekingBegan:self];
    [_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        if (_seekingToTime == time) {
            _seekingToTime = 0.0f;
        }
        if (completionHandler) {
            completionHandler();
        }
        [me.delegate playerViewSeekingCompletation:me];
    }];
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completionHandler:nil];
}

- (void)seekFromCurrentTime:(NSTimeInterval)interval completionHandler:(WZAVPlayerBlock)completionHandler
{
    NSTimeInterval time = CMTimeGetSeconds(_player.currentTime);
    time += interval;
    if (time < 0) {
        time = 0;
    }
    [self seekToTime:time completionHandler:completionHandler];
}

- (void)seekFromCurrentTime:(NSTimeInterval)interval
{
    [self seekFromCurrentTime:interval completionHandler:nil];
}

@end
