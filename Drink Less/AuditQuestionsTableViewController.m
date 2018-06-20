//
//  AuditQuestionsTableViewController.m
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "AuditQuestionsTableViewController.h"
#import "PXUnitsGuideViewController.h"
#import "PXIntroManager.h"
#import <Parse/Parse.h>
#import <Google/Analytics.h>
#import "UIViewController+PXHelpers.h"

static NSString *const PXGenderKey = @"gender";
static NSString *const PXTitleKey = @"questiontitle";

@interface AuditQuestionsTableViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSDictionary *plist;
@property (strong, nonatomic) NSMutableArray *questions;
@property (strong, nonatomic) PXIntroManager *introManager;

@end

@implementation AuditQuestionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.introManager = [PXIntroManager sharedManager];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AuditQuestions" ofType:@"plist"];
    self.plist = [NSDictionary dictionaryWithContentsOfFile:path];
    
#if DEBUG
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_autoselect)];
    gr.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:gr];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self checkAndShowTipIfNeeded];
    
    [PXTrackedViewController trackScreenName:@"Your drinking (Audit questions)"];
}

- (IBAction)pressedInfoButton:(id)sender {
    [self presentViewController:[PXUnitsGuideViewController navigationController] animated:YES completion:nil];
}

#pragma mark - Properties

- (NSMutableArray *)questions {
    if (!_questions) {
        _questions = [[NSMutableArray alloc] init];
        
        BOOL firstQuestionIsZero = NO;
        BOOL secondQuestionIsZero = NO;
        BOOL thirdQuestionIsZero = NO;
        NSString *skipToQuestionID = nil;
        
        NSNumber *genderRow = self.introManager.gender;
        NSString *gender = self.plist[PXGenderKey][@"answers"][genderRow.unsignedIntegerValue][@"answer"];
        
        NSArray *questionIDs = [self.plist.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2 options:NSNumericSearch];
        }];
        for (NSString *questionID in questionIDs) {
            if (skipToQuestionID) {
                if ([questionID isEqualToString:skipToQuestionID]) {
                    // Reached question so stop skipping
                    skipToQuestionID = nil;
                } else {
                    // Skip this question and remove it's answer
                    [self.introManager.auditAnswers removeObjectForKey:questionID];
                    continue;
                }
            }
            
            NSMutableDictionary *question = [self.plist[questionID] mutableCopy];
            if (!question[PXTitleKey]) {
                NSString *genderKey = [NSString stringWithFormat:@"%@-%@", PXTitleKey, gender.lowercaseString];
                if (question[genderKey]) {
                    question[PXTitleKey] = question[genderKey];
                }
            }
            question[@"questionID"] = questionID;
            [_questions addObject:question];
            
            NSNumber *answer = self.introManager.auditAnswers[questionID];
            if (answer) {
                if ([questionID isEqualToString:@"question1"]) {
                    firstQuestionIsZero = (answer.integerValue == 0);
                    if (firstQuestionIsZero) {
                        skipToQuestionID = @"question9";
                    }
                } else if ([questionID isEqualToString:@"question2"]) {
                    secondQuestionIsZero = (answer.integerValue == 0);
                } else if ([questionID isEqualToString:@"question3"]) {
                    thirdQuestionIsZero = (answer.integerValue == 0);
                    if (secondQuestionIsZero && thirdQuestionIsZero) {
                        skipToQuestionID = @"question9";
                    }
                }
            }
        }
    }
    return _questions;
}

- (IBAction)pressedContinue:(id)sender {
    if (self.introManager.auditAnswers.count < self.questions.count) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer all the questions" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Are you sure you want to submit your answers?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        alert.delegate = self;
        [alert show];
        return;
    }
}

- (int)calcAuditScore {
    int auditScore = 0;
    for (NSDictionary *questionDict in self.questions) {
        NSNumber *answer = self.introManager.auditAnswers[questionDict[@"questionID"]];
        NSDictionary *answerDict = questionDict[@"answers"][answer.integerValue];
        auditScore += [answerDict[@"scorevalue"] integerValue];
    }
    return auditScore;
}

- (void)reloadTableViewAnimated {
    [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        [self.tableView reloadData];
                    } completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.questions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *questionDict = [self.questions objectAtIndex:section];
    return [questionDict objectForKey:PXTitleKey];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    NSRange range = [text rangeOfString:@"units" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:view.textLabel.text];
        [attributedText addAttributes:linkAttributes range:range];
        view.textLabel.attributedText = attributedText;
        
        if (view.gestureRecognizers.count == 0) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedInfoButton:)];
            [view addGestureRecognizer:tapGesture];
        }
    } else {
        for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
            [view removeGestureRecognizer:gestureRecognizer];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *questionDict = [self.questions objectAtIndex:section];
    NSArray *answersArray = [questionDict objectForKey:@"answers"];
    return answersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"auditCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSDictionary *questionDict = [self.questions objectAtIndex:indexPath.section];
    NSArray *answersArray = [questionDict objectForKey:@"answers"];
    NSDictionary *answerDict = [answersArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [answerDict objectForKey:@"answer"];
    
    NSNumber *selected = self.introManager.auditAnswers[questionDict[@"questionID"]];
    if (selected) {
        if (indexPath.row == selected.integerValue) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *questionDict = [self.questions objectAtIndex:indexPath.section];
    [self.introManager.auditAnswers setObject:@(indexPath.row) forKey:questionDict[@"questionID"]];
    
    // Rebuild the questions array when certain questions are answered
    NSString *questionID = questionDict[@"questionID"];
    if ([questionID isEqualToString:@"question1"] ||
        [questionID isEqualToString:@"gender"] ||
        [questionID isEqualToString:@"question2"] ||
        [questionID isEqualToString:@"question3"]) {
        self.questions = nil;
    }
    [self reloadTableViewAnimated];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        self.introManager.auditScore = @([self calcAuditScore]);
        self.introManager.stage = PXIntroStageAuditResults;
        [self.introManager save];
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                              action:@"continue and confirm on audit(your drinking) questions"  // Event action (required)
                                                               label:@"continue"          // Event label
                                                               value:nil] build]];    // Event value
        
        
        [self performSegueWithIdentifier:@"PXShowAuditResults" sender:nil];
    }
}

// for quick debugging
- (void)_autoselect
{
    NSIndexPath *idxp;
    for (int i=0; i<_questions.count; i++) {
        NSUInteger ans = [_questions[i][@"answers"] count]-1;
        idxp = [NSIndexPath indexPathForRow:ans inSection:i];
        [self tableView:self.tableView didSelectRowAtIndexPath:idxp];
        //[self.tableView selectRowAtIndexPath:idxp animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView scrollToRowAtIndexPath:idxp atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

@end
