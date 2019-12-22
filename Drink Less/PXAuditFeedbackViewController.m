//
//  PXAuditFeedbackViewController.m
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAuditFeedbackViewController.h"
#import "PXGroupsManager.h"
#import "PXIntroManager.h"
#import "PXInfoViewController.h"
#import "PXDailyTaskManager.h"
#import "PXEditGoalViewController.h"
#import "drinkless-Swift.h"


@interface PXAuditFeedbackViewController ()

@property (nonatomic, weak) IBOutlet UIView *highGroupView;
@property (nonatomic, weak) IBOutlet UIView *lowGroupView;
@property (nonatomic) BOOL isOnboarding;

@end

@implementation PXAuditFeedbackViewController

+ (instancetype)auditFeedbackViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"PXIntroVC5"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isOnboarding = VCInjector.shared.isOnboarding;

    self.buttonContainerHidden = self.isButtonContainerHidden;

    self.navigationItem.hidesBackButton = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    
    self.screenName = @"Audit results of how you think you compare";
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXHideProgressToolbar" object:nil userInfo:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL isHigh = YES; //[PXGroupsManager sharedManager].highNM.boolValue;
    self.title = isHigh ? @"How your drinking compares" : @"Alcohol advice";
    // Add help for high only
    if (true) {
        UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
        self.navigationItem.rightBarButtonItem = barItem;
    }
    
    self.highGroupView.hidden = !isHigh;
    self.lowGroupView.hidden = isHigh;
}

//---------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"feedback"]) {
        [self tappedContinue:nil];
    }
}

//---------------------------------------------------------------------

#pragma mark - Properties

- (void)setButtonContainerHidden:(BOOL)buttonContainerHidden {
    _buttonContainerHidden = buttonContainerHidden;
    
    if (self.isViewLoaded) {
        for (UIViewController *childViewController in self.childViewControllers) {
            if ([childViewController respondsToSelector:@selector(setButtonContainerHidden:)]) {
                [childViewController setValue:@(buttonContainerHidden) forKey:@"buttonContainerHidden"];
            }
        }
    }
}

#pragma mark - Actions

- (IBAction)tappedContinue:(id)sender {
    if (self.isOnboarding) {
        PXIntroManager *introManager = [PXIntroManager sharedManager];
        introManager.stage = PXIntroStageThinkDrinkQuestion;
        [introManager save];
    }
    
   // Different pathways if onboarding versus a follow up
    if (self.isOnboarding) {
        [self performSegueWithIdentifier:@"PXIntroHelpfulVC" sender:nil];
    } else {
        
        [[PXDailyTaskManager sharedManager] completeTaskWithID:@"audit-follow-up"];
        
        // Insert the AuditHistory overview vc onto the nav stack and then we'll pop back to that animated...
        AuditHistoryOverviewVC *auditHistoryVC = [AuditHistoryOverviewVC instantiateFromStoryboard];
        UINavigationController *navVC = self.navigationController;
        NSMutableArray<UIViewController *> *vcStack = navVC.viewControllers.mutableCopy;
        [vcStack insertObject:auditHistoryVC atIndex:1];
        navVC.viewControllers = [NSArray arrayWithArray:vcStack];
        [navVC popToViewController:auditHistoryVC animated:YES];
    }
}

- (void)showInfo {
    [PXInfoViewController showResource:@"intro-compare" fromViewController:self];
}




@end
