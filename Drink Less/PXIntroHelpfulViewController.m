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
#import <Google/Analytics.h>

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

#pragma mark - Actions

- (IBAction)pressedFinish:(id)sender {
    if (!self.introManager.wasHelpful) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select an answer" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    self.introManager.stage = PXIntroStageFinished;
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                          action:@"tapped_finish_at_end_of_audit"  // Event action (required)
                                                           label:@"Finish"          // Event label
                                                           value:nil] build]];    // Event value
    
    [self.introManager save];
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
