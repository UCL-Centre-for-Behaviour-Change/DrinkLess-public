//
//  PXDashedBackgroundView.h
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXDashedBackgroundView : UIView

@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic, getter = isDashed) BOOL dashed;
@property (nonatomic) CGFloat lineWidth;
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) UIColor *fillColor;

@end
