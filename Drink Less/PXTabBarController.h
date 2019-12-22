//
//  PXTabBarController.h
//  Drink Less
//
//  Created by Chris on 08/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

extern NSString *const PXShowDrinksPanelNotification;

@interface PXTabBarController : UITabBarController

- (void)showCalendarTab;

- (void)selectTabAtIndex:(NSInteger)tabIndex storyboardName:(NSString *)storyboardName pushViewControllersWithIdentifiers:(NSArray *)identifiers;

@end
