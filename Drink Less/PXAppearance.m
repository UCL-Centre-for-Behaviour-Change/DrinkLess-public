//
//  PXAppearance.m
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAppearance.h"

@implementation PXAppearance

+ (void)configureAppearance {
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    navigationBar.barTintColor = [UIColor drinkLessGreenColor];
    navigationBar.tintColor = [UIColor drinkLessLightGreenColor];
    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.currentPageIndicatorTintColor = [UIColor drinkLessGreenColor];
    pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:0.0 alpha:0.1];
    
    UITabBarItem *tabBarItem = [UITabBarItem appearance];
    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor drinkLessDarkGreyColor], NSFontAttributeName: [UIFont systemFontOfSize:10.5]} forState:UIControlStateNormal];
    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor]} forState:UIControlStateSelected];
    
    [[UISwitch appearance] setOnTintColor:[UIColor drinkLessGreenColor]];
}

@end
