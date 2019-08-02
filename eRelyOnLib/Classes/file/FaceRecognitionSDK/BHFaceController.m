//
//  BHFaceController.m
//
//
//  Created by DF-Mac on 17/4/28.
//  Copyright © 2017年 BoomHope. All rights reserved.
//

#import "BHFaceController.h"
#import "BHFaceCommon.h"
#import "BHFaceDetector.h"
#import "STTracker.h"
#import "SZNumberLabel.h"
#import "UIView+STLayout.h"

#import "ToolView.h"
#import "UILabel+BHLabel.h"
#import "UIImage+fixOrientation.h"

#import "VideoRecorder.h"
#import <ImageIO/ImageIO.h>
#import "BaseMacro.h"
#import "UIView+Frame.h"
#define kNavColorRGBColor [UIColor colorWithRed:226/255.0f green:33/255.0f blue:33/255.0f alpha:1] // 导航栏颜色

#define  myMargin  20
#define  btnH  44
#define barH 64

#define backBtnH 25
#define backBtnW 13

#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define buttonH  44
#define textFieldH 30
#define subviewMargin 10


#define successW 50

#define successH 50

#define sIVW 50
#define sIVH 50

#define sLW 100
#define sLH 50

#define Radius 5


#define screenH [UIScreen mainScreen].bounds.size.height

#define screenW [UIScreen mainScreen].bounds.size.width

#define ivRate screenH/568

#define ivWRate screenW/320

@interface BHFaceController () <
STLivenessDetectorDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate> {

    dispatch_queue_t _callBackQueue;

    NSArray *_arrDetection;

    BOOL isRecording;

    BOOL isPromptWindow;

    livingResultsType livingResult;

}
@property (nonatomic, copy) AliveFace backData;

@property(nonatomic, copy) NSString *strBundlePath;
@property(nonatomic,strong)UIAlertController *alertVC;

@property(nonatomic, strong) STTracker *tracker;
@property(nonatomic, strong) BHImage *faceImage;
@property(nonatomic, strong) STLivenessDetector *detector;

@property(nonatomic, weak) id<STLivenessDetectorDelegate> delegate;
//完成步骤的枚举
@property(nonatomic, assign) LivefaceDetectionType *livefaceDetectionType;

@property(nonatomic, strong) UIImageView *imageMaskView;

@property(nonatomic, strong) UIView *cbgView;

@property(nonatomic, strong) UIImageView *imageAnimationView;
@property(nonatomic, strong) UIImageView *tickingImageView;

@property(nonatomic, strong) UILabel *lblCountDown;

@property(nonatomic, strong) UILabel *lblPrompt;

@property(nonatomic, assign) float fCurrentPlayerVolume;

@property(nonatomic, strong) AVAudioPlayer *blinkAudioPlayer;
@property(nonatomic, strong) AVAudioPlayer *mouthAudioPlayer;
@property(nonatomic, strong) AVAudioPlayer *nodAudioPlayer;
@property(nonatomic, strong) AVAudioPlayer *yawAudioPlayer;

@property(nonatomic, strong) AVAudioPlayer *currentAudioPlayer;
@property(nonatomic, strong) AVAudioPlayer *goodAudioPlayer;

@property(nonatomic, strong) NSArray *arrMothImages;
@property(nonatomic, strong) NSArray *arrYawImages;
@property(nonatomic, strong) NSArray *arrPitchImages;
@property(nonatomic, strong) NSArray *arrBlinkImages;

@property(nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property(nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDevice *device;
@property(nonatomic, strong) AVCaptureDevice *deviceFront;
@property(nonatomic, assign) CGRect previewframe;

@property(nonatomic, assign) BOOL bShowCountDownView;

@property(nonatomic, weak) ToolView *toolView;

@property(nonatomic, strong) UIView *alertBgView;
@property(nonatomic, strong) VideoRecorder *videoRecorder;



@end

@implementation BHFaceController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = BlueColor;//0x4F5BC4
}

- (void)setNavi
{
    UIView *navi = [UIView new];
    if (@available(iOS 11.0, *)) {
        navi.frame = CGRectMake(0, 0, SCREENWIDTH, TopBarHeight_xs);
    } else {
        // Fallback on earlier versions
        navi.frame = CGRectMake(0, 0, SCREENWIDTH, TopBarHeight);
    }
    navi.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navi];
    
    UIImageView *leftIV = [UIImageView new];
    leftIV.frame = CGRectMake(15, navi.height-15-18, 34, 18);
    leftIV.image = [UIImage imageNamed:@"back"];
    [navi addSubview:leftIV];
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(8, navi.height-40, 48, 28);
    leftBtn.backgroundColor = ClearColor;
    [leftBtn addTarget:self action:@selector(leftBtnBackClick) forControlEvents:UIControlEventTouchUpInside];
    [navi addSubview:leftBtn];
    
    UILabel *titleLab = [UILabel new];
    CGFloat left = 30+18;
    titleLab.frame = CGRectMake(left, navi.height-13-18, SCREENWIDTH-96, 18);
    titleLab.textColor = WhiteTextColor;
    titleLab.font = iphone5x_4_0?FontWithSize(15): FontSemiboldSize(18);
    titleLab.text = @"活体检测";
    titleLab.textAlignment = NSTextAlignmentCenter;
    [navi addSubview:titleLab];
}

