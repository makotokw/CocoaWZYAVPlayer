//
//  WZAVPlayerViewController.m
//  WZAVPlayer
//
//  Copyright (c) 2012-2013 makoto_kw. All rights reserved.
//

#import "WZAVPlayerDefines.h"
#import "WZAVPlayerViewController.h"
#import "WZAVPlayerView.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>

/* Asset keys */
NSString * const kTracksKey         = @"tracks";
NSString * const kPlayableKey		= @"playable";

/* PlayerItem keys */
NSString * const kStatusKey                 = @"status";
NSString * const kPlaybackBufferEmpty       = @"playbackBufferEmpty";
NSString * const kPlaybackLikelyToKeepUp    = @"playbackLikelyToKeepUp";

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

@interface WZAVPlayerViewController ()
{
    NSString *_contentTitle;
	NSURL *_contentURL;
    
    WZAVPlayerBlock _backBlock;
    BOOL _backButtonHidden;
    
	AVPlayer *_player;
    AVPlayerItem *_playerItem;
    NSTimeInterval _initialPlaybackTime;
    NSTimeInterval _readyToPlayTime;
    MBProgressHUD *_progressHud;
    
    BOOL _buffering;
    BOOL _reopening;
    BOOL _mediaEnded;
}
@end

static void *WZAVPlayerViewControllerRateObservationContext = &WZAVPlayerViewControllerRateObservationContext;
static void *WZAVPlayerViewControllerStatusObservationContext = &WZAVPlayerViewControllerStatusObservationContext;
static void *WZAVPlayerViewControllerCurrentItemObservationContext = &WZAVPlayerViewControllerCurrentItemObservationContext;

#pragma mark -
@implementation WZAVPlayerViewController

@synthesize playerView = _playerView;
@dynamic contentURL, contentTitle;
@dynamic backBlock, backButtonHidden;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSString *)playerViewNibNamed
{
    return NSStringFromClass([WZAVPlayerView class]);
}

- (id)playerView
{
    return self.view;
}

- (WZAVPlayerView *)createPlayerView
{
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:[self playerViewNibNamed] owner:self options:nil] objectAtIndex:0];
    return (WZAVPlayerView *)view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self requireAudioPlayback];
    
    // First, check view as PlayerView
    UIView *view = [self playerView];
    if ([view isKindOfClass:[WZAVPlayerView class]]) {
        _playerView = (WZAVPlayerView *)view;
    } else {
        // add playerView from xib file
        _playerView = [self createPlayerView];
        if (_playerView) {
            _playerView.frame = self.view.bounds;
            _playerView.autoresizingMask= UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:_playerView];
        }
    }
    
    _playerView.delegate = self;
    if (!_playerView.backBlock && _backBlock) {
        _playerView.backBlock = _backBlock;
        _backBlock = nil;
    }
    _playerView.backButtonHidden = _backButtonHidden;
    [_playerView disableControls];
    [_playerView resetPlayPosition];
}

- (void)dealloc
{
    [self cancelObserveAVPlayer:_player];
    [self cancelObserveAVPlayerItem:_playerItem];
    
    _player = nil;
    _playerItem = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSString *)localizedStringWithKey:(NSString *)key
{
    return NSLocalizedStringFromTable(key, @"WZAVPlayerStrings", nil);
}

- (void)observeAVPlayer:(AVPlayer *)player
{
    [player addObserver:self
              forKeyPath:kCurrentItemKey
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:WZAVPlayerViewControllerCurrentItemObservationContext];
    
    [player addObserver:self
              forKeyPath:kRateKey
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:WZAVPlayerViewControllerRateObservationContext];
}

- (void)observeAVPlayerItem:(AVPlayerItem *)playerItem
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    [playerItem addObserver:self
                  forKeyPath:kStatusKey
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:WZAVPlayerViewControllerStatusObservationContext];
    
    [playerItem addObserver:self
                  forKeyPath:kPlaybackBufferEmpty
                     options:NSKeyValueObservingOptionNew
                     context:WZAVPlayerViewControllerStatusObservationContext];
    
    [playerItem addObserver:self
                  forKeyPath:kPlaybackLikelyToKeepUp
                     options:NSKeyValueObservingOptionNew
                     context:WZAVPlayerViewControllerStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:playerItem];
    
    if (iOSVersion >= 6.0) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidPlaybackStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:playerItem];
    }
}

