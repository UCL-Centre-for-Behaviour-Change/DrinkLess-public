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
#import <Parse/Parse.h>


@implementation UIViewController (PXHelpers)

- (void)checkAndShowTipIfNeeded {
    
//    Special cases:
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

- (void)checkAndShowPrivacyPolicyIfNeedsAcknowledgement {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];    
    if ([defs boolForKey:@"acknowledgedPrivacyPolicy"] != YES) {
        PXWebViewController *vc = [[PXWebViewController alloc] initWithResource:@"privacy-changed"];
        [vc setOpenedOutsideOnboarding:YES];
        [vc.view setBackgroundColor:[UIColor whiteColor]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }
}


@end