- (void)leftBtnBackClick
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initWithDuration:(double)dDurationPerModel
     resourcesBundlePath:(NSString *)strBundlePath
               modelPath:(NSString *)strModelPath
      financeLicensePath:(NSString *)strFinanceLicensePath {

    if (self) {

        self.tracker = [[STTracker alloc] initWithModelPath:strModelPath
                                         financeLicensePath:strFinanceLicensePath];
        self.detector =
        [[STLivenessDetector alloc] initWithDuration:dDurationPerModel
                                           modelPath:strModelPath
                                  financeLicensePath:strFinanceLicensePath];

        self.bShowCountDownView = dDurationPerModel > 0;

        if (!strBundlePath || [strBundlePath isEqualToString:@""] ||
            ![[NSFileManager defaultManager] fileExistsAtPath:strBundlePath]) {
            NSLog(@"资源文件错误");
            return;

        }
        self.strBundlePath = strBundlePath;

        [self setComplexity:LIVE_COMPLEXITY_HARD];
        self.bVoicePrompt = YES;
        self.fCurrentPlayerVolume = 0.8;

    }

}

- (void) callBackQueue:(dispatch_queue_t)queue
     detectionSequence:(NSArray *)arrDetection {


    if (!arrDetection) { // 动作序列
        NSLog(@"  请检测动作序列 !");
    } else {
        self.previewframe = CGRectMake(0, 0, kSTScreenWidth, kSTScreenHeight);

        double prepareCenterX = kSTScreenWidth / 2.0;
        double prepareCenterY = kSTScreenHeight / 2.0;
        double prepareRadius = kSTScreenWidth / 2.5;

        [self.tracker setDelegate:self
                    callBackQueue:queue
               prepareCenterPoint:CGPointMake(prepareCenterX, prepareCenterY)
                    prepareRadius:prepareRadius];

        [self.detector setDelegate:self
                     callBackQueue:queue
                 detectionSequence:arrDetection];

        _arrDetection = [arrDetection mutableCopy];


    }


    if (_callBackQueue != queue) {
        _callBackQueue = queue;
    }
}

- (void)setComplexity:(LivefaceComplexity)iComplexity {

    
    if (self.detector) {
        [self.detector setComplexity:iComplexity];
    }


}

- (void)setBVoicePrompt:(BOOL)bVoicePrompt {
    _bVoicePrompt = bVoicePrompt;

    [self setPlayerVolume];
}


// 开始检测
- (void)startDetection {
    [self.tracker startTracking];
}

- (void)cancelDetection {
    [self.tracker stopTracking];
    [self.detector cancelDetection];
}

+ (NSString *)getSDKVersion {
    return [STLivenessDetector getSDKVersion];
}
#pragma - mark -
#pragma - mark Life Cycle

- (void)loadView {
    [super loadView];

    [self displayViewsIfRunning:NO];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //[self setNavi];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString* strResourcesBundlePath = [[NSBundle mainBundle] pathForResource:@"BHFace_Resource" ofType:@"bundle"];
    
   
    
    
    // 获取模型路径
    //NSString* strModelPath = [[NSBundle mainBundle] pathForResource:@"face_1.0" ofType:@"model"];
    NSString* strModelPath = [[NSBundle bundleWithPath:strResourcesBundlePath] pathForResource:@"face_1.0" ofType:@"model"];
    // 获取授权文件路径
    //NSString* strFinanceLicensePath = [[NSBundle mainBundle] pathForResource:@"bh_liveness" ofType:@"lic"];
    NSString* strFinanceLicensePath = [[NSBundle mainBundle] pathForResource:@"bh_liveness" ofType:@"lic"];

    if (self.movementTestTime > 1) {
        [self initWithDuration:self.movementTestTime resourcesBundlePath:strResourcesBundlePath modelPath:strModelPath financeLicensePath:strFinanceLicensePath];
    }else {
        [self initWithDuration:10 resourcesBundlePath:strResourcesBundlePath modelPath:strModelPath financeLicensePath:strFinanceLicensePath];
    }

    self.navigationController.navigationBarHidden = NO;

    UIView *cbgView = [[UIView alloc]
                       initWithFrame:CGRectMake(0, 0, kSTScreenWidth, kSTScreenHeight)];
    self.cbgView = cbgView;
    cbgView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:cbgView];

    self.view.backgroundColor = [UIColor colorWithRed:196.0/255.0 green:196/255.0 blue:196.0/255.0 alpha:1];

    // 开启相机
    BOOL bSetupCaptureSession = [self setupCaptureSession];

    if (!bSetupCaptureSession) {
//        return; // 使用模拟器可把此次注释
    }

    [self setupUI];

    [self setupAudio];


    NSMutableArray* liveMSqArr = [NSMutableArray new];
    NSString *numStr = @"1";
    int num;

    // 为了让文档里的动作序列与枚举值相对应,进行替换  LivefaceDetectionType(枚举)
    for (int i = 0; i < self.aliveTypeArr.count; i++) {

        num = [_aliveTypeArr[i] intValue];
        switch (num) {
            case 0:
                numStr = @"1"; // 眨眼对应 1
                break;
            case 1:
                numStr = @"3"; // 张嘴对应 3
                break;
            case 2:
                numStr = @"4"; // 摇头对应 4
                break;
            case 3:
                numStr = @"2"; // 点头对应 2
                break;
            default:
                NSLog(@"动作序列参数错误");
                return;

        }

        [liveMSqArr addObject:numStr];


    }

    [self callBackQueue:dispatch_get_main_queue() detectionSequence:liveMSqArr];


}