- (void)cancelObserveAVPlayer:(AVPlayer *)player
{
    [player removeObserver:self forKeyPath:kCurrentItemKey];
	[player removeObserver:self forKeyPath:kRateKey];
}

- (void)cancelObserveAVPlayerItem:(AVPlayerItem *)playerItem
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    [playerItem removeObserver:self forKeyPath:kStatusKey];
    [playerItem removeObserver:self forKeyPath:kPlaybackBufferEmpty];
    [playerItem removeObserver:self forKeyPath:kPlaybackLikelyToKeepUp];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:playerItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                  object:playerItem];
    if (iOSVersion >= 6.0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemPlaybackStalledNotification
                                                    object:playerItem];
    }
}

- (BOOL)backButtonHidden
{
    return (_playerView) ? _playerView.backButtonHidden : _backButtonHidden;
}

- (void)setBackButtonHidden:(BOOL)hidden
{
    if (_playerView) {
        _playerView.backButtonHidden = hidden;
    } else {
        _backButtonHidden = hidden;
    }    
}

- (WZAVPlayerBlock)backBlock
{
    return (_playerView) ? _playerView.backBlock : _backBlock;
}

- (void)setBackBlock:(WZAVPlayerBlock)backBlock
{
    if (_playerView) {
        _playerView.backBlock = backBlock;
    } else {
        _backBlock = backBlock;
    }
}

- (void)setContentTitle:(NSString *)title
{
    _contentTitle = title;
    _playerView.title = title;
}

- (NSString *)contentTitle
{
    return _contentTitle;
}

- (void)setContentURL:(NSURL*)URL
{
	if (_contentURL != URL) {
        _reopening = NO;
        [self internalSetContentURL:URL];
	}
}

- (NSURL *)contentURL
{
    return _contentURL;
}

- (void)internalSetContentURL:(NSURL*)URL
{
    _contentURL = URL;
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_contentURL options:nil];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    WZAVPlayerViewController *me = self;
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            _readyToPlayTime = 0.0f;
                            [me prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

- (void)requireAudioPlayback
{
    // 動画アプリなのでオーディオ出力がアプリケーションにとって必須のものであると設定する
    // これによりロック状態、サイレント状態でも音声出力が行われる
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
}

- (void)reopenWithPosition:(NSTimeInterval)position
{
    if (_contentURL) {
        if (position > 0) {
            _initialPlaybackTime = position;
        }
        _reopening = YES;
        [self internalSetContentURL:_contentURL];
    }
}

- (void)reopen
{
    // get current position and set it when content is reopened
    double position = CMTimeGetSeconds([_player currentTime]);
    [self reopenWithPosition:position];
}

- (void)tryAutoPlayWithDelay:(NSTimeInterval)delay
{
    WZLogD(@"WZAVPlayerViewController.tryRestartPlayWithDelay:%lf", delay);
    __weak WZAVPlayerViewController *me = self;
    dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (delay * NSEC_PER_SEC));
    dispatch_after(tt, dispatch_get_main_queue(), ^{
        if (_mediaEnded || _playerView.isPaused) { // ignore media is end
            return;
        }
        [me play];
        [me refreshForReadyToPlayIfPlaying];
        [me refreshForReadyToPlayIfPlayingWithDelay:1.0];
    });
}

#pragma mark -
#pragma mark PlayerController

- (void)play
{
    if (_mediaEnded) {
        
    } else {
        [_playerView play];
    }
}

- (void)pause
{
    [_playerView pause];
}

- (void)close
{
    [self hideProgress];
    [_playerView close];
    
    if (_playerItem) {
        [self cancelObserveAVPlayerItem:_playerItem];
        _playerItem = nil;
    }
    if (_player) {
        [self cancelObserveAVPlayer:_player];
        _player = nil;
	}
    
    _mediaEnded = NO;
    _buffering = NO;
    _reopening = NO;
    _contentTitle = nil;
    _contentURL = nil;
}

- (IBAction)back:(id)sender
{
    [self pause:nil];
    if (_backBlock) {
        _backBlock();
    }
}

