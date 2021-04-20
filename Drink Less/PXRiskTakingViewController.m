//
//  PXRiskTakingViewController.m
//  drinkless
//
//  Created by Edward Warrender on 18/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXRiskTakingViewController.h"
#import "PXBalloonView.h"
#import "PXSolidButton.h"
#import <AVFoundation/AVFoundation.h>
#import "PXDailyTaskManager.h"
#import "drinkless-Swift.h"

static NSInteger const PXMaximumRoundsCount = 10;
static NSInteger const PXMaximumInflationCount = 30;
static CGFloat const PXPoundsPerInflation = 0.5;

/** Still used?? */
@interface PXRiskTakingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *totalEarnedLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastBalloonLabel;
@property (weak, nonatomic) IBOutlet PXSolidButton *inflateButton;
@property (weak, nonatomic) IBOutlet PXSolidButton *collectButton;
@property (weak, nonatomic) IBOutlet PXBalloonView *balloonView;

@property (strong, nonatomic) CAGradientLayer *gradientLayer;
@property (strong, nonatomic) NSNumberFormatter *currencyFormatter;
@property (strong, nonatomic) AVAudioPlayer *inflateSound;
@property (strong, nonatomic) AVAudioPlayer *explodeSound;

@property (nonatomic, getter = hasStartedGame) BOOL startedGame;
@property (nonatomic, getter = areButtonsEnabled) BOOL buttonsEnabled;
@property (nonatomic) NSInteger roundIndex;
@property (nonatomic) NSInteger inflationIndex;
@property (nonatomic) CGFloat capacity;
@property (nonatomic) CGFloat totalEarned;
@property (nonatomic) CGFloat lastEarned;

@end

@implementation PXRiskTakingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Risk taking";
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[(id)[UIColor colorWithWhite:0.88 alpha:1.0].CGColor,
                                  (id)[UIColor colorWithWhite:0.98 alpha:1.0].CGColor];
    self.gradientLayer.locations = @[@0.2, @0.6];
    self.gradientLayer.rasterizationScale = [UIScreen mainScreen].scale;
    self.gradientLayer.shouldRasterize = YES;
    [self.view.layer insertSublayer:self.gradientLayer atIndex:0];
    
    self.totalEarnedLabel.textColor = [UIColor drinkLessGreenColor];
    self.lastBalloonLabel.textColor = [UIColor drinkLessGreenColor];
    self.currencyFormatter = [[NSNumberFormatter alloc] init];
    self.currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    self.currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Init audio only if enabled
    self.inflateSound = nil;
    self.explodeSound = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"]) {
        NSURL *inflateURL = [[NSBundle mainBundle] URLForResource:@"BalloonInflate" withExtension:@"wav"];
        NSURL *explodeURL = [[NSBundle mainBundle] URLForResource:@"BalloonExplode" withExtension:@"wav"];
        self.inflateSound = [[AVAudioPlayer alloc] initWithContentsOfURL:inflateURL error:nil];
        self.explodeSound = [[AVAudioPlayer alloc] initWithContentsOfURL:explodeURL error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.inflateSound prepareToPlay];
            [self.explodeSound prepareToPlay];
        });
    }
    
    self.gradientLayer.frame = self.view.bounds;
    
    if (!self.hasStartedGame) {
        self.startedGame = YES;
        [self startGame];
    }
}

#pragma mark - Properties

- (void)setTotalEarned:(CGFloat)totalEarned {
    _totalEarned = totalEarned;
    
    self.totalEarnedLabel.text = [self.currencyFormatter stringFromNumber:@(totalEarned)];
}

- (void)setLastEarned:(CGFloat)lastEarned {
    _lastEarned = lastEarned;
    
   self.lastBalloonLabel.text = [self.currencyFormatter stringFromNumber:@(lastEarned)];
}

- (void)setButtonsEnabled:(BOOL)buttonsEnabled {
    _buttonsEnabled = buttonsEnabled;
    
    BOOL animated = buttonsEnabled;
    if (self.inflationIndex == 0) {
        [self.collectButton setEnabled:NO animated:animated];
    } else {
        [self.collectButton setEnabled:buttonsEnabled animated:animated];
    }
    [self.inflateButton setEnabled:buttonsEnabled animated:animated];
}

#pragma mark - Actions

- (IBAction)pressedInflate:(id)sender {
    NSInteger popChance = PXMaximumInflationCount - self.inflationIndex;
    BOOL hasReachedLimit = popChance == 0;
    BOOL shouldPopRandomly = arc4random_uniform((u_int32_t)popChance + 1) == 0;
    if (hasReachedLimit || shouldPopRandomly) {
        self.buttonsEnabled = NO;
        [self.balloonView explodeWithCompletion:^{
            self.buttonsEnabled = YES;
            
            self.lastEarned = 0.0;
            [self nextRound];
        }];
        self.explodeSound.currentTime = 0;
        [self.explodeSound play];
        return;
    }
    self.inflationIndex++;
    self.capacity = self.inflationIndex / (float)PXMaximumInflationCount;
    self.buttonsEnabled = NO;
    [self.balloonView inflateToCapacity:self.capacity completion:^{
        self.buttonsEnabled = YES;
    }];
    self.inflateSound.currentTime = 0;
    [self.inflateSound play];
}

- (IBAction)pressedCollect:(id)sender {
    self.buttonsEnabled = NO;
    [self.balloonView collectWithCompletion:^{
        self.buttonsEnabled = YES;
        
        self.lastEarned = PXPoundsPerInflation * self.inflationIndex;
        self.totalEarned += self.lastEarned;
        [self nextRound];
    }];
}

- (IBAction)pressedExit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)unwindToRiskTaking:(UIStoryboardSegue *)storyboard {
    
}

#pragma mark - Game

- (void)startGame {
    self.totalEarned = 0.0;
    self.lastEarned = 0.0;
    self.roundIndex = 0;
    [self startRound];
}

- (void)startRound {
    self.inflationIndex = 0;
    
    self.buttonsEnabled = NO;
    [self.balloonView resetWithCompletion:^{
        self.buttonsEnabled = YES;
    }];
}

- (void)nextRound {
    self.roundIndex++;
    if (self.roundIndex >= PXMaximumRoundsCount) {
        [self gameOver];
    } else {
        [self startRound];
    }
}

- (void)gameOver {
    NSString *totalEarnedString = [self.currencyFormatter stringFromNumber:@(self.totalEarned)];
    NSString *message = [NSString stringWithFormat:@"You managed to earn %@ in %li rounds", totalEarnedString, (long)self.roundIndex];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Over" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction: [UIAlertAction actionWithTitle:@"Play again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startGame];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self pressedExit:nil];
    }]];
    [alert showIn:self];
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"risk-taking"];
}



@end
