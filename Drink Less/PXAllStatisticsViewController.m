//
//  PXAllStatisticsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 06/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAllStatisticsViewController.h"
#import "PXDashboardViewController.h"
#import "PXGoalStatistics.h"
#import "PXBarPlot.h"
#import "PXAllStatistics.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXStatisticsView.h"
#import "PXGroupsManager.h"
#import "PXIntroManager.h"
#import "PXDrinkRecord.h"
#import "PXDrinkRecord+Extras.h"
#import "PXCoreDataManager.h"
#import "PXWeekSummaryViewController.h"

static NSString *const PXDataTypeKey = @"dataType";

@interface PXAllStatisticsViewController () <PXBarPlotDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *hostingView;
@property (weak, nonatomic) IBOutlet PXStatisticsView *statisticsView;
@property (strong, nonatomic) PXBarPlot *barPlot;
@property (strong, nonatomic) NSArray *graphOptions;
@property (strong, nonatomic) PXAllStatistics *allStatistics;
@property (nonatomic, readonly) BOOL isHigh;
@property (nonatomic) NSInteger selectedIndex;

@end

@implementation PXAllStatisticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"All statistics";
    
    self.barPlot = [[PXBarPlot alloc] initWithHostingView:self.hostingView];
    self.barPlot.xAxisDateFormat = @"d MMM";
    self.barPlot.delegate = self;
    
    [self configureSegmentedControl];
    [self.placeholderView setImage:[UIImage imageNamed:@"no_graph"] title:nil subtitle:@"Enter your drinking by tapping the big + button below. We’ll then show you how it changes over time." footer:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _isHigh = [PXGroupsManager sharedManager].highSM.boolValue;
    if (!self.isHigh) {
        NSInteger index = 0;
        self.segmentedControl.selectedSegmentIndex = index;
        self.titleLabel.text = self.graphOptions[index][PXTitleKey];
    }
    self.segmentedControl.hidden = !self.isHigh;
    self.titleLabel.hidden = self.isHigh;
    
    self.allStatistics = [[PXAllStatistics alloc] init];
    self.barPlot.plotData = self.allStatistics.plotData;
    self.statisticsView.allStatistics = self.allStatistics;
    
    BOOL hasData = (self.allStatistics.plotData.count != 0);
    self.contentView.hidden = !hasData;
    self.placeholderView.hidden = hasData;
    
    if (hasData) {
        [self segmentedControlChanged:nil];
    }
};

- (void)configureSegmentedControl {
    self.graphOptions = @[@{PXTitleKey: @"Units",    PXDataTypeKey: @(PXConsumptionTypeUnits)},
                          @{PXTitleKey: @"Alc Free", PXDataTypeKey: @(PXConsumptionTypeAlcoholFreeDays)},
                          @{PXTitleKey: @"Calories", PXDataTypeKey: @(PXConsumptionTypeCalories)},
                          @{PXTitleKey: @"Money",    PXDataTypeKey: @(PXConsumptionTypeSpending)}];
    [self.segmentedControl removeAllSegments];
    
    for (NSDictionary *dictionary in self.graphOptions) {
        NSString *title = dictionary[PXTitleKey];
        [self.segmentedControl insertSegmentWithTitle:title atIndex:self.segmentedControl.numberOfSegments animated:NO];
    }
    self.segmentedControl.selectedSegmentIndex = 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"weekSummary"]) {
        PXWeekSummaryViewController *weekSummaryViewController = segue.destinationViewController;
        weekSummaryViewController.weekSummary = self.allStatistics.weeklySummaries[self.selectedIndex];
    }
}

#pragma mark - Actions