- (IBAction)playOrPause:(id)sender
{
    if (_playerView.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (IBAction)play:(id)sender
{
	[self play];
}

- (IBAction)pause:(id)sender
{
	[self pause];
}

- (IBAction)close:(id)sender;
{
    [self close];
}

#pragma mark -
#pragma mark Player Item

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    WZLogD(@"WZAVPlayerViewController.playerItemDidReachEnd");
    [self playerDidReachEndPlayback];
}

- (void)playerItemFailedEnd:(NSNotification *)notification
{
    WZLogD(@"WZAVPlayerViewController.playerItemFailedEnd");
}

- (void)playerItemDidPlaybackStalled:(NSNotification *)notification
{
    WZLogD(@"WZAVPlayerViewController.playerItemDidPlaybackStalled");
}

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    // hack! reopen
    if (_readyToPlayTime > 0) {
        if ([error.domain isEqualToString:AVFoundationErrorDomain]) {
            if (error.code == AVErrorMediaServicesWereReset) {
                [_playerView endPlayerTimeObserver];
                [_playerView disableControls];
                [self showProgressWithText:[self localizedStringWithKey:@"Re-Opening..."]];
                [self reopen];
                return;
            }
        }
    }
    
    [self hideProgress];
    [_playerView refreshPlayPosition];
    [_playerView disableControls];
    [_playerView endPlayerTimeObserver];
    [self playerFailedToPrepareForPlayback:error];
}

#pragma mark Prepare to play asset, URL

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
	for (NSString *thisKey in requestedKeys) {
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed) {
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
	}
    
    if (!asset.playable) {
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey,
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"WZAVPayerViewController" code:0 userInfo:errorDict];
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        return;
    }
	   
    if (_playerItem) {
        [self cancelObserveAVPlayerItem:_playerItem];
        _playerItem = nil;
    }
	
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self observeAVPlayerItem:_playerItem];
    
    // create player via play
    if (_player) {
        [self cancelObserveAVPlayer:_player];
        [self playerDidReplaceFromPlayer:_player];
        _player = nil;
	}
    
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:_playerItem];
        [self observeAVPlayer:_player];
    }
    
    if (_player.currentItem != _playerItem) {
        [_player replaceCurrentItemWithPlayerItem:_playerItem];
    }
    
    if (_reopening) {
        _reopening = NO;
    }
    
    // display buffering track when content is not a local file
    _playerView.isSliderAvailableTrackEnabled = !_contentURL.isFileURL;
    
    [self playerDidPrepare];

}

#pragma mark Asset Key Value Observing

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
	if (context == WZAVPlayerViewControllerStatusObservationContext) {
        if ([keyPath isEqualToString:kPlaybackBufferEmpty]) {
            if (_playerItem.playbackBufferEmpty) {
                WZLogD(@"AVPlayerItem.playbackBufferEmpty = YES");
                [self showProgressMessageWithText:[self localizedStringWithKey:@"Loading..."]];
                _buffering = YES;
            } else {
                WZLogD(@"AVPlayerItem.playbackBufferEmpty = NO");
                [self tryAutoPlayWithDelay:5];
            }
        } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUp]) {
            if (_playerItem.playbackLikelyToKeepUp) {
                WZLogD(@"AVPlayerItem.playbackLikelyToKeepUp = YES, Buffering = %d", _buffering);
                if (_buffering) {
                    _buffering = NO;
                    [self tryAutoPlayWithDelay:0.5];
                } else {
                    [self refreshForReadyToPlayIfPlayingWithDelay:0.25];
                }
            } else {
//                WZLogD(@"AVPlayerItem.playbackLikelyToKeepUp = NO");
//                [self showProgressMessageWithText:[self localizedStringWithKey:@"Loading..."]];
//                [_player pause];
            }
            
        } else if ([keyPath isEqualToString:kStatusKey]) {

            [_playerView refreshControls];
            
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            switch (status) {
                case AVPlayerStatusUnknown:
                {
                    WZLogD(@"AVPlayerItem.status = AVPlayerStatusUnknown");
                    [_playerView endPlayerTimeObserver];                    
                    [_playerView refreshPlayPosition];
                    [_playerView disableControls];
                }
                    break;
                    
                case AVPlayerStatusReadyToPlay:
                {
                    WZLogD(@"AVPlayerItem.status = AVPlayerStatusReadyToPlay");

                    // AVPlayer will get this status when it returns from background task.
                    _readyToPlayTime = [[NSDate date] timeIntervalSince1970];
                                        
                    [_playerView beginPlayerTimeObserver];
                    [_playerView enableControls];
                    
                    [self playerDidReadyPlayback];
                    
                    NSTimeInterval initialPlaybackPosition = [self playerInitialPlayPosition];
                    
                    __weak WZAVPlayerViewController *me = self;
                    if (initialPlaybackPosition > 0) {
                        [_playerView seekToTime:initialPlaybackPosition completionHandler:^{
                            [me playerDidBeginPlayback];
                        }];
                        _initialPlaybackTime = 0.0;
                    } else {
                        // AVPlayerStatusReadyToPlay will be fired after seeked on Live Streaming
                        // check position
                        double position = CMTimeGetSeconds([_player currentTime]);
                        if (position < 3) {
                            [me playerDidBeginPlayback];
                        }
                    }
                }
                    break;
                    
                case AVPlayerStatusFailed:
                {
                    WZLogD(@"AVPlayerItem.status = AVPlayerStatusFailed");
                    AVPlayerItem *playerItem = (AVPlayerItem *)object;
                    if (_playerItem == playerItem) {
                        [self assetFailedToPrepareForPlayback:playerItem.error];
                    }
                }
                    break;
            }
        }
	}
    
	else if (context == WZAVPlayerViewControllerRateObservationContext) {
        [_playerView refreshControls];
        // ignore when reopening
        if (_player.rate == 1.0 && !_reopening) {
            [self refreshForReadyToPlayIfPlayingWithDelay:0.5f];
        }
	}

	else if (context == WZAVPlayerViewControllerCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];        
        if (newPlayerItem == (id)[NSNull null]) {
            [_playerView close];
        } else {
            [_playerView close];
            _playerView.player = _player;
            _playerView.videoFillMode = AVLayerVideoGravityResizeAspect;
            [_playerView refreshControls];
        }
	}
    
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
#pragma mark HUD

