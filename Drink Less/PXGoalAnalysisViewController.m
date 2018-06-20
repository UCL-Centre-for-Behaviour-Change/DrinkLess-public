//
//  PXGoalAnalysisViewController.m
//  drinkless
//
//  Created by Edward Warrender on 24/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalAnalysisViewController.h"
#import "PXGoalStatistics.h"
#import "PXGoal+Extras.h"
#import "CPTGraphHostingView.h"
#import "PXBarPlot.h"
#import "PXPiePlot.h"
#import "PXFormatter.h"
#import <CorePlot-CocoaTouch.h>
#import "UITextView+HTML.h"
#import "PXDashboardViewController.h"
#import "PXYourGoalsViewController.h"
#import "PXListView.h"
#import "PXTabBarController.h"

@interface PXGoalAnalysisViewController () <UITextViewDelegate>

@property (nonatomic, readonly) PXAnalysisType analysisType;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITextView *explanationTextView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) PXBarPlot *barPlot;
@property (strong, nonatomic) PXPiePlot *piePlot;
@property (strong, nonatomic) PXListView *listView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation PXGoalAnalysisViewController

- (instancetype)initWithAnalysisType:(PXAnalysisType)analysisType {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PXGoalProgress" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"PXGoalAnalysisVC"];
    if (self) {
        _analysisType = analysisType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Goal analysis";
    
    self.explanationTextView.textContainer.lineFragmentPadding = 0.0;
    self.explanationTextView.textContainerInset = UIEdgeInsetsMake(1.0, 0.0, 1.0, 0.0);
    
    if (self.analysisType == PXAnalysisTypeOverview) {
        self.listView = [PXListView listView];
        
        self.listView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:self.listView];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_listView, _imageView);
        NSDictionary *metrics = @{@"margin": @15.0};
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[_listView]-margin-|" options:0 metrics:metrics views:views]];
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[_imageView]-100-|" options:0 metrics:metrics views:views]];
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[_listView]-margin-[_imageView]-margin-|" options:0 metrics:metrics views:views]];
    }
    else {
        CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] init];
        hostingView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:hostingView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(hostingView);
        NSDictionary *metrics = @{@"margin": @5.0};
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[hostingView]|" options:0 metrics:nil views:views]];
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[hostingView]-margin-|" options:0 metrics:metrics views:views]];
        
        if (self.analysisType == PXAnalysisTypeTime) {
            self.barPlot = [[PXBarPlot alloc] initWithHostingView:hostingView];
        }
        else if (self.analysisType == PXAnalysisTypeScores) {
            self.piePlot = [[PXPiePlot alloc] initWithHostingView:hostingView];
        }
    }
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.analysisType == PXAnalysisTypeScores) {
        [self.containerView layoutIfNeeded];
        [self.piePlot updateLayout];
    }
}

