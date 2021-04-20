//
//  PXIntroHelpfulViewController.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIntroHelpfulViewController.h"
#import "PXIntroManager.h"
#import "PXRateView.h"
#import "drinkless-Swift.h"

@interface PXIntroHelpfulViewController () <PXRateViewDelegate>

@property (weak, nonatomic) IBOutlet PXRateView *yesRateView;
@property (weak, nonatomic) IBOutlet PXRateView *noRateView;
@property (weak, nonatomic) PXRateView *selectedRateView;
@property (strong, nonatomic) PXIntroManager *introManager;

@end

@implementation PXIntroHelpfulViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.yesRateView.helpful = YES;
    self.noRateView.helpful = NO;
    
    self.screenName = @"Was the audit helpful";
    
    self.introManager = [PXIntroManager sharedManager];
    if (self.introManager.wasHelpful) {
        self.selectedRateView = self.introManager.wasHelpful.boolValue ? self.yesRateView : self.noRateView;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // remove children
    [self.navigationController setViewControllers:@[self] animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"helpful"]) {
        //[self pressedContinue:nil];
        [self selectedRateView:self.yesRateView];
        [self pressedFinish:nil];
    }
}

#pragma mark - Actions

- (IBAction)pressedFinish:(id)sender {
    if (!self.introManager.wasHelpful) {
        [[UIAlertController simpleAlertWithTitle:nil msg:@"Please select an answer" buttonTxt:@"Ok"] showIn:self];
        return;
    }
    self.introManager.stage = PXIntroStageCreateGoal;
    [self.introManager save];
    
    // Load the goal setting
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Activities" bundle:nil];
    PXEditGoalViewController *vc = [sb instantiateViewControllerWithIdentifier:@"PXEditGoalVC"];
    vc.isOnboarding = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - PXRateViewDelegate

- (void)selectedRateView:(PXRateView *)rateView {
    self.selectedRateView = rateView;
    self.introManager.wasHelpful = @(rateView.isHelpful);
}

- (void)setSelectedRateView:(PXRateView *)selectedRateView {
    if (_selectedRateView == selectedRateView) return;
    
    _selectedRateView.selected = NO;
    selectedRateView.selected = YES;
    _selectedRateView = selectedRateView;
}

@end
