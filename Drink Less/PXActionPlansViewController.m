//
//  PXActionPlansViewController.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXActionPlansViewController.h"
#import "PXActionPlanView.h"
#import "PXEditActionPlanViewController.h"
#import "PXYourActionPlansViewController.h"
#import "PXUserActionPlans.h"
#import "PXActionPlan.h"
#import "PXDailyTaskManager.h"
#import <AVFoundation/AVFoundation.h>
#import "TSMessageView.h"
#import "PXInfoViewController.h"
#import "UIViewController+PXHelpers.h"
#import "drinkless-Swift.h"

@interface PXActionPlansViewController () <PXEditActionPlanViewControllerDelegate>

@property (weak, nonatomic) IBOutlet PXActionPlanView *actionPlanView;
@property (strong, nonatomic) PXUserActionPlans *userActionPlans;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation PXActionPlansViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userActionPlans = [PXUserActionPlans loadActionPlans];
    self.actionPlanView.ifTextLabel.text = @"I’ve had two drinks and someone offers to buy me another";
    self.actionPlanView.thenTextLabel.text = @"I’ll say, “No thank you, I’ve got a really busy day tomorrow”";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Action plans"];
    
    [self checkAndShowTipIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Init audio only if enabled
    self.audioPlayer = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"]) {
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"DrinkSuccess" withExtension:@"wav"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.audioPlayer prepareToPlay];
        });
    }
    
    [self.tableView layoutIfNeeded];
    self.actionPlanView.collapsed = YES;
    [self.actionPlanView setCollapsed:NO animated:YES delay:0.5];
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"action-plans"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"createActionPlan"]) {
        PXEditActionPlanViewController *editActionPlanVC = segue.destinationViewController;
        editActionPlanVC.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"yourActionPlans"]) {
        PXYourActionPlansViewController *yourActionPlansVC = segue.destinationViewController;
        yourActionPlansVC.userActionPlans = self.userActionPlans;
    }
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"action-plans" fromViewController:self];
}

#pragma mark - PXEditActionPlanViewControllerDelegate

- (void)didCancelEditing:(PXEditActionPlanViewController *)editActionPlanViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didFinishEditing:(PXEditActionPlanViewController *)editActionPlanViewController {
    PXActionPlan *actionPlan = editActionPlanViewController.actionPlan;
    [self.userActionPlans.actionPlans addObject:actionPlan];
    [actionPlan saveAndLogToServer:self.userActionPlans];
    [self.navigationController popViewControllerAnimated:YES];
    
    [TSMessage showNotificationInViewController:self
                                          title:@"Well done on setting a new action plan"
                                       subtitle:nil
                                           type:TSMessageNotificationTypeSuccess
                                       duration:2.0];
    // Delay sound by 0.4 seconds to sync with TSMessage
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 400), dispatch_get_main_queue(), ^{
        self.audioPlayer.currentTime = 0;
        [self.audioPlayer play];
    });
}

@end