- (void)updateFigures {
    PXGoal *goal = self.goalStatistics.goal;
    self.headerLabel.text = [NSString stringWithFormat:@"Goal: %@", goal.title];
    
    NSDictionary *data = self.goalStatistics.data;
    PXGoalStatus lastStatus = [data[PXStatusKey] integerValue];
    BOOL didHit = (lastStatus == PXGoalStatusHit || lastStatus == PXGoalStatusExceeded);
    self.explanationTextView.textColor = didHit ? [UIColor drinkLessGreenColor] : [UIColor colorWithWhite:0.33 alpha:1.0];
    
    if (self.analysisType == PXAnalysisTypeOverview) {
        PXGoalType goalType = goal.goalType.integerValue;
        NSNumber *quantity = data[PXQuantityKey];
        NSString *consumption;
        if (goalType == PXGoalTypeSpending) {
            consumption = [PXFormatter currencyFromNumber:quantity];
        } else {
            NSString *format = (goalType == PXGoalTypeUnits) ? @"%.1f" : @"%.f";
            consumption = [NSString stringWithFormat:format, quantity.floatValue];
        }
        NSDate *toDate = data[PXToDateKey];
        // go back one day as we want the top bounds to be inclusive
        toDate = [toDate dateByAddingTimeInterval:-24*3600];
        NSString *dateString = [self.dateFormatter stringFromDate:toDate];
        self.listView.titleLabel.text = [NSString stringWithFormat:@"Last ended:\n%@:", goal.goalTypeTitle];
        self.listView.textLabel.text = [NSString stringWithFormat:@"%@\n%@", dateString, consumption];
        
        [self.explanationTextView loadHTMLString:[self calculateMessage]];
        self.imageView.image = [PXGoalCalculator imageForGoalStatus:lastStatus];
    }
    else if (self.analysisType == PXAnalysisTypeTime) {
        NSDictionary *plotIdentifiers = @{@(PXGoalStatusExceeded): @"Exceeded the goal",
                                          @(PXGoalStatusHit): @"Hit the goal",
                                          @(PXGoalStatusNear): @"Nearly hit the goal",
                                          @(PXGoalStatusMissed): @"Missed the goal"};
        
        NSMutableArray *plots = [NSMutableArray arrayWithCapacity:plotIdentifiers.count];
        for (NSNumber *key in [plotIdentifiers.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
            PXGoalStatus status = key.integerValue;
            NSString *plotIdentifier = plotIdentifiers[key];
            [plots addObject:@{PXPlotIdentifier: plotIdentifier,
                               PXColorKey: [PXGoalCalculator colorForGoalStatus:status]}];
        }
        self.barPlot.plots = plots;
        
        NSString *yKey = PXQuantityKey;
        NSMutableArray *plotData = [NSMutableArray array];
        for (NSInteger i = 0; i < self.goalStatistics.allData.count; i++) {
            NSDictionary *dictionary = self.goalStatistics.allData[i];
            PXGoalStatus status = [dictionary[PXStatusKey] integerValue];
            NSString *plotIdentifier = plotIdentifiers[@(status)];
            [plotData addObject:@{PXPlotIdentifier: plotIdentifier,
                                  @"x": @(i + 1),
                                  yKey: dictionary[yKey],
                                  PXColorKey: [PXGoalCalculator colorForGoalStatus:status]}];
        }
        self.barPlot.plotData = plotData;
        
        CGFloat targetMax = goal.targetMax.floatValue;
        NSNumber *maxQuantity = [self.goalStatistics.allData valueForKeyPath:[NSString stringWithFormat:@"@max.%@", yKey]];
        CGFloat maxYValue = MAX(maxQuantity.floatValue, targetMax);
        [self.barPlot setXTitle:@"Week" yTitle:goal.goalTypeTitle xKey:@"x" yKey:yKey minYValue:0.0 maxYValue:maxYValue goalValue:targetMax displayAsPercentage:NO axisTypeX:PXAxisTypeNumber showLegend:YES];
        
        BOOL isPlural = self.goalStatistics.allData.count != 1;
        self.explanationTextView.text = [NSString stringWithFormat:@"You’ve hit %.f%% of your goal%@ to %@.", self.goalStatistics.successPercentage, isPlural ? @"s" : @"", self.goalStatistics.goal.title.lowercaseString];
    }
    else if (self.analysisType == PXAnalysisTypeScores) {
        self.piePlot.plotData = @[@{PXTitleKey: @"Exceeded the goal",
                                    PXValueKey: @(self.goalStatistics.exceedCount),
                                    PXColorKey: [PXGoalCalculator colorForGoalStatus:PXGoalStatusExceeded]},
                                  @{PXTitleKey: @"Hit the goal",
                                    PXValueKey: @(self.goalStatistics.hitCount),
                                    PXColorKey: [PXGoalCalculator colorForGoalStatus:PXGoalStatusHit]},
                                  @{PXTitleKey: @"Nearly hit the goal",
                                    PXValueKey: @(self.goalStatistics.nearCount),
                                    PXColorKey: [PXGoalCalculator colorForGoalStatus:PXGoalStatusNear]},
                                  @{PXTitleKey: @"Missed the goal",
                                    PXValueKey: @(self.goalStatistics.missCount),
                                    PXColorKey: [PXGoalCalculator colorForGoalStatus:PXGoalStatusMissed]}];
        
        NSInteger successStreak = self.goalStatistics.successStreak;
        if (successStreak > 0) {
            NSString *weeks = self.goalStatistics.successStreak == 1 ? @"week" : @"weeks";
            self.explanationTextView.text = [NSString stringWithFormat:@"Your longest streak for hitting this goal lasted %li %@.", (long)self.goalStatistics.successStreak, weeks];
        } else {
            self.explanationTextView.text = nil;
        }
    }
}

- (PXGoalStatus)statusOfPastRecursion:(NSInteger)recursion {
    NSUInteger count = self.goalStatistics.allData.count;
    NSInteger index = count - 1 - recursion;
    if (index < count) {
        NSDictionary *dictionary = self.goalStatistics.allData[index];
        return [dictionary[PXStatusKey] integerValue];
    }
    return NSNotFound;
}

- (NSString *)calculateMessage {
    PXGoalStatus lastStatus = [self statusOfPastRecursion:0];
    PXGoalStatus secondLastStatus = [self statusOfPastRecursion:1];
    
    if (lastStatus == PXGoalStatusExceeded) {
        // Exceeded goal first time
        if (secondLastStatus != PXGoalStatusExceeded) {
            return @"Overachiever! Goal smashed. Well done.";
        }
        // Exceeded twice or more in a row
        return @"Whoa, there goes that goal again. Twice in a row too. Is this an unusual period or do you think the goal is a bit easy? <a href='app://your-goals'/>You can make it harder if you like</a>.";
    }
    if (lastStatus == PXGoalStatusMissed) {
        // Missed goal first time
        if (secondLastStatus != PXGoalStatusMissed) {
            return @"You didn’t hit your goal this week. No problem, keep going.";
        }
        // Missed twice or more in a row
        return @"Looks like you’re having a bit of difficulty with this one. Is it an unusual period, or do you think the goal is a bit much of a stretch? <a href='app://your-goals'>You can make it slightly easier if you like.</a>";
    }
    
    // Each key is an identifier which must be the same between app versions so the user's message is consistent
    NSDictionary *randomMessages;
    if (lastStatus == PXGoalStatusHit) {
        randomMessages = @{@"hit1": @"Get you! Good work on hitting your goal.",
                           @"hit2": @"Congratulations on a great week of achievement. Feel proud? You should.",
                           @"hit3": @"Goal hit. Good work. You’re great.",
                           @"hit4": @"That’s your goal got! I’d pat you on the back if I had arms.",
                           @"hit5": @"Well done, you hit your goal. Keep going."};
    }
    else if (lastStatus == PXGoalStatusNear) {
        randomMessages = @{@"near1": @"Didn’t quite make this one. Close though. You can do this.",
                           @"near2": @"Just missed this goal. It’s definitely within reach though.",
                           @"near3": @"Nearly made it. Just need to do a bit more and you’ll make it next time.",
                           @"near4": @"That was close! Won’t take much more to get that glorious green tick.",
                           @"near5": @"Almost! Bit more of a push and you’ll get this goal."};
    }
    if (randomMessages) {
        PXGoal *goal = self.goalStatistics.goal;
        NSNumber *recursion = @(self.goalStatistics.allData.count - 1);
        
        BOOL needsUpdate = NO;
        if (![goal.feedbackRecursion isEqualToNumber:recursion]) {
            needsUpdate = YES;
        } else if (!randomMessages[goal.feedbackMessageID]) {
            needsUpdate = YES;
        }
        
        if (needsUpdate) {
            goal.feedbackRecursion = recursion;
            NSInteger index = arc4random_uniform((u_int32_t)randomMessages.count);
            goal.feedbackMessageID = randomMessages.allKeys[index];
            [goal.managedObjectContext save:nil];
        }
        return randomMessages[goal.feedbackMessageID];
    }
    return nil;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([URL.scheme isEqualToString:@"app"]) {
        if ([URL.host isEqualToString:@"your-goals"]) {
            NSInteger previousIndex = self.navigationController.viewControllers.count - 2;
            UIViewController *previousViewController = self.navigationController.viewControllers[previousIndex];
            
            if ([previousViewController isKindOfClass:[PXDashboardViewController class]]) {
                [self.navigationController popViewControllerAnimated:NO];
                
                PXTabBarController *tabBarController = (PXTabBarController *)previousViewController.tabBarController;
                [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXGoalsNavTVC", @"PXYourGoalsVC"]];
            }
            else if ([previousViewController isKindOfClass:[PXYourGoalsViewController class]]) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        return NO;
    }
    return YES;
}

@end
