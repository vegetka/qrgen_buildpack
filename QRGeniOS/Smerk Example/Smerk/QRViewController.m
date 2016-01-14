//
//  SMKQRViewController.m
//  Smerk
//
//  Created by Patrick Quinn on 21/12/2015.
//  Copyright © 2015 Smerk. All rights reserved.
//

#import "QRViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface QRViewController ()

@end

@implementation QRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.cameraView setImage:image];
    
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    
    
    [self generateTone];
    // Do any additional setup after loading the view.
}


- (void)generateTone
{
    //  First, we need to establish which Audio Unit we want.
    
    //  We start with its description, which is:
    AudioComponentDescription outputUnitDescription = {
        .componentType         = kAudioUnitType_Output,
        .componentSubType      = kAudioUnitSubType_GenericOutput,
        .componentManufacturer = kAudioUnitManufacturer_Apple
    };
    
    //  Next, we get the first (and only) component corresponding to that description
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputUnitDescription);
    
    //  Now we can create an instance of that component, which will create an
    //  instance of the Audio Unit we're looking for (the default output)
    AudioComponentInstanceNew(outputComponent, &outputUnit);
    AudioUnitInitialize(outputUnit);
    
    //  Next we'll tell the output unit what format our generated audio will
    //  be in. Generally speaking, you'll want to stick to sane formats, since
    //  the output unit won't accept every single possible stream format.
    //  Here, we're specifying floating point samples with a sample rate of
    //  44100 Hz in mono (i.e. 1 channel)
    AudioStreamBasicDescription ASBD = {
        .mSampleRate       = 44100,
        .mFormatID         = kAudioFormatLinearPCM,
        .mFormatFlags      = kAudioFormatFlagsNativeFloatPacked,
        .mChannelsPerFrame = 1,
        .mFramesPerPacket  = 1,
        .mBitsPerChannel   = sizeof(Float32) * 8,
        .mBytesPerPacket   = sizeof(Float32),
        .mBytesPerFrame    = sizeof(Float32)
    };
    
    AudioUnitSetProperty(outputUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &ASBD,
                         sizeof(ASBD));
    
    //  Next step is to tell our output unit which function we'd like it
    //  to call to get audio samples. We'll also pass in a context pointer,
    //  which can be a pointer to anything you need to maintain state between
    //  render callbacks. We only need to point to a double which represents
    //  the current phase of the sine wave we're creating.
    AURenderCallbackStruct callbackInfo = {
        .inputProc       = SineWaveRenderCallback,
        .inputProcRefCon = &renderPhase
    };
    
    AudioUnitSetProperty(outputUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         0,
                         &callbackInfo,
                         sizeof(callbackInfo));
    
    //  Here we're telling the output unit to start requesting audio samples
    //  from our render callback. This is the line of code that starts actually
    //  sending audio to your speakers.
    AudioOutputUnitStart(outputUnit);
}

// This is our render callback. It will be called very frequently for short
// buffers of audio (512 samples per call on my machine).
OSStatus SineWaveRenderCallback(void * inRefCon,
                                AudioUnitRenderActionFlags * ioActionFlags,
                                const AudioTimeStamp * inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList * ioData)
{
    // inRefCon is the context pointer we passed in earlier when setting the render callback
    double currentPhase = *((double *)inRefCon);
    // ioData is where we're supposed to put the audio samples we've created
    Float32 * outputBuffer = (Float32 *)ioData->mBuffers[0].mData;
    const double frequency = 440.;
    const double phaseStep = (frequency / 44100.) * (M_PI * 2.);
    
    for(int i = 0; i < inNumberFrames; i++) {
        outputBuffer[i] = sin(currentPhase);
        currentPhase += phaseStep;
    }
    
    // If we were doing stereo (or more), this would copy our sine wave samples
    // to all of the remaining channels
    for(int i = 1; i < ioData->mNumberBuffers; i++) {
        memcpy(ioData->mBuffers[i].mData, outputBuffer, ioData->mBuffers[i].mDataByteSize);
    }
    
    // writing the current phase back to inRefCon so we can use it on the next call
    *((double *)inRefCon) = currentPhase;
    return noErr;
}

- (void)nukeTone
{
    AudioOutputUnitStop(outputUnit);
    AudioUnitUninitialize(outputUnit);
    AudioComponentInstanceDispose(outputUnit);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CIImage *)createQRForString:(NSString *)qrString {
    NSData *stringData = [qrString dataUsingEncoding: NSISOLatin1StringEncoding];
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    
    return qrFilter.outputImage;
}

- (UIImage *)makeUIImageFromCIImage:(CIImage *)ciImage {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    
    UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return uiImage;
}

-(void)displayImage: (NSString*)inputString {
    
    inputString = [inputString stringByAppendingString:@"+patrick.quinn@gramma-music.com+"];
    inputString = [inputString stringByAppendingString:@"password234"];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(10.0f, 10.0f);
    CIImage *output = [[self createQRForString:inputString] imageByApplyingTransform: transform];
    
    UIImage *qrcode = [self makeUIImageFromCIImage:output];
    
    image = qrcode;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
