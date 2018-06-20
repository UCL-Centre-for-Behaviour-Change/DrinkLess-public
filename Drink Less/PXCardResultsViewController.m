//
//  PXCardResultsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardResultsViewController.h"
#import "PXBarPlot.h"
#import <CorePlot-CocoaTouch.h>
#import "PXUserGameHistory.h"

@interface PXCardResultsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *hostingView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerConstraint;
@property (strong, nonatomic) PXBarPlot *barPlot;

@end

@implementation PXCardResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Card results";
    
    BOOL beatPersonalBest = NO;
    NSNumber *userMaxScore;
    NSDate *lastPlayedDate;
    NSInteger attempts = self.userGameHistory.cardGameLogs.count;
    
    if (attempts > 1) {
        CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] init];
        hostingView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:hostingView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(hostingView);
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[hostingView]|" options:0 metrics:nil views:views]];
        [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[hostingView(270)]|" options:0 metrics:nil views:views]];
        
        self.barPlot = [[PXBarPlot alloc] initWithHostingView:hostingView];
        self.barPlot.xAxisDateFormat = @"HH:mm";
        self.barPlot.xAxisSpecialDateFormat = @"d MMM";
        self.barPlot.isGameBarPlot = YES;
        
        NSString *positivePlot = @"Positive";
        NSString *negativePlot = @"Negative";
        self.barPlot.plots = @[@{PXPlotIdentifier: positivePlot,
                                 PXColorKey: [UIColor drinkLessGreenColor]},
                               @{PXPlotIdentifier: negativePlot,
                                 PXColorKey: [UIColor goalRedColor]}];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        NSArray *gameHistory = [self.userGameHistory.cardGameLogs sortedArrayUsingDescriptors:@[sortByDate]];
        lastPlayedDate = [gameHistory.lastObject date];
        NSDate *previousDate = nil;
        NSString *yKey = @"score";
        
        NSMutableArray *plotData = [NSMutableArray array];
        for (NSInteger i = 0; i < gameHistory.count; i++) {
            PXCardGameLog *gameLog = gameHistory[i];
            BOOL firstRecordOfDay = ![NSDate isDate:gameLog.date sameDayAsDate:previousDate];
            BOOL isPositive = gameLog.score.floatValue >= 0.0;
            NSString *plotIdentifier = isPositive ? positivePlot : negativePlot;
            [plotData addObject:@{PXPlotIdentifier: plotIdentifier,
                                  PXDateKey: gameLog.date,
                                  yKey: [gameLog valueForKey:yKey],
                                  PXSpecialDateKey: @(firstRecordOfDay)}];
            previousDate = gameLog.date;
        }
        self.barPlot.plotData = plotData;
        
        CGFloat minScore = 0.0;
        CGFloat maxScore = 10.0;
        NSNumber *userMinScore = [gameHistory valueForKeyPath:[NSString stringWithFormat:@"@min.%@", yKey]];
        userMaxScore = [gameHistory valueForKeyPath:[NSString stringWithFormat:@"@max.%@", yKey]];
        CGFloat minYValue = MIN(userMinScore.floatValue, minScore);
        CGFloat maxYValue = MAX(userMaxScore.floatValue, maxScore);
        [self.barPlot setXTitle:nil yTitle:nil xKey:nil yKey:yKey minYValue:minYValue maxYValue:maxYValue goalValue:0.0 displayAsPercentage:NO axisTypeX:PXAxisTypeDate showLegend:NO];
        
        NSSortDescriptor *sortByScore = [NSSortDescriptor sortDescriptorWithKey:yKey ascending:YES];
        PXCardGameLog *highestScoringLog = [gameHistory sortedArrayUsingDescriptors:@[sortByScore]].lastObject;
        beatPersonalBest = (highestScoringLog == self.gameLog);
    }
    
    if (self.gameLog) {
        NSInteger score = self.gameLog.score.integerValue;
        NSString *status = [self statusForScore:score];
        NSInteger successes = self.gameLog.successes.integerValue;
        NSString *correctText = [NSString stringWithFormat:@"%@! You got %li correct.", status, (long)successes];
        if (beatPersonalBest) {
            correctText = [correctText stringByAppendingString:@"\nYou beat your personal best!"];
        }
        self.scoreLabel.text = correctText;
        self.messageLabel.text = [self messageForAttempt:attempts];
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"Yes please, no thanks";
        self.scoreLabel.text = @"Previous scores";
        self.buttonContainerConstraint.constant = 0.0;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"dd/MM/yyyy - HH:mm";
        
        NSDictionary *highlightedAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor]};
        NSAttributedString *timesPlayed = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%li", (long)attempts] attributes:highlightedAttributes];
        NSAttributedString *highestScore = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%li", (long)userMaxScore.integerValue] attributes:highlightedAttributes];
        NSAttributedString *lastPlayed = [[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:lastPlayedDate] attributes:highlightedAttributes];
        
        NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:@"Times played: "];
        [message appendAttributedString:timesPlayed];
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nHighest score: "]];
        [message appendAttributedString:highestScore];
        [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nLast played: "]];
        [message appendAttributedString:lastPlayed];
        self.messageLabel.attributedText = message;
    }
}

- (NSString *)statusForScore:(NSInteger)score {
    if (score <= 0.0) return @"Could do better";
    if (score <= 10.0) return @"Good";
    if (score <= 20.0) return @"Well done";
    if (score <= 35.0) return @"Excellent";
    return @"Amazing";
}

- (NSString *)messageForAttempt:(NSInteger)attempt {
    if (attempt == 2 || attempt == 3) {
        return @"You have finished the game. Do come back and play again to see if you are getting any faster!";
    }
    return @"You have finished the game. Remember practice makes perfect. Come back and play again to see if you are getting any faster.";
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    
    // Center the scrollView vertically if the content size height has changed
    CGFloat height = self.scrollView.contentSize.height;
    CGFloat verticalSpace = self.scrollView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.scrollView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.scrollEnabled = YES;
    }
}

@end
