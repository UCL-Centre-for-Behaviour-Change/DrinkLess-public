//
//  UIColor+DrinkLess.m
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "UIColor+DrinkLess.h"

@implementation UIColor (DrinkLess)

+ (UIColor *)drinkLessDarkGreyColor {
    return [UIColor colorWithWhite:0.44 alpha:1.0];
}

+ (UIColor *)drinkLessLightGreyColor {
    return [UIColor colorWithWhite:0.84 alpha:1.0];
}

+ (UIColor *)drinkLessGreenColor {
    return [UIColor colorWithRed:98/255.0 green:172/255.0 blue:40/255.0 alpha:1.0];
}

+ (UIColor *)drinkLessLightGreenColor {
    return [UIColor colorWithRed:175/255.0 green:245/255.0 blue:122/255.0 alpha:1.0];
}

+ (UIColor *)drinkLessOrangeColor { //now orange!
    return [UIColor colorWithRed:239/255.0 green:180/255.0 blue:39/255.0 alpha:1.0];
}

+ (UIColor *)drinkLessRedColor {
    return [UIColor colorWithRed:240/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
}

+ (UIColor *)gaugeGreenColor {
    return [UIColor colorWithRed:98/255.0 green:172/255.0 blue:40/255.0 alpha:1.0];
}

+ (UIColor *)gaugeYellowColor {
    return [UIColor colorWithRed:240/255.0 green:240/255.0 blue:0/255.0 alpha:1.0];
}

+ (UIColor *)gaugeDarkYellowColor {
    return [UIColor colorWithRed:200/255.0 green:200/255.0 blue:20/255.0 alpha:1.0];
}

+ (UIColor *)gaugeOrangeColor {
    return [UIColor colorWithRed:240/255.0 green:160/255.0 blue:0/255.0 alpha:1.0];
}

+ (UIColor *)gaugeRedColor {
    return [UIColor colorWithRed:240/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
}

+ (UIColor *)goalRedColor {
    return [UIColor colorWithRed:224/255.0 green:65/255.0 blue:33/255.0 alpha:1.0];
}

+ (UIColor *)goalGrayColor {
    return [UIColor colorWithWhite:0.7 alpha:1.0];
}

+ (UIColor *)overlayGreen {
    return [UIColor colorWithRed:68/255.0 green:144/255.0 blue:8/255.0 alpha:0.35];
}

+ (UIColor *)overlayRed {
    return [UIColor colorWithRed:158/255.0 green:54/255.0 blue:14/255.0 alpha:0.35];
}

+ (UIColor *)calendarHasPlanColor {
    return [UIColor colorWithRed:200/255.0 green:200/255.0 blue:255/255.0 alpha:0.35];
}

+ (UIColor *)barOrange {
    return [UIColor colorWithRed:239/255.0 green:180/255.0 blue:39/255.0 alpha:1.0];
}

+ (UIColor *)barLightGreen {
    return [UIColor colorWithRed:134/255.0 green:214/255.0 blue:72/255.0 alpha:1.0];
}

- (UIColor *)colorWithBrightnessAdjustedBy:(CGFloat)deltaB
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    b += deltaB;
    b = MIN(MAX(b, 0.0), 1.0);
    return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
}

- (UIColor *)colorFadedTowardColor:(UIColor *)fadeColor amount:(CGFloat)amount
{
    CGFloat r1, g1, b1, a1;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    CGFloat r2, g2, b2, a2;
    [fadeColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    CGFloat (^interp)(CGFloat, CGFloat, CGFloat) = ^(CGFloat x1, CGFloat x2, CGFloat a){
        return (x2 - x1) * a + x1;
    };
    CGFloat r3, g3, b3, a3;
    r3 = interp(r1, r2, amount);
    g3 = interp(g1, g2, amount);
    b3 = interp(b1, b2, amount);
    a3 = interp(a1, a2, amount);
    return [UIColor colorWithRed:r3 green:g3 blue:b3 alpha:a3];
}

@end