- (IBAction)segmentedControlChanged:(id)sender {
    NSDictionary *dictionary = self.graphOptions[self.segmentedControl.selectedSegmentIndex];
    PXConsumptionType consumptionType = [dictionary[PXDataTypeKey] integerValue];
    BOOL isTypeUnits = YES;//(consumptionType == PXConsumptionTypeUnits || consumptionType == PXConsumptionTypeAlcoholFreeDays);
    
    if (isTypeUnits) {
//        CGFloat markerYValue = 0.0;
//        if (self.isHigh) {
//            BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
//            markerYValue = isFemale ? 14.0 : 14.0;
//        }
        NSNumber *yKey = dictionary[PXDataTypeKey];
        
        NSString *unitsLabel;
        NSInteger goalType;
        self.barPlot.dontUseNoDrinksIcon = YES;
        switch (consumptionType) {
            default:
            case PXConsumptionTypeUnits:
                unitsLabel = @"Units";
                goalType = 0;
                self.barPlot.dontUseNoDrinksIcon = NO;
                break;
            case PXConsumptionTypeSpending:
                unitsLabel = @"Amount Spent";
                goalType = 3;
                break;
            case PXConsumptionTypeCalories:
                unitsLabel = @"Calories Consumed";
                goalType = 2;
                break;
            case PXConsumptionTypeAlcoholFreeDays:
                unitsLabel = @"Alcohol Free Days";
                goalType = 1;
                break;
            
        }
        
        CGFloat goal = [self goalLineFromUserSetGoals:goalType];

        // Make sure max includes goal
        const CGFloat GOAL_PAD = 5;
        CGFloat maxYValue = [self.allStatistics.maxValues[yKey] floatValue];
        
        if (consumptionType == PXConsumptionTypeAlcoholFreeDays) {
            maxYValue = 7;
        } else {
        
            if (maxYValue < (goal + GOAL_PAD)) {
                maxYValue = goal + GOAL_PAD;
            }
            if (maxYValue < 16) {
                maxYValue = 16;
                // has 8 divisions
            } else {
                const int DIVISIONS = 9;
                maxYValue = ceil(maxYValue);
                maxYValue += DIVISIONS - (float)((int)maxYValue % DIVISIONS);
            }
        }
        
        [self.barPlot setXTitle:@"Week ending"
                         yTitle:unitsLabel
                           xKey:nil
                           yKey:yKey
                      minYValue:0.0
                      maxYValue:maxYValue
                      goalValue:goal
                consumptionType:consumptionType
                     showLegend:NO];

        // Reset bar colouring default for new goalValue passed in
        self.barPlot.plots = nil;
        self.barPlot.plotData = self.barPlot.plotData;
        //markerYvalue should be the current goal unit
        
   
    }
    else {
        self.statisticsView.consumptionType = consumptionType;
    }
    self.hostingView.hidden = !isTypeUnits;
    self.statisticsView.hidden = isTypeUnits;
}

// This is a bit of a quick hack hence why I'm wrapping it. It should really be injected by the parent VC
- (CGFloat)goalLineFromUserSetGoals:(NSInteger)goalType {
    
    // Loop throgh goal stats for "unit" type(=0) goals and find the lowest value
    CGFloat goal = FLT_MAX;
    NSArray *goalStats = [(PXDashboardViewController *)self.parentViewController activeGoalsStatistics];
    for (PXGoalStatistics *stat in goalStats) {
        if (stat.goal.goalType.integerValue == goalType) {
            CGFloat value = stat.goal.targetMax.floatValue;
            if (value < goal) goal = value;
        }
    }
    
    // return 0 for none
    return (goal == FLT_MAX) ? 0 : goal;
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
{// is this doing anything?
    CPTColor *areaColor = nil;
    areaColor = [CPTColor redColor];
    CPTFill *barFill = [CPTFill fillWithColor:areaColor];
    
    return barFill;
}

- (IBAction)unwindToStatistics:(UIStoryboardSegue *)segue {
    // User came back to dashboard
}

#pragma mark - PXBarPlotDelegate

- (void)barPlot:(PXBarPlot *)barPlot didSelectItemAtIndex:(NSInteger)index {
    self.selectedIndex = index;
    [self performSegueWithIdentifier:@"weekSummary" sender:nil];
}

@end