- (void)setupUI
{
        // 导航栏部分
        UIImage *image=[self imageWithFullFileName:@"btn_back.png"];
        CGSize size=CGSizeMake(backBtnW, backBtnH);
        image=[UIImage scaleImage:image ToSize:size];
        image=[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(back)];

        self.navigationItem.titleView=[UILabel labelWithText:@"身份验证" textColor:[UIColor whiteColor] frame:self.navigationItem.titleView.frame];
        self.view.backgroundColor = [UIColor blackColor];


        UIImage *imageMask = [self imageWithFullFileName:@"face-recognition_no-face.png"];

        UIImage *imageMouth1 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imageMouth2 = [self imageWithFullFileName:@"Boot_animation_open_one_s_mouth.png"];

        UIImage *imagePitch1 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imagePitch2 = [self imageWithFullFileName:@"Boot-animation_nod.png"];
        UIImage *imagePitch3 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imagePitch4 = [self imageWithFullFileName:@"Boot-animation_nod.png"];
        UIImage *imagePitch5 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];

        UIImage *imageBlink1 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imageBlink2 = [self imageWithFullFileName:@"Boot_animation_blink.png"];

        UIImage *imageYaw1 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imageYaw2 = [self imageWithFullFileName:@"Boot_animation_face_to_turn_left.png"];
        UIImage *imageYaw3 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];
        UIImage *imageYaw4 =
        [self imageWithFullFileName:@"Boot_animation_face_to_turn_right.png"];
        UIImage *imageYaw5 = [self imageWithFullFileName:@"Boot_animation_the_face.png"];

        self.arrMothImages = [NSArray arrayWithObjects:imageMouth1, imageMouth2, nil];

        self.arrPitchImages = [NSArray
                               arrayWithObjects:imagePitch1, imagePitch2, imagePitch3, imagePitch4,
                               imagePitch5, imagePitch4, imagePitch3, imagePitch2, nil];
        self.arrBlinkImages =
        [NSArray arrayWithObjects:imageBlink1, imageBlink2, nil];
        self.arrYawImages = [NSArray arrayWithObjects:imageYaw1, imageYaw2, imageYaw3,
                             imageYaw4, imageYaw5, imageYaw4,
                             imageYaw3, imageYaw2, nil];




    self.edgesForExtendedLayout = UIRectEdgeNone;

    BOOL bNavigationBarHidden = self.navigationController.navigationBar.hidden;

    CGFloat fBarHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat fViewHeight = self.view.frame.size.height-64;

    if (!bNavigationBarHidden) {
        fViewHeight = kSTScreenHeight - fBarHeight;
    }

    self.imageMaskView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, kSTScreenWidth, fViewHeight-30)];
    self.imageMaskView.image = imageMask;
    self.imageMaskView.userInteractionEnabled = YES;
    self.imageMaskView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.imageMaskView];


    //    添加提示label

    UIView *labelView = [[UIView alloc] init];
    labelView.backgroundColor = [UIColor whiteColor];
    CGFloat lvH = 40*ivRate;
    CGFloat lvW = self.view.frame.size.width;
    CGFloat lvX = 0;
    CGFloat lvY = 0;
    labelView.frame = CGRectMake(lvX, lvY, lvW, lvH);
    [self.view addSubview:labelView];
    //
    UILabel *label = [[UILabel alloc] init];
    label.text = @"请保持人脸出现在框内";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:15];
    label.textColor = [UIColor lightGrayColor];

    CGFloat lbH = lvH;
    CGFloat margin = 30;
    CGFloat lbX = margin;
    CGFloat lbW = labelView.frame.size.width-2*margin;

    label.frame = CGRectMake(lbX, 0, lbW, lbH);

    [labelView addSubview:label];

    ToolView *toolView = [[ToolView alloc] init];
    toolView.animationView.image = [self imageWithFullFileName:@"Boot_animation_the_face"];

    self.toolView = toolView;

    CGFloat tvH = 90*ivRate;
    CGFloat tvW = screenW;
    CGFloat tvX = 0;
    CGFloat tvY = screenH-tvH;

    if([self.navigationController visibleViewController]){
        toolView.frame = CGRectMake(tvX, tvY - 64, tvW, tvH);
    }else {
        toolView.frame = CGRectMake(tvX, tvY, tvW, tvH);
    }

    [self.view addSubview:toolView];

    self.imageAnimationView = toolView.animationView;

    self.lblPrompt = toolView.aliveLabel;

    self.lblCountDown = toolView.tickLabel;

}


