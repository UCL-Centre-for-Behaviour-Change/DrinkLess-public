//
//  PXTrackedViewController.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackedViewController.h"
#import "drinkless-Swift.h"
#import "UIViewController+PXHelpers.h"

@interface PXTrackedViewController()


@end

@implementation PXTrackedViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.screenName) {
        [DataServer.shared trackScreenView:self.screenName];
    }
    [self checkAndShowTipIfNeeded];
}

@end
