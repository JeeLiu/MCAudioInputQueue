//
//  ViewController.m
//  MCAudioInputQueue
//
//  Created by Chengyin on 15-4-7.
//  Copyright (c) 2015年 Chengyin. All rights reserved.
//

#import "ViewController.h"
#import "MCAudioInputQueue.h"
#import "AVAudioPlayer+PCM.h"
#import <AVFoundation/AVAudioSession.h>

@interface ViewController ()<MCAudioInputQueueDelegate>
{
@private
    MCAudioInputQueue *_recorder;
    AudioStreamBasicDescription _format;
    BOOL _started;
    
    NSMutableData *_data;
    AVAudioPlayer *_player;
}
@property (nonatomic,strong) IBOutlet UIButton *startOrStopButton;
@property (nonatomic,strong) IBOutlet UIButton *playButton;
@end

@implementation ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _format.mFormatID = kAudioFormatLinearPCM;
    _format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    _format.mBitsPerChannel = 16;
    _format.mChannelsPerFrame = 1;
    _format.mBytesPerPacket = _format.mBytesPerFrame = (_format.mBitsPerChannel / 8) * _format.mChannelsPerFrame;
    _format.mFramesPerPacket = 1;
    _format.mSampleRate = 8000.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_interrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_interrupted:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)dealloc
{
    [_recorder stop];
    [_player stop];
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ui actions
- (IBAction)startOrStop:(id)sender
{
    if (_started)
    {
        [self _stopRecord];
    }
    else
    {
        [self _startRecord];
    }
}

- (IBAction)play:(id)sender
{
    [self _play];
}

- (void)_refreshUI
{
    if (_started)
    {
        [self.startOrStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else
    {
        [self.startOrStopButton setTitle:@"Start" forState:UIControlStateNormal];
    }
    
    self.playButton.enabled = !_started && _data.length > 0;
}

#pragma mark - play
- (void)_play
{
    _player = [[AVAudioPlayer alloc] initWithPcmData:_data pcmFormat:_format error:nil];
    [_player play];
}

#pragma mark - record
- (void)_startRecord
{
    if (_started)
    {
        return;
    }
    
    [_player stop];
    _started = YES;
    
    _data = [NSMutableData data];
    _recorder = [[MCAudioInputQueue alloc] initWithFormat:_format bufferDuration:1 delegate:self];
    [_recorder start];
    
    [self _refreshUI];
}

- (void)_stopRecord
{
    if (!_started)
    {
        return;
    }
    
    _started = NO;
    
    [self _refreshUI];
}

#pragma mark - interrupt
- (void)_interrupted:(NSNotification *)notification
{
    [self _stopRecord];
    [_player stop];
}

#pragma mark - inputqueue delegate
- (void)inputQueue:(MCAudioInputQueue *)inputQueue inputData:(NSData *)data numberOfPackets:(UInt32)numberOfPackets
{
    if (data)
    {
        [_data appendData:data];
    }
}

- (void)inputQueue:(MCAudioInputQueue *)inputQueue errorOccur:(NSError *)error
{
    [self _stopRecord];
}
@end