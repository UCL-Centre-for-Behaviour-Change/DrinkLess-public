//
//  PXIdentityNavViewController.m
//  drinkless
//
//  Created by Edward Warrender on 04/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityNavViewController.h"
#import "PXUserIdentity.h"
#import "PXUserFlipsides.h"
#import "PXGroupsManager.h"
#import "PXDailyTaskManager.h"
#import "PXStepGuide.h"
#import "PXInfoViewController.h"
#import "PXTipView.h"

@interface PXIdentityNavViewController ()

@property (strong, nonatomic) NSString *originalHeader;
@property (strong, nonatomic) IBOutlet UILabel *headerTextLabel;
@property (weak, nonatomic) IBOutlet PXTipView *tipView;
@property (nonatomic, readonly) BOOL isHigh;

@end

@implementation PXIdentityNavViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isHigh = [PXGroupsManager sharedManager].highID.boolValue;

    self.originalHeader = self.headerTextLabel.text;

    // Add the info only for high level peopl
    if (self.isHigh) {
        UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
        // Make the info button to the right of help. Also safeguard against nil
        NSArray *barButtonItems = [@[barItem] arrayByAddingObjectsFromArray:(self.navigationItem.rightBarButtonItems?:@[])];
        self.navigationItem.rightBarButtonItems = barButtonItems;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if (self.isHigh) {
        self.headerTextLabel.text = self.originalHeader;
    } else {
        self.headerTextLabel.text = @"You are here because you’ve decided that you want to drink less.\n\nNow, take a moment to imagine yourself as this person who drinks less. What would it mean for you?\n\nBuilding up a new identity as someone who does not drink excessively is an important part of drinking less.\n\nSometimes the consequences of drinking too much are not what you intended or wanted to happen.\n\nIt can be helpful to think about these negative consequences of drinking too much when you’re trying to drink less.";
    }
    CGRect rect = self.tableView.tableHeaderView.frame;
    rect.size = [self.tableView.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    self.tableView.tableHeaderView.frame = rect;
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    
    [self.tableView reloadData];
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"identity"];
    
    [self.tipView showTipToConstant:40];
    
    //    special case when "explore" will be completed
    //    https://github.com/PortablePixels/DrinkLess/issues/187
    if ([[PXStepGuide loadCompletedSteps] count] == 2) {
        
        [PXStepGuide completeStepWithID:@"explore"];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![PXGroupsManager sharedManager].highID.boolValue) {
        return 0;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    [PXStepGuide completeStepWithID:@"explore"];
}

- (BOOL)shouldNavigateWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"PXIdentityStack"]) {
        [self promptAndShowIdentityStack];
        return NO;
    }
    else if ([identifier isEqualToString:@"PXFlipsidesStack"]) {
        [self showFlipsidesStack];
        return NO;
    }
    return [super shouldNavigateWithIdentifier:identifier];
}

- (void)closeIdentityStack {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Stacks

- (void)promptAndShowIdentityStack {
    PXUserIdentity *userIdentity = [PXUserIdentity loadUserIdentity];

    // i.e. if they've not finished a round, then just go ahead
    if (![self userHasCompletedOnce:userIdentity]) {
        [self showIdentityStackForceRestart:NO];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Would you like to either review your previous entry or start again?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Review", @"Start Again", nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) return;
    if (buttonIndex == 1) { // Review
        [self showIdentityStackForceRestart:NO];
    } else {                // Restart
        [self showIdentityStackForceRestart:YES];
    }
}

- (void)showIdentityStackForceRestart:(BOOL)forceRestart {
    PXUserIdentity *userIdentity = [PXUserIdentity loadUserIdentity];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:self.storyboardName bundle:nil];
    NSMutableArray *viewControllers = [NSMutableArray array];
    
    // Blank out for forced restart
    if (forceRestart) {
        [[[PXUserIdentity alloc] init] save];  // blank it out
        userIdentity = [PXUserIdentity loadUserIdentity];
    }
    
    // VCs
    UIViewController *introVC = [storyboard instantiateViewControllerWithIdentifier:@"PXIdentityIntroVC"];
    UIViewController *photoVC = [storyboard instantiateViewControllerWithIdentifier:@"PXIdentityPhotoVC"];
    UIViewController *aspectsVC = [storyboard instantiateViewControllerWithIdentifier:@"PXIdentityAspectsVC"];
    UIViewController *contraVC = [storyboard instantiateViewControllerWithIdentifier:@"PXIdentityContradictionsVC"];
    UIViewController *exampleVC = [storyboard instantiateViewControllerWithIdentifier:@"PXIdentityExampleVC"];

    // If not forcing a restart and we've been through once, then go to the important screen but add all the proper stack
    if ([self userHasCompletedOnce:userIdentity] && !forceRestart) {
        viewControllers = @[introVC, photoVC, aspectsVC].mutableCopy;
    } else {
        // Otherwise, add the stack up to and inc the next step
        [viewControllers addObject:introVC];
        if (userIdentity.hasSeenIntro) { [viewControllers addObject:photoVC]; }
        if (userIdentity.photo) { [viewControllers addObject:aspectsVC]; }
        if (userIdentity.importantAspects.count) { [viewControllers addObject:contraVC]; }
        if (userIdentity.contradictedAspects.count) { [viewControllers addObject:exampleVC]; }
    }

    // Dependancy injection
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeIdentityStack)];
    for (UIViewController *viewController in viewControllers) {
        NSString *key = @"userIdentity";
        SEL selector = NSSelectorFromString(key);
        if ([viewController respondsToSelector:selector]) {
            [viewController setValue:userIdentity forKey:key];
        }
        viewController.navigationItem.rightBarButtonItem = closeButton;
    }
    NSArray *stack = [self.navigationController.viewControllers arrayByAddingObjectsFromArray:viewControllers];
    [self.navigationController setViewControllers:stack animated:YES];
}

/** Common check for whether user has been through the journey at least once */
- (BOOL)userHasCompletedOnce:(PXUserIdentity *)userIdentity {
    return (userIdentity.contradictedAspects.count > 0);
}

- (void)showFlipsidesStack {
    PXUserFlipsides *userFlipsides = [PXUserFlipsides loadFlipsides];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:self.storyboardName bundle:nil];
    NSMutableArray *viewControllers = [NSMutableArray array];
    
    // Push the identity stack up to where they've entered data
    [viewControllers addObject:[storyboard instantiateViewControllerWithIdentifier:@"PXFlipsidesIntroVC"]];
    if (userFlipsides.hasSeenIntro) {
        [viewControllers addObject:[storyboard instantiateViewControllerWithIdentifier:@"PXFlipsidesVC"]];
    }
    // Dependancy injection
    for (UIViewController *viewController in viewControllers) {
        NSString *key = @"userFlipsides";
        SEL selector = NSSelectorFromString(key);
        if ([viewController respondsToSelector:selector]) {
            [viewController setValue:userFlipsides forKey:key];
        }
    }
    NSArray *stack = [self.navigationController.viewControllers arrayByAddingObjectsFromArray:viewControllers];
    [self.navigationController setViewControllers:stack animated:YES];
}

- (void)showInfo {
    [PXInfoViewController showResource:@"identity-high" fromViewController:self];
}




@end
