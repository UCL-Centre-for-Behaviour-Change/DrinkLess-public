//
//  PXHomeNavigationController.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXHomeNavigationController.h"
#import "PXStepGuide.h"

@implementation PXHomeNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[PXStepGuide debugReset];
    
    BOOL showStepGuide = ![PXStepGuide hasDone];
    if (showStepGuide) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepGuideDone) name:PXStepGuideDoneNotification object:nil];
    }
    [self showStepGuide:showStepGuide];
}

- (void)stepGuideDone {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PXStepGuideDoneNotification object:nil];
    
    [UIView transitionWithView:self.view duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [UIView performWithoutAnimation:^{
            [self showStepGuide:NO];
        }];
    } completion:nil];
}

- (void)showStepGuide:(BOOL)showStepGuide {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
    NSString *identifier = showStepGuide ? @"stepGuide" : @"dashboard";
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    self.viewControllers = @[viewController];
}

@end
