//
//  PXCardViewController.m
//  Cards
//
//  Created by Edward Warrender on 02/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardViewController.h"
#import "PXDeskView.h"
#import "PXUserGameHistory.h"
#import "PXCardResultsViewController.h"
#import "PXDailyTaskManager.h"
#import "PXGroupsManager.h"
#import "PXGamePreferences.h"
#import "PXInfoViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSTimeInterval const PXCountdownDuration = 60.0;

@interface PXCardViewController () <PXDeskViewDelegate>

@property (weak, nonatomic) IBOutlet PXDeskView *deskView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval secondsRemaining;
@property (nonatomic) NSInteger numberOfSuccesses;
@property (nonatomic) NSInteger numberOfErrors;
@property (strong, nonatomic) AVAudioPlayer *successSound;
@property (strong, nonatomic) AVAudioPlayer *failSound;
@property (nonatomic, readonly) BOOL isHigh;

@end

@implementation PXCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Card view";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Cards" ofType:@"plist"];
    self.deskView.cards = [NSArray arrayWithContentsOfFile:path];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _isHigh = [PXGroupsManager sharedManager].highAAT.boolValue;

    // Init sound if enabled
    self.successSound = nil;
    self.failSound = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"]) {
        NSURL *successURL = [[NSBundle mainBundle] URLForResource:@"GameSuccess" withExtension:@"wav"];
        NSURL *failURL = [[NSBundle mainBundle] URLForResource:@"GameFail" withExtension:@"wav"];
        self.successSound = [[AVAudioPlayer alloc] initWithContentsOfURL:successURL error:nil];
        self.failSound = [[AVAudioPlayer alloc] initWithContentsOfURL:failURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.successSound prepareToPlay];
            [self.failSound prepareToPlay];
        });
    }
    
    [self startGame];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startCountdown];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (!self.deskView.hasEndedRound) {
        [self stopCountdownWithCompletion:NULL];
    }
}

- (void)startGame {
    BOOL isPushTall = [PXGamePreferences isPushTall];
    NSString *pushOrientation = [PXGamePreferences pushOrientation];
    NSString *pullOrientation = [PXGamePreferences pullOrientation];
    self.instructionsLabel.text = [NSString stringWithFormat:@"Say “Yes please” to %@ pictures (pull towards you) and “No thanks” to %@ pictures (push away from you).", pullOrientation, pushOrientation];
    
    self.deskView.landscapePositive = isPushTall;
    self.deskView.lowGroup = ![PXGroupsManager sharedManager].highAAT.boolValue;
    self.numberOfSuccesses = 0;
    self.numberOfErrors = 0;
    
    // Shows the user the countdown early as a hint
    [self.deskView prepareRoundWithCountdown:PXCountdownDuration];
    self.secondsRemaining = PXCountdownDuration;
}

#pragma mark - Timer

- (void)startCountdown {
    [self.deskView prepareRoundWithCountdown:PXCountdownDuration];
    [self.deskView startRoundWithCompletion:^{
        self.secondsRemaining = PXCountdownDuration;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tickTimer:) userInfo:nil repeats:YES];
    }];
}

- (void)stopCountdownWithCompletion:(void (^)(void))completion {
    [self.timer invalidate];
    self.timer = nil;
    [self.deskView endRoundWithCompletion:completion];
}

- (void)tickTimer:(NSTimer *)timer {
    self.secondsRemaining--;
    if (self.secondsRemaining <= 0.0) {
        [self stopCountdownWithCompletion:^{
            [self performSegueWithIdentifier:@"saveAndShowResults" sender:nil];
        }];
    }
}

- (void)setSecondsRemaining:(NSTimeInterval)secondsRemaining {
    self.deskView.secondsRemaining = secondsRemaining;
    _secondsRemaining = secondsRemaining;
}

#pragma - PXDeskViewDelegate

- (void)didFailTrial {
    self.numberOfErrors++;
    
    self.failSound.currentTime = 0;
    [self.failSound play];
}

- (void)didPassTrial {
    self.numberOfSuccesses++;
    
    self.successSound.currentTime = 0;
    [self.successSound play];
}

#pragma mark - Navigation

- (IBAction)unwindToCardGame:(UIStoryboardSegue *)segue {
    // User came back to game
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"saveAndShowResults"]) {
        PXCardGameLog *gameLog = [[PXCardGameLog alloc] initWithSuccesses:self.numberOfSuccesses errors:self.numberOfErrors];
        [self.userGameHistory saveGameLog:gameLog];
        
        PXCardResultsViewController *cardResultsVC = (PXCardResultsViewController *)segue.destinationViewController;
        cardResultsVC.userGameHistory = self.userGameHistory;
        cardResultsVC.gameLog = gameLog;
        
        [[PXDailyTaskManager sharedManager] completeTaskWithID:@"approach-avoidance"];
    }
}



@end