- (BOOL)progressUserInteractionEnabled
{
    return NO;
}

- (id)showProgressWithText:(NSString *)text
{
    if (!_progressHud) {
        _progressHud = [MBProgressHUD showHUDAddedTo:_playerView animated:YES];
        _progressHud.dimBackground = NO;
        _progressHud.margin = 20.0f;
        _progressHud.userInteractionEnabled = [self progressUserInteractionEnabled];
    }
    _progressHud.labelText = text;
    return _progressHud;
}

- (id)showProgressMessageWithText:(NSString *)text
{
    if (!_progressHud) {
        _progressHud = [MBProgressHUD showHUDAddedTo:_playerView animated:YES];
        _progressHud.dimBackground = NO;
        _progressHud.mode = MBProgressHUDModeIndeterminate;
        _progressHud.userInteractionEnabled = [self progressUserInteractionEnabled];
    }
    _progressHud.labelText = text;
    return _progressHud;
}

- (void)hideProgress
{
    [MBProgressHUD hideHUDForView:_playerView animated:YES];
    _progressHud = nil;
}

- (void)refreshForReadyToPlayIfPlaying
{
    if (_player.rate == 1.0
        // not work playbackLikelyToKeepUp on iOS5??
        //        && _playerItem.playbackLikelyToKeepUp
        && !_playerView.isSeeking) {
        [self hideProgress];
        [_playerView enableControls];
    }
}

- (void)refreshForReadyToPlayIfPlayingWithDelay:(NSTimeInterval)delay
{
    __weak WZAVPlayerViewController *me = self;
    dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (delay * NSEC_PER_SEC));
    dispatch_after(tt, dispatch_get_main_queue(), ^{
        [me refreshForReadyToPlayIfPlaying];
    });
}

#pragma mark - PlayerView Delegate

- (void)playerViewLiveDidChanged:(WZAVPlayerView *)view changeToValue:(BOOL)isLive
{
    // LiveMode to RecordedMode, then reopen and play
    if (!isLive) {
        [self reopenWithPosition:0];
    }
}

- (void)playerViewSeekingBegan:(WZAVPlayerView *)view
{
    if (!_contentURL.isFileURL) {
        [self showProgressMessageWithText:[self localizedStringWithKey:@"Loading..."]];
    }
}

- (void)playerViewSeekingCompletation:(WZAVPlayerView *)view
{
    if (!_contentURL.isFileURL) {
        [self refreshForReadyToPlayIfPlaying];
    }
}

