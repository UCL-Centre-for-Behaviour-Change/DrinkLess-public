//
//  UIViewController+Swipe.h
//  drinkless
//
//  Created by Edward Warrender on 29/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

typedef void (^PXBlockCallback)(UISwipeGestureRecognizerDirection direction);

@interface UIViewController (Swipe)

- (void)addSwipeWithCallback:(PXBlockCallback)callback;

@end
