//
//  VideoRecorder.m
//  BHFaceAliveDetect
//
//  Created by 陈贤彬 on 16/5/18.
//  Copyright (c) 2016年 BoomHope. All rights reserved.
//

#import "VideoRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>


#define screenH [UIScreen mainScreen].bounds.size.height

#define ivoRate screenH / 568

@interface

VideoRecorder () {
    
    int frame;
    
}

@property (nonatomic, retain) AVAssetWriter* videoWriter;

@property (nonatomic, retain) AVAssetWriterInput* videoWriterInput;

@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor* adaptor;

@end

@implementation VideoRecorder

- (void)setupVideoWriter
{
    
    
    if (self.videoTime == 0) {
        return;
    }
    
    UIScreen* mainScreen = [UIScreen mainScreen];
    
    CGSize size = CGSizeMake(mainScreen.bounds.size.width,
                             mainScreen.bounds.size.height - (100 * ivoRate + 64));
    
    NSString* doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString* fileName = nil;
    
    fileName = [NSString stringWithFormat:@"Alive.mp4"];
    
    NSString* viedoPath = [doc stringByAppendingPathComponent:fileName];
    
    self.viedoPath = viedoPath;
    
    NSError* error = nil;
    
    unlink([viedoPath UTF8String]);
    
    self.videoWriter =
    [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:viedoPath] fileType:AVFileTypeQuickTimeMovie error:&error];
    
    NSParameterAssert(_videoWriter);
    
    if (error) {
        
        NSLog(@"error = %@", [error localizedDescription]);
    }
    
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithLong:250000], AVVideoAverageBitRateKey, nil];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:size.width], AVVideoWidthKey, [NSNumber numberWithInt:size.height], AVVideoHeightKey, videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                               outputSettings:videoSettings];
    
    NSParameterAssert(_videoWriterInput);
    
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary* sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                    sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary];
    
    
    
    if ([_videoWriter canAddInput:_videoWriterInput]) {
        
//        NSLog(@"I can add this input");
    } else {
        
//        NSLog(@"i can't add this input");
    }
    if (_videoWriter.status != 1) {
        
        [_videoWriter addInput:_videoWriterInput];
        NSParameterAssert(_videoWriterInput);
        NSParameterAssert([_videoWriter canAddInput:_videoWriterInput]);
    }
    
    
    
}

- (void)finishRecorder
{
    
    [NSThread sleepForTimeInterval:0.1];
    if (self.videoTime == 0 || self.videoWriter.status == 0) {
        return;
    }
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"录制完成");
        
        if (self.videoWriter.status != AVAssetWriterStatusFailed && self.videoWriter.status == AVAssetWriterStatusCompleted) {
            self->_videoWriter = nil;
            self->_adaptor = nil;
            self->_videoWriterInput = nil;
        }
        
    }];
}

- (void)recordVideo:(CMSampleBufferRef)sampleBuffer captureOutput:(AVCaptureOutput*)captureOutput
         dataOutput:(AVCaptureOutput*)dataOutput
{
    
    if (self.videoTime == 0) {
        return;
    }
    
    self.status = self.videoWriter.status;
    
    
    CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (frame == 0 && self.videoWriter.status != AVAssetWriterStatusWriting && self.videoWriter.status != AVAssetWriterStatusFailed) {
        
        if (![self.videoWriter startWriting] && self.videoWriter.status == 0) {
            
            return;
        }else {
            
            [self.videoWriter startSessionAtSourceTime:lastSampleTime];
            
            
            dispatch_after( dispatch_time(DISPATCH_TIME_NOW,
                                          (int64_t)((self.videoTime - 1) * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                               
                               if (self.videoWriter.status != AVAssetWriterStatusCompleted) {
                                   
                                   if (![self->_videoWriterInput isReadyForMoreMediaData]) {
                                       
                                       [self finishRecorder];
                                   }
                               }
                               
                           });
            
            
        }
        
        
    }
    
    
    
    if (captureOutput == dataOutput) {
        
        if (self.videoWriter.status > AVAssetWriterStatusWriting) {
            
            if (_videoWriter.status == AVAssetWriterStatusFailed) {
                
                NSLog(@"Error: %@", _videoWriter.error);
                self.isEnd = YES;
                
                return;
            }
        }
        
        
        //        写数据
        if ([_videoWriterInput isReadyForMoreMediaData]) {
            
            if (![_videoWriterInput appendSampleBuffer:sampleBuffer]) {
                
//                NSLog(@"Unable to write to video input");
                
                
            } else {
                
//                NSLog(@"already write vidio");
            }
        }
    }
    
    
    frame++;
    
    
}

@end