+ (NSString *)AVFoundationErrorEnumStringFromCode:(NSInteger)error
{
    switch (error) {
        case AVErrorUnknown:
            return @"AVErrorUnknown";
            
        case AVErrorOutOfMemory:
            return @"AVErrorOutOfMemory";
            
        case AVErrorSessionNotRunning:
            return @"AVErrorSessionNotRunning";
            
        case AVErrorDeviceAlreadyUsedByAnotherSession:
            return @"AVErrorDeviceAlreadyUsedByAnotherSession";
            
        case AVErrorNoDataCaptured:
            return @"AVErrorNoDataCaptured";
            
        case AVErrorSessionConfigurationChanged:
            return @"AVErrorSessionConfigurationChanged";
            
        case AVErrorDiskFull:
            return @"AVErrorDiskFull";
            
        case AVErrorDeviceWasDisconnected:
            return @"AVErrorDeviceWasDisconnected";
            
        case AVErrorMediaChanged:
            return @"AVErrorMediaChanged";
            
        case AVErrorMaximumDurationReached:
            return @"AVErrorMaximumDurationReached";
            
        case AVErrorMaximumFileSizeReached:
            return @"AVErrorMaximumFileSizeReached";
            
        case AVErrorMediaDiscontinuity:
            return @"AVErrorMediaDiscontinuity";
            
        case AVErrorMaximumNumberOfSamplesForFileFormatReached:
            return @"AVErrorMaximumNumberOfSamplesForFileFormatReached";
            
        case AVErrorDeviceNotConnected:
            return @"AVErrorDeviceNotConnected";
            
        case AVErrorDeviceInUseByAnotherApplication:
            return @"AVErrorDeviceInUseByAnotherApplication";
            
        case AVErrorDeviceLockedForConfigurationByAnotherProcess:
            return @"AVErrorDeviceLockedForConfigurationByAnotherProcess";
            
#if TARGET_OS_IPHONE
        case AVErrorSessionWasInterrupted:
            return @"AVErrorSessionWasInterrupted";
            
        case AVErrorMediaServicesWereReset:
            return @"AVErrorMediaServicesWereReset";
#endif
            
        case AVErrorExportFailed:
            return @"AVErrorExportFailed";
            
        case AVErrorDecodeFailed:
            return @"AVErrorDecodeFailed";
            
        case AVErrorInvalidSourceMedia:
            return @"AVErrorInvalidSourceMedia";
            
        case AVErrorFileAlreadyExists:
            return @"AVErrorFileAlreadyExists";
            
        case AVErrorCompositionTrackSegmentsNotContiguous:
            return @"AVErrorCompositionTrackSegmentsNotContiguous";
            
        case AVErrorInvalidCompositionTrackSegmentDuration:
            return @"AVErrorInvalidCompositionTrackSegmentDuration";
            
        case AVErrorInvalidCompositionTrackSegmentSourceStartTime:
            return @"AVErrorInvalidCompositionTrackSegmentSourceStartTime";
            
        case AVErrorInvalidCompositionTrackSegmentSourceDuration:
            return @"AVErrorInvalidCompositionTrackSegmentSourceDuration";
            
        case AVErrorFileFormatNotRecognized:
            return @"AVErrorFileFormatNotRecognized";
            
        case AVErrorFileFailedToParse:
            return @"AVErrorFileFailedToParse";
            
        case AVErrorMaximumStillImageCaptureRequestsExceeded:
            return @"AVErrorMaximumStillImageCaptureRequestsExceeded";
            
        case AVErrorContentIsProtected:
            return @"AVErrorContentIsProtected";
            
        case AVErrorNoImageAtTime:
            return @"AVErrorNoImageAtTime";
            
        case AVErrorDecoderNotFound:
            return @"AVErrorDecoderNotFound";
            
        case AVErrorEncoderNotFound:
            return @"AVErrorEncoderNotFound";
            
        case AVErrorContentIsNotAuthorized:
            return @"AVErrorContentIsNotAuthorized";
            
        case AVErrorApplicationIsNotAuthorized:
            return @"AVErrorApplicationIsNotAuthorized";
            
#if TARGET_OS_IPHONE
        case AVErrorDeviceIsNotAvailableInBackground:
            return @"AVErrorDeviceIsNotAvailableInBackground";
#endif
            
        case AVErrorOperationNotSupportedForAsset:
            return @"AVErrorOperationNotSupportedForAsset";
            
        case AVErrorDecoderTemporarilyUnavailable:
            return @"AVErrorDecoderTemporarilyUnavailable";
            
        case AVErrorEncoderTemporarilyUnavailable:
            return @"AVErrorEncoderTemporarilyUnavailable";
            
        case AVErrorInvalidVideoComposition:
            return @"AVErrorInvalidVideoComposition";
            
        case AVErrorReferenceForbiddenByReferencePolicy:
            return @"AVErrorReferenceForbiddenByReferencePolicy";
            
        case AVErrorInvalidOutputURLPathExtension:
            return @"AVErrorInvalidOutputURLPathExtension";
            
        case AVErrorScreenCaptureFailed:
            return @"AVErrorScreenCaptureFailed";
            
        case AVErrorDisplayWasDisabled:
            return @"AVErrorDisplayWasDisabled";
            
        case AVErrorTorchLevelUnavailable:
            return @"AVErrorTorchLevelUnavailable";
            
#if TARGET_OS_IPHONE
        case AVErrorOperationInterrupted:
            return @"AVErrorOperationInterrupted";
#endif
            
        case AVErrorIncompatibleAsset:
            return @"AVErrorIncompatibleAsset";
            
        case AVErrorFailedToLoadMediaData:
            return @"AVErrorFailedToLoadMediaData";
            
        case AVErrorServerIncorrectlyConfigured:
            return @"AVErrorServerIncorrectlyConfigured";
            
        default:
            return @"";
    }
}