- (void)Restart {
    [self.tracker startTracking];
}

- (void)setupAudio {

    NSString *strBlinkPath = [self audioPathWithFullFileName:@"st_notice_blink.mp3"];
    self.blinkAudioPlayer = [[AVAudioPlayer alloc]
                             initWithContentsOfURL:[NSURL fileURLWithPath:strBlinkPath]
                             error:nil];
    NSLog(@"strBlinkPath=%@",strBlinkPath);

    self.blinkAudioPlayer.volume = self.fCurrentPlayerVolume;
    self.blinkAudioPlayer.numberOfLoops = 0;
    [self.blinkAudioPlayer prepareToPlay];

    NSString *strMouthPath = [self audioPathWithFullFileName:@"st_notice_mouth.mp3"];
    self.mouthAudioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:strMouthPath] error:nil];
    self.mouthAudioPlayer.volume = _fCurrentPlayerVolume;
    self.mouthAudioPlayer.numberOfLoops = 0;
    [self.mouthAudioPlayer prepareToPlay];

    NSString *strNodPath = [self audioPathWithFullFileName:@"st_notice_nod.mp3"];
    self.nodAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strNodPath]error:nil];
    self.nodAudioPlayer.volume = _fCurrentPlayerVolume;
    self.nodAudioPlayer.numberOfLoops = 0;
    [self.nodAudioPlayer prepareToPlay];

    NSString *strYawPath = [self audioPathWithFullFileName:@"st_notice_yaw.mp3"];
    self.yawAudioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:strYawPath]error:nil];
    self.yawAudioPlayer.volume = _fCurrentPlayerVolume;
    self.yawAudioPlayer.numberOfLoops = 0;
    [self.yawAudioPlayer prepareToPlay];

    NSString *strGoodPath = [self audioPathWithFullFileName:@"good.wav"];
    self.goodAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strGoodPath] error:nil];
    self.goodAudioPlayer.volume = _fCurrentPlayerVolume;
    self.goodAudioPlayer.numberOfLoops = 0;
    [self.goodAudioPlayer prepareToPlay];
}

- (BOOL)setupCaptureSession {

    self.session = [[AVCaptureSession alloc] init];

    self.session.sessionPreset = AVCaptureSessionPreset640x480;

    self.device = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] lastObject];

    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    self.deviceInput = input;

    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }

    if (!input) {
        if (self.delegate &&
            [self.delegate
             respondsToSelector:@selector(livenessDidFailWithErrorType:
                                          detectionType:
                                          detectionIndex:
                                          data:
                                          stImages:)]) {
                 dispatch_async(_callBackQueue, ^{
                     [self.delegate livenessDidFailWithErrorType:LIVENESS_CAMERA_ERROR
                                                   detectionType:[[self->_arrDetection firstObject]
                                                                  integerValue]
                                                  detectionIndex:0
                                                            data:nil
                                                        stImages:nil];
                 });
             }
        return NO;
    }

    self.dataOutput = [[AVCaptureVideoDataOutput alloc] init];

    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
    }
    // 相机初始化
    AVCaptureConnection *connection = [self.dataOutput.connections firstObject];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;

    [self.dataOutput setVideoSettings: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];

    dispatch_queue_t queueBuffer = dispatch_queue_create("LIVENESS_BUFFER_QUEUE", NULL);

    [self.dataOutput setSampleBufferDelegate:self queue:queueBuffer];

    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];

    captureVideoPreviewLayer.frame = self.view.bounds;

    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    [self.cbgView.layer addSublayer:captureVideoPreviewLayer];

    [self.cbgView bringSubviewToFront:self.imageMaskView];

    return YES;
}

- (UIImage *)imageWithFullFileName:(NSString *)strFileName {

    NSString *strFilePath = [NSString pathWithComponents:@[self.strBundlePath, @"images", strFileName ]];
    NSLog(@"strFilePath=%@", strFilePath);
    return [UIImage imageWithContentsOfFile:strFilePath];
}

- (NSString *)audioPathWithFullFileName:(NSString *)strFileName {
    NSString *strFilePath = [NSString pathWithComponents:@[ self.strBundlePath, @"sounds", strFileName ]];
    return strFilePath;
}

- (void)displayViewsIfRunning:(BOOL)bRunning {

    self.imageAnimationView.hidden = NO;
    self.lblPrompt.hidden = NO;

#pragma mark - 用于显示底部的步骤(最初)图示

    self.lblCountDown.hidden = self.bShowCountDownView ? !bRunning : YES;
    self.tickingImageView.hidden = self.bShowCountDownView ? !bRunning : YES;
}

