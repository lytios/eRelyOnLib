//
//  ToolView.m
//  BHNewFaceAlive
//
//  Created by xianbin chen on 15/10/22.
//  Copyright (c) 2017年 BoomHope. All rights reserved.
//

#import "ToolView.h"

#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

@interface ToolView ()

@property (nonatomic, weak) UIImageView* bgView;

@end

@implementation ToolView

- (instancetype)initWithFrame:(CGRect)frame
{

    self = [super initWithFrame:frame];

    if (self) {

        UIImageView* bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"toolViewbg"]];
        bgView.backgroundColor = [UIColor whiteColor];
        self.bgView = bgView;
        [self addSubview:bgView];

        UIImageView* animationView = [[UIImageView alloc] init];
        self.animationView = animationView;
        [self addSubview:animationView];
        
        
        UILabel* tickLabel = [[UILabel alloc] init];
        tickLabel.textAlignment = NSTextAlignmentCenter;
        tickLabel.textColor = [UIColor blackColor];
        tickLabel.font = [UIFont boldSystemFontOfSize:15];
        self.tickLabel = tickLabel;
        [self addSubview:tickLabel];
        
        CGFloat ratio = UIScreen.mainScreen.bounds.size.width / 375.0;
        UILabel* aliveLabel = [[UILabel alloc] init];
        aliveLabel.font = [UIFont boldSystemFontOfSize:19 * ratio];
        aliveLabel.textColor = [UIColor blackColor];
        self.aliveLabel = aliveLabel;
        [self addSubview:aliveLabel];
        UIImage *imageYaw1 = [self imageWithFullFileName:@"ticking1.png"];
        UIImage *imageYaw2 = [self imageWithFullFileName:@"ticking2.png"];
        UIImage *imageYaw3 = [self imageWithFullFileName:@"ticking3.png"];
        UIImage *imageYaw4 = [self imageWithFullFileName:@"ticking4.png"];
        NSArray* imageArr = @[ imageYaw1,imageYaw2,imageYaw3,imageYaw4 ];
        UIImageView* tickingImageView = [[UIImageView alloc] init];
        tickingImageView.animationImages = imageArr;
        tickingImageView.animationDuration = 1;
        tickingImageView.animationRepeatCount = 0;
        self.tickingImageView = tickingImageView;
        [self addSubview:tickingImageView];

        [tickingImageView startAnimating];
    }

    return self;
}

- (UIImage *)imageWithFullFileName:(NSString *)strFileName {
    
    NSString *strResourcesBundlePath = [[NSBundle mainBundle] pathForResource:@"BHFace_Resource" ofType:@"bundle"];
    NSString *strFilePath = [NSString pathWithComponents:@[ strResourcesBundlePath, @"images", strFileName ]];
    
    return [UIImage imageWithContentsOfFile:strFilePath];
}

- (void)layoutSubviews
{

    self.bgView.frame = self.bounds;

    CGFloat margin = 10;

    CGFloat anH = self.bounds.size.height;
    CGFloat anW = anH;

    CGFloat anX = (self.frame.size.width - anW) / 2.0;
    CGFloat anY = 0;

    CGFloat iPhone_margin = 15;
    CGFloat iPhoneX_margin = 6;
    CGFloat marginA = 7;
    if (kDevice_Is_iPhoneX) {
        iPhone_margin = iPhone_margin + 10;
        iPhoneX_margin = iPhoneX_margin + 2;
        marginA = marginA + 5;
    }

    // 人像动画
    self.animationView.frame = CGRectMake(anX + iPhone_margin, anY+iPhone_margin, anW-iPhone_margin*2, anH-iPhone_margin*2);




    CGFloat alH = 47;
    CGFloat alY = (self.frame.size.height - alH) / 2.0;
    CGFloat alW = anX - 2 * margin;
    CGFloat alX = margin ;

    self.aliveLabel.frame = CGRectMake(alX, alY, alW + marginA*2, alH);
    self.aliveLabel.textAlignment = NSTextAlignmentCenter;
    //    self.aliveLabel.text = @"请上下点头";

    CGFloat tvW = alH;
    CGFloat tvH = tvW;

    CGFloat tvX = self.frame.size.width + margin - tvW - (alW / 2);
    CGFloat tvY = alY;

    self.tickingImageView.frame = CGRectMake(tvX - iPhoneX_margin, tvY, tvW, tvH);


    self.tickLabel.frame = self.tickingImageView.frame;
}

@end