@end

#pragma mark -

@implementation WZAVPlayerViewController (Protected)

- (NSTimeInterval)playerInitialPlayPosition
{
    return _initialPlaybackTime;
}

- (void)playerDidPrepare
{
    WZLogD(@"WZAVPlayerViewController.playerDidPrepare");
    _mediaEnded = NO;
    [_playerView refreshControls];
    [_playerView resetPlayPosition];
}

- (void)playerDidReadyPlayback
{
    WZLogD(@"WZAVPlayerViewController.playerDidReadyPlayback");
    _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    [self hideProgress];
    [_playerView refreshControls];
}

- (void)playerDidBeginPlayback
{
    WZLogD(@"WZAVPlayerViewController.playerDidBeginPlayback");
    [_playerView dismissOverlayWithDuration:0.25f];
    [self tryAutoPlayWithDelay:0.5];
}

- (void)playerDidEndPlayback
{
    WZLogD(@"WZAVPlayerViewController.playerDidEndPlayback");
    [self close];
}

- (void)playerDidReachEndPlayback
{
    WZLogD(@"WZAVPlayerViewController.playerDidReachEndPlayback");
    _mediaEnded = YES;
    [self close];
}

- (void)playerDidReplaceFromPlayer:(AVPlayer *)oldPlayer
{
    WZLogD(@"WZAVPlayerViewController.playerDidReplaceFromPlayer");
}

- (void)playerFailedToPrepareForPlayback:(NSError *)error
{
    NSString *errorMessage = error.localizedDescription;
    
    if (!self.isBeingDismissed) {
        
        if (error) {
            NSString *description;
            if ([error.domain isEqualToString:AVFoundationErrorDomain]) {
#if DEBUG
                NSString *enumString = [WZAVPlayerViewController AVFoundationErrorEnumStringFromCode:error.code];
                errorMessage = [NSString stringWithFormat:@"%@(%@) %@", error.localizedDescription, enumString, error.localizedRecoverySuggestion];
#else
                if (error.localizedRecoverySuggestion) {
                    errorMessage = [NSString stringWithFormat:@"%@ %@", error.localizedDescription, error.localizedRecoverySuggestion];
                }
#endif
            }
        }
        
        __weak WZAVPlayerViewController *me = self;
        [UIAlertView showAlertViewWithTitle:[self localizedStringWithKey:@"Can Not Play"]
                                    message:errorMessage
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil
                                    handler:^(UIAlertView *view, NSInteger buttonIndex) {
                                        // Execute DidEndPlayback when catch error before ReadyToPlay
                                        if (_readyToPlayTime == 0) {
                                            [me playerDidEndPlayback];
                                        }
                                    }];
    }
}

@end