- (void)showPromptWithDetectionType:(LivefaceDetectionType)iType
                     detectionIndex:(int)iIndex {
    //我添加的全局枚举
    self.livefaceDetectionType = &(iType);

    if (self.currentAudioPlayer) {
        [self stopAudioPlayer];
    }

    if ([self.imageAnimationView isAnimating]) {
        [self.imageAnimationView stopAnimating];
    }

    CATransition *transion = [CATransition animation];
    transion.type = @"push";
    transion.subtype = @"fromRight";
    transion.duration = 0.5f;
    transion.removedOnCompletion = YES;

#pragma mark - 在此处将iType类型传出

    switch (iType) {
        case LIVE_YAW: {
            self.lblPrompt.text = @"请摇头";
            self.imageAnimationView.animationDuration = 2.0f;
            self.imageAnimationView.animationImages = self.arrYawImages;
            self.currentAudioPlayer = self.yawAudioPlayer;
            self.livefaceDetectionType = &(iType);

            break;
        }

        case LIVE_BLINK: {
            self.lblPrompt.text = @"请眨眼";
            self.imageAnimationView.animationDuration = 1.0f;
            self.imageAnimationView.animationImages = self.arrBlinkImages;
            self.currentAudioPlayer = self.blinkAudioPlayer;
            self.livefaceDetectionType = &(iType);

            break;
        }

        case LIVE_MOUTH: {
            self.lblPrompt.text = @"请张嘴";
            self.imageAnimationView.animationDuration = 1.0f;
            self.imageAnimationView.animationImages = self.arrMothImages;
            self.currentAudioPlayer = self.mouthAudioPlayer;
            self.livefaceDetectionType = &(iType);


            break;
        }
        case LIVE_NOD: {
            self.lblPrompt.text = @"请上下点头";
            self.imageAnimationView.animationDuration = 2.0f;
            self.imageAnimationView.animationImages = self.arrPitchImages;
            self.currentAudioPlayer = self.nodAudioPlayer;

            self.livefaceDetectionType = &(iType);

            break;
        }
        case LIVE_NONE: {
            break;
        }
    }

    if (![self.imageAnimationView isAnimating]) {
        [self.imageAnimationView startAnimating];
    }

    if (self.currentAudioPlayer) {
        [self stopAudioPlayer];

        // 第一个不播放"很好"语音
        if (iIndex != 0) {
            [self.goodAudioPlayer play];
        }

        [self.currentAudioPlayer play];
    }
}

- (void)stopAudioPlayer {

    if ([self.currentAudioPlayer isPlaying]) {
        [self.currentAudioPlayer stop];
        [self.goodAudioPlayer stop];
    }

    self.currentAudioPlayer.currentTime = 0;

    self.goodAudioPlayer.currentTime = 0;
}

- (void)clearStepViewAndStopSound {

    if (self.currentAudioPlayer) {
        [self stopAudioPlayer];
    }
    [self.goodAudioPlayer play];

}

- (void)setPlayerVolume {

    self.fCurrentPlayerVolume = self.bVoicePrompt ? 0.8 : 0;

    self.blinkAudioPlayer.volume = self.fCurrentPlayerVolume;
    self.mouthAudioPlayer.volume = self.fCurrentPlayerVolume;
    self.nodAudioPlayer.volume = self.fCurrentPlayerVolume;
    self.yawAudioPlayer.volume = self.fCurrentPlayerVolume;
}

- (void)cameraStart {

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice
             requestAccessForMediaType:AVMediaTypeVideo
             completionHandler:^(BOOL granted) {

                 if (granted) {
                     [self.tracker startTracking];
                 } else {
                     if (self.delegate &&
                         [self.delegate
                          respondsToSelector:
                          @selector(livenessDidFailWithErrorType:
                                    detectionType:
                                    detectionIndex:
                                    data:
                                    stImages:)]) {
                              dispatch_async(self->_callBackQueue, ^{

                                  [self.delegate
                                   livenessDidFailWithErrorType:LIVENESS_CAMERA_ERROR
                                   detectionType:LIVE_BLINK
                                   detectionIndex:0
                                   data:nil
                                   stImages:nil];
                              });
                          }
                 }
             }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            [self.tracker startTracking];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: {
            if (self.delegate &&
                [self.delegate
                 respondsToSelector:@selector(livenessDidFailWithErrorType:
                                              detectionType:
                                              detectionIndex:
                                              data:
                                              stImages:)]) {
                     dispatch_async(_callBackQueue, ^{

                         [self.delegate livenessDidFailWithErrorType:LIVENESS_CAMERA_ERROR
                                                       detectionType:LIVE_BLINK
                                                      detectionIndex:0
                                                                data:nil
                                                            stImages:nil];
                     });
                 }
            break;
        }
        default:
            break;
    }
}
#pragma - mark -
#pragma - mark Event Response

- (void)onBtnBack {

    [self cancelDetection];
}

- (void)onBtnStartDetect {

    [self cameraStart];
}

