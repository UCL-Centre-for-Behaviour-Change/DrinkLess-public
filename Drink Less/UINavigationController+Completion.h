//
//  UINavigationController+Completion.h
//  drinkless
//
//  Created by Edward Warrender on 07/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Completion)

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end
