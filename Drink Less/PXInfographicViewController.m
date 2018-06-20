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

@end

@implementation PXInfographicViewController

- (instancetype)initWithType:(PXGraphicType)type {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"infographicVC"];
    if (self) {
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
    
    self.originalTitleBottom = self.titleBottomConstraint.constant;
    
    UIView *subview = self.gaugeView ?: self.peopleView;
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerView addSubview:subview];
    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    [self.headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|" options:0 metrics:nil views:views]];
    [self.headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|" options:0 metrics:nil views:views]];
    
    self.groupSegmentedControl.selectedSegmentIndex = PXGroupTypeEveryone;
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
    PXGroupType groupType = self.groupSegmentedControl.selectedSegmentIndex;
    
    BOOL isDrinkers = groupType == PXGroupTypeDrinkers;
    self.titleLabel.text = isDrinkers ? @"Drinkers includes anyone who has had a drink in the last year, even if that was just one!" : nil;
    self.titleBottomConstraint.constant = isDrinkers ? self.originalTitleBottom : 0.0;
    
    self.feedback = [self.auditCalculator feedbackWithGroupType:groupType populationType:self.populationType graphicType:self.graphicType];
    
    [self setActualAnswersGroupType:groupType populationType:self.populationType graphicType:self.graphicType];
    
    if ([PXIntroManager sharedManager].actualAnswers.allKeys.count == 0) {
        NSLog(@"[PARSE] WARNING, empty actualAnswers");
    }
    
    self.explanationLabel.text = self.feedback.text;
    
    if (self.graphicType == PXGraphicTypePeople) {
        self.peopleView.genderType = (self.populationType == PXPopulationTypeCountry) ? PXGenderTypeNone : self.auditCalculator.genderType;
        self.peopleView.percentileColors = self.auditCalculator.percentileColors;
    } else {
        self.gaugeView.estimate = self.feedback.estimate;
        self.gaugeView.percentileColors = self.auditCalculator.percentileColors;
        self.gaugeView.percentileZones = self.auditCalculator.percentileGaugeZones;
    }
    
    if (sender == self.groupSegmentedControl) {
        if (self.graphicType == PXGraphicTypePeople) {
            self.peopleView.percentile = self.feedback.percentile;
        } else {
            self.gaugeView.percentile = self.feedback.percentile;
        }
    }
}

- (void)setActualAnswersGroupType:(PXGroupType)groupType populationType:(PXPopulationType)populationType graphicType:(PXGraphicType)graphicType {
    
    PXIntroManager *introManager = [PXIntroManager sharedManager];

    double everyOnepercentile = [self.auditCalculator percentileForScore:introManager.auditScore groupType:PXGroupTypeEveryone populationType:populationType cutOffBelowAverage:YES];
    double drinkersPercentile = [self.auditCalculator percentileForScore:introManager.auditScore groupType:PXGroupTypeDrinkers populationType:populationType cutOffBelowAverage:YES];
    
    NSString *everyOneDemographicKey, *drinkersDemographicKey;
    
    if (populationType == PXPopulationTypeAgeGender) {
        everyOneDemographicKey = [NSString stringWithFormat:@"%@:actual", self.auditCalculator.demographicKey];
        drinkersDemographicKey = [NSString stringWithFormat:@"%@:actualDrinkersAnswer", self.auditCalculator.demographicKey];
    } else {
        everyOneDemographicKey = @"all-UK:actual";
        drinkersDemographicKey = @"all-UK:actualDrinkersAnswer";
    }
    
    [introManager.actualAnswers setObject:@(everyOnepercentile) forKey:everyOneDemographicKey];
    [introManager.actualAnswers setObject:@(drinkersPercentile) forKey:drinkersDemographicKey];
}

@end