- (void)onBtnSound {

    self.bVoicePrompt = !self.bVoicePrompt;

    [self setPlayerVolume];
}

#pragma - mark -
#pragma - mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    // 录视频
    if (isRecording && self.videoRecorder.status != AVAssetWriterStatusCompleted && self.videoRecorder.status != AVAssetWriterStatusFailed ) {

        [self.videoRecorder recordVideo:sampleBuffer
                          captureOutput:captureOutput
                             dataOutput:connection.output];
    }

    if (self.tracker) {
        [self.tracker trackWithCMSanmpleBuffer:sampleBuffer
                                faceOrientaion:LIVE_FACE_UP];
    }

    if (self.detector) {
        [self.detector trackAndDetectWithCMSampleBuffer:sampleBuffer
                                         faceOrientaion:LIVE_FACE_UP];
    }
}


#pragma - mark -
#pragma - mark STLivenessDetectorDelegate

- (void)livenessFaceRect:(BHRect *)rect {

    if (self.delegate && [self.delegate respondsToSelector:@selector(livenessFaceRect:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate livenessFaceRect:rect];
        });
    }
}

/**
 *  人脸对准的回调
 *  @param status      对准的类型
 */
- (void)livenessTrackerStatus:(LivefaceErrorType)status {

    switch (status) {
        case LIVENESS_FINANCELICENS_FILE_NOT_FOUND:
            NSLog(@"...............1");
            livingResult = checkNO;

        case LIVENESS_FINANCELICENS_CHECK_LICENSE_FAIL:
            NSLog(@"...............2");
            livingResult = checkNO;

        case LIVENESS_MODELSBUNDLE_FILE_NOT_FOUND:
            NSLog(@"...............3");

        case LIVENESS_MODELSBUNDLE_CHECK_MODEL_FAIL:
            NSLog(@"...............4");

        case LIVENESS_INVALID_APPID:
            NSLog(@"...............5");
            livingResult = checkNO;
        case LIVENESS_AUTH_EXPIRE: {
            livingResult = checkNO;
            NSLog(@"...............6");
            if (self.delegate &&
                [self.delegate
                 respondsToSelector:@selector(livenessDidFailWithErrorType:
                                              detectionType:
                                              detectionIndex:
                                              data:
                                              stImages:)]) {
                     dispatch_async(_callBackQueue, ^{
                         [self.delegate livenessDidFailWithErrorType:status
                                                       detectionType:LIVE_BLINK
                                                      detectionIndex:0
                                                                data:nil
                                                            stImages:nil];
                     });
                 }
            break;
        }
        case LIVENESS_NOFACE: {
            NSLog(@"...............7");

            self.imageMaskView.image = [self imageWithFullFileName:@"face-recognition_no-face.png"];

            break;
        }
        case LIVENESS_FACE_TOO_FAR: {
            NSLog(@"...............8");

            break;
        }
        case LIVENESS_FACE_TOO_CLOSE: {
            NSLog(@"...............9");

            break;
        }

        case LIVENESS_DETECTING: {
            NSLog(@"...............10");

            break;
        }
        case LIVENESS_SUCCESS: {
            NSLog(@"...............11");

            self.imageMaskView.image = [self imageWithFullFileName:@"face-recognition_face.png"];

            if (self.recordTime >= 0){
            self.videoRecorder = [[VideoRecorder alloc] init];
            self.videoRecorder.videoTime = self.recordTime;
            [self.videoRecorder setupVideoWriter];
            isRecording = YES;
            }


            [self.tracker stopTracking];

            if (self.session && [self.session isRunning] && self.detector) {
                [self.detector startDetection];
            }
            break;
        }
        case LIVENESS_TIMEOUT: {
            NSLog(@"...............12");
            NSLog(@"超时未起作用");
            break;
        }
            
        case LIVENESS_WILL_RESIGN_ACTIVE: {
            NSLog(@"...............13");


            [self.tracker stopTracking];
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"请保持程序在前台运行, 重试一次"
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  otherButtonTitles:@"确定", nil];
            [alert show];
            break;
        }
        default:
            NSLog(@"...............14");
            break;
    }
}

/**
 *  每个检测模块开始的回调方法
 *
 *  @param iDetectionType  当前开始检测的模块类型
 *  @param iDetectionIndex 当前开始检测的模块在动作序列中的位置, 从0开始.
 */
- (void)livenessDidStartDetectionWithDetectionType:(LivefaceDetectionType)iDetectionType
                                    detectionIndex:(int)iDetectionIndex {


    if (iDetectionType == LIVE_BLINK && iDetectionIndex != 0)
    {
        // 间隙最优照片抓取,设置延时0.3秒
        [NSThread sleepForTimeInterval:0.3];
    }

    [self displayViewsIfRunning:YES];

    [self showPromptWithDetectionType:iDetectionType
                       detectionIndex:iDetectionIndex];

    if (self.delegate &&
        [self.delegate
         respondsToSelector:
         @selector(livenessDidStartDetectionWithDetectionType:
                   detectionIndex:)]) {

             dispatch_async(_callBackQueue, ^{


                 [self.delegate
                  livenessDidStartDetectionWithDetectionType:iDetectionType
                  detectionIndex:iDetectionIndex];
             });
         }



}

