//
//  UIColor+DrinkLess.h
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface UIColor (DrinkLess)

+ (UIColor *)drinkLessDarkGreyColor;
+ (UIColor *)drinkLessLightGreyColor;
+ (UIColor *)drinkLessGreenColor;
+ (UIColor *)drinkLessLightGreenColor;
+ (UIColor *)drinkLessOrangeColor;
+ (UIColor *)drinkLessRedColor;

+ (UIColor *)gaugeGreenColor;
+ (UIColor *)gaugeYellowColor;
+ (UIColor *)gaugeDarkYellowColor;
+ (UIColor *)gaugeOrangeColor;
+ (UIColor *)gaugeRedColor;

+ (UIColor *)goalRedColor;
+ (UIColor *)goalGrayColor;

+ (UIColor *)overlayGreen;
+ (UIColor *)overlayRed;

+ (UIColor *)calendarHasPlanColor;

+ (UIColor *)barOrange;
+ (UIColor *)barLightGreen;

- (UIColor *)colorWithBrightnessAdjustedBy:(CGFloat)deltaB;
- (UIColor *)colorFadedTowardColor:(UIColor *)fadeColor amount:(CGFloat)amount;


@end
