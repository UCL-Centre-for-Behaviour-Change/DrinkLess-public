//
//  PXEstimateViewController.m
//  drinkless
//
//  Created by Edward Warrender on 26/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXEstimateViewController.h"
#import "PXEstimateCell.h"
#import "PXAuditCalculator.h"
#import "PXIntroManager.h"
#import "PXInfoViewController.h"
#import <Google/Analytics.h>

static CGFloat const PXGaugeMargin = 30.0;

@interface PXEstimateViewController () <PXEstimateCellDelegate>

@property (strong, nonatomic) PXAuditCalculator *auditCalculator;
@property (weak, nonatomic) IBOutlet PXEstimateCell *countryCell;
@property (weak, nonatomic) IBOutlet PXEstimateCell *ageGenderCell;

@end

@implementation PXEstimateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    // Prevent swipe back as well
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.auditCalculator = [[PXAuditCalculator alloc] init];
    
    self.countryCell.gaugeView.estimate = self.auditCalculator.countryEstimate.floatValue;
    self.countryCell.gaugeView.percentileZones = self.auditCalculator.percentileGaugeZones;
    self.countryCell.delegate = self;
    
    self.ageGenderCell.gaugeView.estimate = self.auditCalculator.demographicEstimate.floatValue;
    self.ageGenderCell.gaugeView.percentileZones = self.auditCalculator.percentileGaugeZones;
    self.ageGenderCell.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.auditCalculator.countryEstimate) {
        self.countryCell.hintLabel.text = self.auditCalculator.countryEstimateZone[PXGaugeTitle];
    } else {
        [self.countryCell startHintAnimation];
    }
    
    if (self.auditCalculator.demographicEstimate) {
        self.ageGenderCell.hintLabel.text = self.auditCalculator.demographicEstimateZone[PXGaugeTitle];
    } else {
        [self.ageGenderCell startHintAnimation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"How do you think you compare dial questions"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.userInteractionEnabled = NO;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"How do you think your drinking compares with others in the UK?";
    } else {
        return [NSString stringWithFormat:@"How do you think your drinking compares with other %@ aged %@?", self.auditCalculator.gender, self.auditCalculator.ageGroup];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat gaugeWidth = tableView.frame.size.width - (PXGaugeMargin * 2.0);
    CGFloat height = [PXGaugeView heightForWidth:gaugeWidth];
    return height + 54.0;
}

#pragma mark - PXEstimateCellDelegate

- (void)updatedGaugeForEstimateCell:(PXEstimateCell *)cell {
    if (cell == self.countryCell) {
        self.auditCalculator.countryEstimate = @(cell.gaugeView.estimate);
        cell.hintLabel.text = self.auditCalculator.countryEstimateZone[PXGaugeTitle];
    }
    else if (cell == self.ageGenderCell) {
        self.auditCalculator.demographicEstimate = @(cell.gaugeView.estimate);
        cell.hintLabel.text = self.auditCalculator.demographicEstimateZone[PXGaugeTitle];
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (!self.auditCalculator.countryEstimate ||
        !self.auditCalculator.demographicEstimate) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer all the questions" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PXShowSlidersResults"]) {
        PXIntroManager *introManager = [PXIntroManager sharedManager];
        introManager.stage = PXIntroStageSliderResults;
        introManager.estimateAnswers = self.auditCalculator.estimateAnswers;
        
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                              action:@"continue_from_compare_dials_questions"  // Event action (required)
                                                               label:@"continue"          // Event label
                                                               value:nil] build]];    // Event value
        
        [introManager save];
    }
}




@end