/**
 *  每一帧数据回调一次,回调当前模块已用时间及当前模块允许的最大处理时间.
 *
 *  @param dPast             当前模块检测已用时间
 *  @param dDurationPerModel 当前模块检测总时间
 */
- (void)livenessTimeDidPast:(double)dPast durationPerModel:(double)dDurationPerModel {

    if (dDurationPerModel != 0) {
        self.lblCountDown.text = [NSString
                                  stringWithFormat:@"%d", ((int)dDurationPerModel - (int)dPast)];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(livenessTimeDidPast:
                                                        durationPerModel:)]) {
            dispatch_async(_callBackQueue, ^{
                [self.delegate livenessTimeDidPast:dPast
                                  durationPerModel:dDurationPerModel];
            });
        }
    }

}

/**
 *  活体检测成功回调
 *
 *  @param data       回传加密后的二进制数据
 *  @param arrSTImage 根据指定输出方案回传 STImage 数组 , STImage属性见 STImage.h
 */
- (void)livenessDidSuccessfulGetData:(NSData *)data
                            stImages:(NSArray *)arrSTImage {

    [self clearStepViewAndStopSound];
    [self displayViewsIfRunning:NO];

    sleep(1);
    [self.goodAudioPlayer stop];

    if (self.delegate &&
        [self.delegate
         respondsToSelector:@selector(livenessDidSuccessfulGetData:
                                      stImages:)]) {
             dispatch_async(_callBackQueue, ^{
                 [self.delegate livenessDidSuccessfulGetData:data stImages:arrSTImage];
             });
         }

    NSUInteger index = 0;

    // 取眨眼图片 ,注意动作序列必须有眨眼

    if ([_arrDetection containsObject:@"1"]) {

        index = [_arrDetection indexOfObject:@"1"];
    }

    self.faceImage = arrSTImage[index];


    [self secondDectSubbmit];

}

/**
 *  活体检测被取消的回调
 *
 *  @param iDetectionType  检测被取消时的检测模块类型
 *  @param iDetectionIndex 检测被取消时的检测模块在动作序列中的位置, 从0开始
 */
- (void)livenessDidCancelWithDetectionType:(LivefaceDetectionType)iDetectionType
                            detectionIndex:(int)iDetectionIndex {


}

// 检测失败的回调(例如:请眨眼...十秒钟过去仍没检测到眨眼,会关闭)
- (void)livenessDidFailWithErrorType:(LivefaceErrorType)iErrorType
                       detectionType:(LivefaceDetectionType)iDetectionType
                      detectionIndex:(int)iDetectionIndex
                                data:(NSData *)data
                            stImages:(NSArray *)arrSTImage {
    NSLog(@"这是活体检测失败的方法调用");

    if (self.videoRecorder.status != 2) {
        isRecording = NO;
        [self.videoRecorder finishRecorder];
    }

    switch (iErrorType) {
        case LIVENESS_TIMEOUT: // 超时

            [self verifyOutMessage:@"检测超时"];
            break;
        case LIVENESS_NOFACE:

            [self verifyOutMessage:@"人脸信息收集中断"];
            break;
        case LIVENESS_WILL_RESIGN_ACTIVE:

            [self verifyInterrupt:@"验证中断,请保持程序在\n前台运行"];
            break;
        case LIVENESS_FINANCELICENS_CHECK_LICENSE_FAIL:
        case LIVENESS_FINANCELICENS_FILE_NOT_FOUND:
        case LIVENESS_AUTH_EXPIRE:
            [self verifyInterrupt:@"授权文件错误!"];
            break;
        default:
            [self validationFalse];
            
            break;
    }


}



#pragma - mark -
// 超时重新开始
- (void)verifyOutMessage:(NSString *)message {


    isPromptWindow = YES;
    self.alertVC =
    [UIAlertController alertControllerWithTitle:nil
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];

    [self.alertVC addAction:[UIAlertAction
                             actionWithTitle:@"确认"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction *_Nonnull action) {

                                 self->isPromptWindow = NO;

                                 [self back];
                             }]];


    [self presentViewController:self.alertVC animated:YES completion:nil];
}

