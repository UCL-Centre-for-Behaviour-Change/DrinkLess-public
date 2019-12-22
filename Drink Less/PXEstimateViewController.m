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
#import "PXAuditFeedbackHelper.h"
#import "PXIntroManager.h"
#import "PXInfoViewController.h"
#import "drinkless-Swift.h"


static CGFloat const PXGaugeMargin = 30.0;

@interface PXEstimateViewController () <PXEstimateCellDelegate>

@property (strong, nonatomic) PXAuditFeedbackHelper *helper;
@property (nonatomic) BOOL isOnboarding;
@property (nonatomic, strong) AuditData *auditData;
@property (nonatomic, strong) DemographicData *demographicData;
@property (weak, nonatomic) IBOutlet PXEstimateCell *countryCell;
@property (weak, nonatomic) IBOutlet PXEstimateCell *ageGenderCell;


@end

@implementation PXEstimateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.auditData = VCInjector.shared.workingAuditData;
    self.demographicData = VCInjector.shared.demographicData;
    self.isOnboarding = VCInjector.shared.isOnboarding;
    self.helper = [[PXAuditFeedbackHelper alloc] initWithDemographicData:self.demographicData];
    
    self.navigationItem.hidesBackButton = YES;
    // Prevent swipe back as well
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.countryCell.gaugeView.estimate = self.auditData.countryEstimate == -1.0 ? 0 : self.auditData.countryEstimate;
    self.countryCell.gaugeView.percentileZones = self.helper.percentileGaugeZones;
    self.countryCell.delegate = self;
    
    self.ageGenderCell.gaugeView.estimate = self.auditData.demographicEstimate == -1.0 ? 0 : self.auditData.demographicEstimate;
    self.ageGenderCell.gaugeView.percentileZones = self.helper.percentileGaugeZones;
    self.ageGenderCell.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.auditData.countryEstimate >= 0) {
        self.countryCell.hintLabel.text = [self.helper countryEstimateZoneForAuditData:self.auditData][PXGaugeTitle];
    } else {
        [self.countryCell startHintAnimation];
    }
    
    if (self.auditData.demographicEstimate >= 0) {
        self.ageGenderCell.hintLabel.text = [self.helper demographicEstimateZoneForAuditData:self.auditData][PXGaugeTitle];
    } else {
        [self.ageGenderCell startHintAnimation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"How do you think you compare dial questions"];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"estimate"]) {
        
        float r1 = arc4random_uniform(90) + 10;
        self.countryCell.gaugeView.estimate = r1;
        [self updatedGaugeForEstimateCell:self.countryCell];
        
        float r2 = arc4random_uniform(90) + 10;
        self.ageGenderCell.gaugeView.estimate = r2;
        [self updatedGaugeForEstimateCell:self.ageGenderCell];
        
        [self performSegueWithIdentifier:@"PXShowSlidersResults" sender:self];
    }
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
        NSString *genderStr = self.demographicData.gender == GenderTypeMale ? @"men" : @"women";
        return [NSString stringWithFormat:@"How do you think your drinking compares with other %@ aged %@?", genderStr, self.demographicData.ageGroup];
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
        self.auditData.countryEstimate = cell.gaugeView.estimate;
        cell.hintLabel.text = [self.helper countryEstimateZoneForAuditData:self.auditData][PXGaugeTitle];
    }
    else if (cell == self.ageGenderCell) {
        self.auditData.demographicEstimate = cell.gaugeView.estimate;
        cell.hintLabel.text = [self.helper demographicEstimateZoneForAuditData:self.auditData][PXGaugeTitle];
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (self.auditData.countryEstimate < 0 ||
        self.auditData.demographicEstimate < 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer all the questions" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PXShowSlidersResults"]) {
        
        self.auditData.demographicKey = self.demographicData.demographicKey;
        
        NSParameterAssert(self.isOnboarding);
        
        // Save the audit stuff now
        // @TODO: DRY this up and get it into some sort of delegate or higher level VC - all this data related stuff actually. It's too important and specific to be buried like this
        self.auditData.demographicKey = self.demographicData.demographicKey;
        [self.auditData calculateActualPercentiles];
        [self.auditData oldSaveToParseUser];
        [self.auditData saveWithLocalOnly:NO];
        
        PXIntroManager *introManager = [PXIntroManager sharedManager];
        introManager.stage = PXIntroStageSliderResults;
        [introManager save];
        
        
        
        
    }
}




@end
