//
//  PXReviewAuditViewController.m
//  drinkless
//
//  Created by Edward Warrender on 02/03/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAuditHistoryViewAuditVC.h"
#import "PXTabView.h"
#import "PXGroupsManager.h"
#import "AuditResultsViewController.h"
#import "PXAuditFeedbackViewController.h"
#import "PXHighGroupAuditViewController.h"
#import "UIViewController+Swipe.h"
#import "PXDailyTaskManager.h"
#import "drinkless-Swift.h"

typedef NS_ENUM(NSInteger, PXTab) {
    PXTabFeedback,
    PXTabScore,
    PXTabAnswers
};

static NSString *const PXTabKey = @"tab";
static NSString *const PXTitleKey = @"title";

@interface PXAuditHistoryViewAuditVC ()

@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet PXTabView *tabView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation PXAuditHistoryViewAuditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Audit History View Audit";
    
    self.tabView.titles = [self.items valueForKey:PXTitleKey];
    [self showViewController:self.viewControllers[self.tabView.selectedIndex]];
    
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
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"normative-misperceptions"];
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

#pragma mark - Properties

- (NSMutableArray *)items {
    if (!_items) {
        BOOL isHigh = [PXGroupsManager sharedManager].highNM.boolValue;
        _items = @[@{PXTabKey: @(PXTabFeedback), PXTitleKey: isHigh ? @"Comparison" : @"Alcohol Advice"},
//                   @{PXTabKey: @(PXTabScore), PXTitleKey: @"Your Drinking"},
                   @{PXTabKey: @(PXTabAnswers), PXTitleKey: @"Answers"}].mutableCopy;
    }
    return _items;
}

- (NSMutableArray *)viewControllers {
    if (!_viewControllers) {
        _viewControllers = [NSMutableArray arrayWithCapacity:self.items.count];
        for (NSDictionary *dictionary in self.items) {
            PXTab tab = [dictionary[PXTabKey] integerValue];
            UIViewController *viewController = [self instantiateViewControllerForTab:tab];
            [_viewControllers addObject:viewController];
        }
    }
    return _viewControllers;
}

- (UIViewController *)instantiateViewControllerForTab:(PXTab)tab {
    UIViewController *viewController = nil;
    if (tab == PXTabAnswers) {
        viewController = [AuditHistoryViewAuditAnswersVC instantiateFromStoryboard];
    }
    else if (tab == PXTabScore) {
        viewController = [AuditResultsViewController auditResultsViewController];
        ((AuditResultsViewController *)viewController).buttonContainerHidden = YES;
    }
    else if (tab == PXTabFeedback) {
        viewController = [PXAuditFeedbackViewController auditFeedbackViewController];
        ((PXAuditFeedbackViewController *)viewController).buttonContainerHidden = YES;
    }
    return viewController;
}

@end