// 中断退出(后台挂起时)
- (void)verifyInterrupt:(NSString *)message {

    isPromptWindow = YES;
    UIAlertController *alertVC =
    [UIAlertController alertControllerWithTitle:nil
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alertVC addAction:[UIAlertAction
                        actionWithTitle:@"确认"
                        style:UIAlertActionStyleCancel
                        handler:^(UIAlertAction *_Nonnull action) {

                            self->isPromptWindow = NO;
                            [self back];
                        }]];

    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)validationFalse {

    isPromptWindow = YES;
    self.alertBgView = [[UIView alloc] initWithFrame:self.cbgView.bounds];
    self.alertBgView.backgroundColor =
    [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    [self.cbgView addSubview:self.alertBgView];

    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 175)];
    bgView.center = self.alertBgView.center;
    bgView.layer.cornerRadius = 10;
    bgView.layer.masksToBounds = YES;
    [self.alertBgView addSubview:bgView];

    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, bgView.frame.size.width, 50)];
    titleLabel.text = @"验证未通过，再试一次吧";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont systemFontOfSize:20];
    [bgView addSubview:titleLabel];

    NSArray *titleArr = @[ @"光线充足", @"正对手机", @"放慢动作" ];
    for (int i = 0; i < titleArr.count; i++) {
        UIImageView *imageView = [[UIImageView alloc]
                                  initWithFrame:CGRectMake(
                                                           (bgView.bounds.size.width / titleArr.count - 50) / 2 +
                                                           bgView.bounds.size.width / titleArr.count * i,
                                                           50, 50, 50)];
        imageView.image = [self imageWithFullFileName:titleArr[i]];
        [bgView addSubview:imageView];

        UILabel *label = [[UILabel alloc]
                          initWithFrame:CGRectMake(bgView.bounds.size.width / titleArr.count * i,
                                                   CGRectGetMaxY(imageView.frame) + 10,
                                                   bgView.bounds.size.width / titleArr.count,
                                                   15)];
        label.text = titleArr[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor grayColor];
        label.font = [UIFont systemFontOfSize:15];
        [bgView addSubview:label];
    }

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(0, 135, CGRectGetWidth(bgView.frame) / 2, 40);
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton addTarget:self
                     action:@selector(alertCancel)
           forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:cancelButton];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    confirmButton.frame = CGRectMake(CGRectGetMaxX(cancelButton.frame), 135,
                                     CGRectGetWidth(bgView.frame) / 2, 40);
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton addTarget:self
                      action:@selector(alertConfirm)
            forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:confirmButton];
}

- (void)alertCancel {
    isPromptWindow = NO;
    [self.alertBgView removeFromSuperview];
    [self end];
}

- (void)alertConfirm {

    isPromptWindow = NO;
    [self.alertBgView removeFromSuperview];
    [self Restart];
}

#pragma mark - 视频流转为图像

#define clamp(a) (a > 255 ? 255 : (a < 0 ? 0 : a))

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIImage *image = [UIImage imageWithCGImage:quartzImage
                                         scale:1.0f
                                   orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(quartzImage);

    return image;
}

- (void)secondDectSubbmit {


    NSLog(@"正在提交.....");


    NSString *path_sandox = NSHomeDirectory();
    //设置一个图片的存储路径
    NSString *imagePath = [path_sandox stringByAppendingString:@"/Documents/bhFaceImage.png"];
    //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
    [UIImagePNGRepresentation(self.faceImage.image) writeToFile:imagePath atomically:YES];

    self.backData(imagePath, self.faceImage.image,self.videoRecorder.viedoPath, checkYES);

    [self end];


}

- (void)backData:(AliveFace)backData {

    self.backData = backData;
}



#pragma mark ----

- (void)end {

    livingResult = checkCancel;
    if (self.videoRecorder.status != 2) {
        isRecording = NO;
        [self.videoRecorder finishRecorder];
    }

    [self cancelDetection];

    [self.alertBgView removeFromSuperview];

}

//视图已经消失
- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"%s", __FUNCTION__);

    [super viewDidDisappear:animated];

     [self.alertBgView removeFromSuperview];

    if (self.session) {
        [self.session beginConfiguration];
        [self.session removeOutput:self.dataOutput];
        [self.session removeInput:self.deviceInput];
        [self.session commitConfiguration];

        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        self.session = nil;
    }

    if ([self.currentAudioPlayer isPlaying]) {
        [self.currentAudioPlayer stop];
    }

    if ([self.goodAudioPlayer isPlaying]) {
        [self.goodAudioPlayer stop];
    }

    if ([self.imageAnimationView isAnimating]) {
        [self.imageAnimationView stopAnimating];
    }


}

-(void)back{
    isPromptWindow = NO;
    [self end];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.detector && self.session && self.dataOutput &&
        ![self.session isRunning]) {
        [self.session startRunning];
        [self cameraStart];
    }
}

- (void)backStop {

    if (self.session) {
        [self.session beginConfiguration];
        [self.session removeOutput:self.dataOutput];
        [self.session removeInput:self.deviceInput];
        [self.session commitConfiguration];

        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        self.session = nil;
    }

    if ([self.currentAudioPlayer isPlaying]) {
        [self.currentAudioPlayer stop];
    }

    if ([self.goodAudioPlayer isPlaying]) {
        [self.goodAudioPlayer stop];
    }

    if ([self.imageAnimationView isAnimating]) {
        [self.imageAnimationView stopAnimating];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

// 禁止横屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {

    return UIInterfaceOrientationMaskPortrait;
}

#pragma - mark - Private Methods

@end
