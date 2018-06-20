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
#import <Google/Analytics.h>

@interface PXAuditFeedbackViewController ()

@property (nonatomic, weak) IBOutlet UIView *highGroupView;
@property (nonatomic, weak) IBOutlet UIView *lowGroupView;

@end

@implementation PXAuditFeedbackViewController

+ (instancetype)auditFeedbackViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"PXIntroVC5"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttonContainerHidden = self.isButtonContainerHidden;

    self.navigationItem.hidesBackButton = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    
    self.screenName = @"Audit results of how you think you compare";
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXHideProgressToolbar" object:nil userInfo:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL isHigh = [PXGroupsManager sharedManager].highNM.boolValue;
    self.title = isHigh ? @"How your drinking compares" : @"Alcohol advice";
    // Add help for high only
    if (isHigh) {
        UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
        self.navigationItem.rightBarButtonItem = barItem;
    }
    
    self.highGroupView.hidden = !isHigh;
    self.lowGroupView.hidden = isHigh;
}


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
    PXIntroManager *introManager = [PXIntroManager sharedManager];
    introManager.stage = PXIntroStageThinkDrinkQuestion;
    [introManager save];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                          action:@"tapped_continue_on_audit_compare_results"  // Event action (required)
                                                           label:@"next"          // Event label
                                                           value:nil] build]];    // Event value
    
    [self performSegueWithIdentifier:@"PXShowThinkDrinkQuestion" sender:nil];
}

- (void)showInfo {
    [PXInfoViewController showResource:@"intro-compare" fromViewController:self];
}




@end
