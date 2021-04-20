//
//  PXInfographicViewController.m
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXInfographicViewController.h"
#import "PXGaugeView.h"
#import "PXPeopleView.h"
#import "PXAuditFeedback.h"
#import "PXIntroManager.h"
#import "drinkless-Swift.h"

static NSUInteger const PXNumberOfPeople = 20;

@interface PXInfographicViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *groupSegmentedControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic, readonly) PXGaugeView *gaugeView;
@property (strong, nonatomic, readonly) PXPeopleView *peopleView;
@property (strong, nonatomic) PXAuditFeedback *feedback;
@property (nonatomic) CGFloat originalTitleBottom;

@property (nonatomic) BOOL isOnboarding;
@property (nonatomic, strong) AuditData *auditData;
@property (nonatomic, strong) DemographicData *demographicData;

@end

@implementation PXInfographicViewController

- (instancetype)initWithType:(PXGraphicType)type {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"infographicVC"];
    if (self) {
        
        self.isOnboarding = VCInjector.shared.isOnboarding;
        self.auditData = VCInjector.shared.workingAuditData;
        self.demographicData = VCInjector.shared.demographicData;
        
        if (type == PXGraphicTypeGauge) {
            _gaugeView = [[PXGaugeView alloc] init];
        } else if (type == PXGraphicTypePeople) {
            _peopleView = [[PXPeopleView alloc] init];
        }
        _graphicType = type;
    }
    return self;
}

+ (instancetype)infographicWithType:(PXGraphicType)type {
    return [[PXInfographicViewController alloc] initWithType:type];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Infographic";
    self.navigationItem.title = @"How do your compare?";
    
    self.originalTitleBottom = self.titleBottomConstraint.constant;
    
    UIView *subview = self.gaugeView ?: self.peopleView;
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerView addSubview:subview];
    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    [self.headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|" options:0 metrics:nil views:views]];
    [self.headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|" options:0 metrics:nil views:views]];
    
    self.groupSegmentedControl.selectedSegmentIndex = GroupTypeEveryone;
    [self changedGroup:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.graphicType == PXGraphicTypePeople) {
        self.peopleView.percentile = self.feedback.percentile;
    } else {
        self.gaugeView.percentile = self.feedback.percentile;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    
    // Center the scrollView vertically if the content size height has changed
    CGFloat height = self.scrollView.contentSize.height;
    CGFloat verticalSpace = self.scrollView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.scrollView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.scrollEnabled = YES;
    }
}

#pragma mark - Actions

- (IBAction)changedGroup:(id)sender {
    GroupType groupType = self.groupSegmentedControl.selectedSegmentIndex;
    
    BOOL isDrinkers = groupType == GroupTypeDrinkers;
    self.titleLabel.text = isDrinkers ? @"Drinkers includes anyone who has had a drink in the last year, even if that was just one!" : nil;
    self.titleBottomConstraint.constant = isDrinkers ? self.originalTitleBottom : 0.0;
    
    self.feedback = [self.helper feedbackWithAuditData:self.auditData groupType:groupType populationType:self.populationType graphicType:self.graphicType];
    
//    [self setActualAnswersGroupType:groupType populationType:self.populationType graphicType:self.graphicType];
    
    self.explanationLabel.text = self.feedback.text;
    
    if (self.graphicType == PXGraphicTypePeople) {
        self.peopleView.genderType = (self.populationType == PopulationTypeCountry) ? GenderTypeNone : self.demographicData.gender;
        self.peopleView.percentileColors = self.helper.percentileColors;
    } else {
        self.gaugeView.estimate = self.feedback.estimate;
        self.gaugeView.percentileColors = self.helper.percentileColors;
        self.gaugeView.percentileZones = self.helper.percentileGaugeZones;
    }
    
    if (sender == self.groupSegmentedControl) {
        if (self.graphicType == PXGraphicTypePeople) {
            self.peopleView.percentile = self.feedback.percentile;
        } else {
            self.gaugeView.percentile = self.feedback.percentile;
        }
    }
}

//- (void)setActualAnswersGroupType:(GroupType)groupType populationType:(PopulationType)populationType graphicType:(PXGraphicType)graphicType {
//
//    PXIntroManager *introManager = [PXIntroManager sharedManager];
//
//    double everyOnepercentile = [self.helper percentileForScore:introManager.auditScore groupType:PXGroupTypeEveryone populationType:populationType cutOffBelowAverage:YES];
//    double drinkersPercentile = [self.helper percentileForScore:introManager.auditScore groupType:PXGroupTypeDrinkers populationType:populationType cutOffBelowAverage:YES];
//
//    NSString *everyOneDemographicKey, *drinkersDemographicKey;
//
//    if (populationType == PXPopulationTypeAgeGender) {
//        everyOneDemographicKey = [NSString stringWithFormat:@"%@:actual", self.helper.demographicKey];
//        drinkersDemographicKey = [NSString stringWithFormat:@"%@:actualDrinkersAnswer", self.helper.demographicKey];
//    } else {
//        everyOneDemographicKey = @"all-UK:actual";
//        drinkersDemographicKey = @"all-UK:actualDrinkersAnswer";
//    }
//
//    [introManager.actualAnswers setObject:@(everyOnepercentile) forKey:everyOneDemographicKey];
//    [introManager.actualAnswers setObject:@(drinkersPercentile) forKey:drinkersDemographicKey];
//}

@end
