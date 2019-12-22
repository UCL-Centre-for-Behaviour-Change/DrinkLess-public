//
//  PXInfographicView.h
//  drinkless
//
//  Created by Edward Warrender on 25/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

static CGFloat const PXWidth = 320.0;

@interface PXInfographicView : UIView

@property (nonatomic) CGFloat percentile;
@property (strong, nonatomic) NSArray *percentileColors;
@property (nonatomic) CGFloat previousWidth;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UIView *contentView;

- (void)initialConfiguration;
- (void)updateGradient;
- (void)updatedPercentile;

@end
