//
//  PXTabBarController.m
//  Drink Less
//
//  Created by Chris on 08/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTabBarController.h"
#import "PXTrackerPanelViewController.h"
#import "PXDrinkRecordListVC.h"
#import "PXDailyTaskManager.h"
#import "PXDashboardViewController.h"
#import "drinkless-Swift.h"

NSString *const PXShowDrinksPanelNotification = @"showDrinksPanelNotification";

@interface PXTabBarController () <UITabBarControllerDelegate, PXTrackerPanelViewControllerDelegate>

@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) PXTrackerPanelViewController *trackerPanelVC;
@property (strong, nonatomic) id showDrinksPanelObserver;
@property (strong, nonatomic) NSDate *panelDate;

@end

@implementation PXTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button addTarget:self action:@selector(toggleTrackerPanel) forControlEvents:UIControlEventTouchDown];
    self.button.adjustsImageWhenHighlighted = NO;
    self.button.adjustsImageWhenDisabled = NO;
    [self.button setBackgroundImage:[UIImage imageNamed:@"Add"] forState:UIControlStateNormal];
    [self.tabBar addSubview:self.button];
    [self.button sizeToFit];
    
    // Needed for later...
    DashboardExplainer.shared.addDrinkBtn = self.button;
    DashboardExplainer.shared.calendarBtn = self.tabBar;
    
    // This will just be on Activities now
//    for (UINavigationController *navigationController in self.viewControllers) {
//        UIViewController *viewController = navigationController.topViewController;
//        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(pressedHelp:)];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.trackerPanelVC) {
        [self.trackerPanelVC viewWillAppear:animated];
    }
    
    __weak typeof(self) weakSelf = self;
    self.showDrinksPanelObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PXShowDrinksPanelNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        weakSelf.panelDate = [note.object isKindOfClass:[NSDate class]] ? note.object : nil;
        if (!weakSelf.trackerPanelVC) {
            [weakSelf toggleTrackerPanel];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.showDrinksPanelObserver];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.button.center = CGPointMake(self.tabBar.bounds.size.width * 0.5,
                                     25);//self.tabBar.bounds.size.height * 0.5);
    [self.tabBar bringSubviewToFront:self.button];
}

//////////////////////////////////////////////////////////
// MARK: - Convenience
//////////////////////////////////////////////////////////

- (void)showCalendarTab {
    self.selectedIndex = 4;
}

//---------------------------------------------------------------------

- (void)selectTabAtIndex:(NSInteger)tabIndex storyboardName:(NSString *)storyboardName pushViewControllersWithIdentifiers:(NSArray *)identifiers {
    self.selectedIndex = tabIndex;
    UINavigationController *navigationController = (UINavigationController *)self.selectedViewController;
    [navigationController popToRootViewControllerAnimated:NO];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    for (NSString *identifier in identifiers) {
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
        [navigationController pushViewController:viewController animated:NO];
    }
}

- (id)topViewController {
    UINavigationController *navigationController = self.selectedViewController;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        return navigationController.topViewController;
    }
    return nil;
}

- (id)topViewControllerOfClass:(Class)class {
    id topViewController = [self topViewController];
    if ([topViewController isKindOfClass:class]) {
        return topViewController;
    }
    return nil;
}

- (NSDate *)viewingDiaryDate {
    PXDrinkRecordListVC *drinkRecordListVC = [self topViewControllerOfClass:[PXDrinkRecordListVC class]];
    return drinkRecordListVC.date;
}

- (void)toggleTrackerPanel {
    [self toggleTrackerPanelWithCompletion:nil];
}

- (void)toggleTrackerPanelWithCompletion:(void (^)(void))completion {
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    
    __weak typeof(self) weakSelf = self;
    BOOL wasOpen = (self.trackerPanelVC != nil);
    if (wasOpen) {
        self.panelDate = nil;
        
        [sharedApplication beginIgnoringInteractionEvents];
        [self.trackerPanelVC setOpen:NO animated:YES completion:^{
            [weakSelf cleanupAfterTrackerPanelClose];
            if (completion) completion();
        }];
    }
    else {
        self.trackerPanelVC = [PXTrackerPanelViewController viewController];
        self.trackerPanelVC.delegate = self;
        self.trackerPanelVC.referenceDate = self.panelDate ?: [self viewingDiaryDate];
        
        UIViewController *viewController = self.selectedViewController;
        UIView *embedView = self.trackerPanelVC.view;
        [viewController addChildViewController:self.trackerPanelVC];
        [self.trackerPanelVC willMoveToParentViewController:viewController];
        [viewController.view addSubview:embedView];
        
        CGRect tabBarRect = [viewController.view convertRect:self.tabBar.frame fromView:self.tabBar.superview];
        CGRect embedRect = viewController.view.bounds;
        embedRect.size.height = CGRectGetMinY(tabBarRect);
        embedView.frame = embedRect;
        [self.trackerPanelVC didMoveToParentViewController:self];
        
        [sharedApplication beginIgnoringInteractionEvents];
        [self.trackerPanelVC setOpen:YES animated:YES completion:^{
            [sharedApplication endIgnoringInteractionEvents];
            
            if (completion) completion();
        }];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (wasOpen) {
            self.button.transform = CGAffineTransformIdentity;
        } else {
            self.button.transform = CGAffineTransformMakeRotation(0.25 * M_PI);
        }
    }];
}

- (void)cleanupAfterTrackerPanelClose
{
    UIApplication *sharedApplication = [UIApplication sharedApplication];

    [self.trackerPanelVC willMoveToParentViewController:nil];
    [self.trackerPanelVC.view removeFromSuperview];
    [self.trackerPanelVC removeFromParentViewController];
    self.trackerPanelVC = nil;
    [sharedApplication endIgnoringInteractionEvents];
    
    // Required to refresh data displayed e.g. dashboard and step guide
    // Refactor this in the future to use modal view controller with fake tabbar
    UIViewController *topViewController = [self topViewController];
    [topViewController viewWillAppear:YES];
    [topViewController viewDidAppear:YES];
    for (UIViewController *viewController in topViewController.childViewControllers) {
        [viewController viewWillAppear:YES];
        [viewController viewDidAppear:YES];
    }
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.trackerPanelVC) {
        [self toggleTrackerPanelWithCompletion:^{
            tabBarController.selectedViewController = viewController;
        }];
        return NO;
    }
    if ([viewController isKindOfClass:UINavigationController.class]) {
        [((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
    }
    return YES;
}

#pragma mark PXTrackerPanelViewControllerDelegate

- (void)shouldClosePanel {
    [self toggleTrackerPanel];
}

- (void)didCompleteCloseAfterDrag
{
    [self cleanupAfterTrackerPanelClose];
}

@end
