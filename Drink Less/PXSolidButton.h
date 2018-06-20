//
//  PXSolidButton.h
//  SmokingDiary
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXSolidButton : UIButton

@property (nonatomic, getter = isCircular) BOOL circular;
@property (nonatomic, getter = shouldKeepLabelConfig) BOOL keepLabelConfig;
@property (nonatomic) CGFloat borderWidth;
@property (strong, nonatomic) UIColor *borderColor;
@property (strong, nonatomic) UIColor *selectedColor;
@property (strong, nonatomic) UIColor *normalColor;

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated;

@end
