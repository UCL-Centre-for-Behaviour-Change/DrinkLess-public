//
//  PXGoalProgressViewController.m
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalProgressViewController.h"
#import "PXGoal.h"
#import "PXGoalStatistics.h"
#import "PXGoalAnalysisViewController.h"
#import "PXTabView.h"
#import "PXPlaceholderViewRenamed.h"
#import "UIViewController+Swipe.h"
#import "PXTimeCalculator.h"
#import "PXInfoViewController.h"

static NSString *const PXTypeKey = @"type";
static NSString *const PXTitleKey = @"title";

@interface PXGoalProgressViewController ()

@property (strong, nonatomic, readonly) PXGoal *goal;
@property (strong, nonatomic) PXGoalStatistics *goalStatistics;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet PXTabView *tabView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (strong, nonatomic) PXTimeCalculator *timeCalculator;

@end

@implementation PXGoalProgressViewController

- (instancetype)initWithGoal:(PXGoal *)goal {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PXGoalProgress" bundle:nil];
    self = [storyboard instantiateInitialViewController];
    if (self) {
        _goal = goal;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Goal Progress";
    
    self.timeCalculator = [[PXTimeCalculator alloc] initWithMaxComponents:1];
    
    self.items = @[@{PXTypeKey: @(PXAnalysisTypeOverview), PXTitleKey: @"Last Week"},
                   @{PXTypeKey: @(PXAnalysisTypeTime),     PXTitleKey: @"Hit Rate"},
                   @{PXTypeKey: @(PXAnalysisTypeScores),   PXTitleKey: @"Success Rate"}];
    
    __weak typeof(self) weakSelf = self;
    [self addSwipeWithCallback:^(UISwipeGestureRecognizerDirection direction) {
        if (direction == UISwipeGestureRecognizerDirectionLeft) {
            if (weakSelf.tabView.selectedIndex < weakSelf.tabView.titles.count - 1) {
                weakSelf.tabView.selectedIndex++;
            }
            [weakSelf tabValueChanged:weakSelf.tabView];
        } else if (direction == UISwipeGestureRecognizerDirectionRight) {
            if (weakSelf.tabView.selectedIndex > 0) {
                weakSelf.tabView.selectedIndex--;
            }
            [weakSelf tabValueChanged:weakSelf.tabView];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.goalStatistics = [[PXGoalStatistics alloc] initWithGoal:self.goal region:PXStatisticRegionAllCompleted];
    
    BOOL noData = (self.goalStatistics.allData.count == 0);
    self.tabView.hidden = noData;
    self.containerView.hidden = noData;
    self.placeholderView.hidden = !noData;
    if (noData) {
        NSString *subtitle;
        if (self.goal.startDate.timeIntervalSinceNow > 0.0) {
            NSString *time = [self.timeCalculator timeBetweenNowAndDate:self.goal.startDate];
            subtitle = [NSString stringWithFormat:@"We need more data before we can show you these graphs.\n\nPlease keep filling in your drinking calendar for another %@.", time];
        }
        else {
            if (self.goal.endDate && [self.goal.endDate timeIntervalSinceDate:self.goalStatistics.completionDate] < 0) {
                subtitle = @"This goal was ended before enough data could be collected to show you these graphs.";
            } else {
                NSString *time = [self.timeCalculator timeBetweenNowAndDate:self.goalStatistics.completionDate];
                subtitle = [NSString stringWithFormat:@"We need more data before we can show you these graphs.\n\nPlease keep filling in your drinking calendar for another %@.", time];
            }
        }
        [self.placeholderView setImage:[UIImage imageNamed:@"no_graph"]
                                 title:nil
                              subtitle:subtitle
                                footer:nil];
    } else {
        self.tabView.titles = [self.items valueForKey:PXTitleKey];
        for (UIViewController *viewController in self.viewControllers) {
            if ([viewController isKindOfClass:[PXGoalAnalysisViewController class]]) {
                PXGoalAnalysisViewController *goalAnalysisVC = (PXGoalAnalysisViewController *)viewController;
                goalAnalysisVC.goalStatistics = self.goalStatistics;
                [goalAnalysisVC updateFigures];
            }
        }
        [self showViewController:self.viewControllers[self.tabView.selectedIndex]];
    }
}

- (void)showViewController:(UIViewController *)newViewController {
    UIViewController *oldViewController = self.childViewControllers.firstObject;
    if (oldViewController) {
        [oldViewController willMoveToParentViewController:nil];
        [oldViewController.view removeFromSuperview];
        [oldViewController removeFromParentViewController];
    }
    [self addChildViewController:newViewController];
    newViewController.view.frame = self.containerView.bounds;
    [self.containerView addSubview:newViewController.view];
    [newViewController didMoveToParentViewController:self];
}

#pragma mark - Actions

- (IBAction)tabValueChanged:(PXTabView *)tabView {
    [self showViewController:self.viewControllers[tabView.selectedIndex]];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"goal-statistics" fromViewController:self];
}

#pragma mark - Properties

- (NSMutableArray *)viewControllers {
    if (!_viewControllers) {
        _viewControllers = [NSMutableArray arrayWithCapacity:self.items.count];
        for (NSDictionary *dictionary in self.items) {
            PXAnalysisType type = [dictionary[PXTypeKey] integerValue];
            PXGoalAnalysisViewController *goalAnalysisVC = [[PXGoalAnalysisViewController alloc] initWithAnalysisType:type];
            goalAnalysisVC.title = dictionary[PXTitleKey];
            [goalAnalysisVC view]; // Getter to invoke viewDidLoad
            [_viewControllers addObject:goalAnalysisVC];
        }
    }
    return _viewControllers;
}

@end
