//
//  UIViewController+PXHelpers.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/14/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "UIViewController+PXHelpers.h"
#import "PXTipView.h"
#import "PXConsentViewController.h"
#import "PXWebViewController.h"
#import "AboutYouTableViewController.h"

@implementation UIViewController (PXHelpers)

- (void)checkAndShowTipIfNeeded {
    
//    espesical case:
//    https://github.com/PortablePixels/DrinkLess/issues/143
    if ([self isKindOfClass:[AboutYouTableViewController class]] ||
        [self isKindOfClass:[PXConsentViewController class]] ||
        ([self isKindOfClass:[PXWebViewController class]] && self.view.tag == 440)) {
        return;
    }
    
    PXTipView *tipView = [[PXTipView alloc] initWithFrame:CGRectMake(0, -43, self.view.frame.size.width, 43)];
    [self.view addSubview:tipView];
    [tipView showTipToConstant:43];
}

@end
