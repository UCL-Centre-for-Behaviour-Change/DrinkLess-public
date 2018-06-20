//
//  PXCardView.h
//  drinkless
//
//  Created by Edward Warrender on 16/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXCardView : UIView

@property (strong, nonatomic) UIDynamicItemBehavior *flingBehavior;
@property (nonatomic, getter = isPositive) BOOL positive;

- (instancetype)initWithImage:(UIImage *)image landscape:(BOOL)isLandscape;

@end
