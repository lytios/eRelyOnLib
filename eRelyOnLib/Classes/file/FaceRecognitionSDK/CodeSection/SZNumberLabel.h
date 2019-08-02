//
//  SZNumberLabel.h
//  BHFaceController
//
//  Created by bh on 16/3/3.
//  Copyright © 2016年 BoomHope. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SZNumberLabel : UILabel

@property (nonatomic , assign) BOOL bHighlight;

- (instancetype)initWithFrame:(CGRect)frame number:(int)iNumber;


@end
