//
//  AppDelegate.h
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (UIViewController *)topMostViewController;

@end

