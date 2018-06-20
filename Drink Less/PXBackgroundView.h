//
//  PXBackgroundView.h
//  drinkless
//
//  Created by Edward Warrender on 13/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PXBackgroundViewPosition) {
    PXBackgroundViewPositionNone,
    PXBackgroundViewPositionTop,
    PXBackgroundViewPositionMiddle,
    PXBackgroundViewPositionBottom,
    PXBackgroundViewPositionSingle
};

@interface PXBackgroundView : UIView

- (instancetype)initWithPosition:(PXBackgroundViewPosition)position;

@property (nonatomic, readonly) PXBackgroundViewPosition position;
@property (nonatomic) UIEdgeInsets separatorInset;
@property (strong, nonatomic) UIColor *separatorColor;

@end
