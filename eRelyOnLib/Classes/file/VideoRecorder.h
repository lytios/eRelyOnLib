//
//  VideoRecorder.h
//  BHFaceAliveDetect
//
//  Created by 陈贤彬 on 16/5/18.
//  Copyright (c) 2016年 BoomHope. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoRecorder : NSObject

@property (nonatomic,copy) NSString *viedoPath;

@property (nonatomic,assign) int videoTime;

@property (nonatomic,assign) NSInteger status;

@property (nonatomic,assign) BOOL isEnd;

-(void)setupVideoWriter;

-(void)finishRecorder;

-(void)recordVideo:(CMSampleBufferRef)sampleBuffer captureOutput:(AVCaptureOutput *)captureOutput dataOutput:(AVCaptureOutput *)dataOutput;


@end
