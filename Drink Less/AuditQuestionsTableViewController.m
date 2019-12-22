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
#import "drinkless-Swift.h"
#import "UIViewController+PXHelpers.h"
#import "drinkless-Swift.h"

static NSString *const PXGenderKey = @"gender";
static NSString *const PXTitleKey = @"questiontitle";

/**
 @TODO: questionsDict should be modelled properly
 @TODO: calcScore should then be moved into AuditCalculator
 */
@interface AuditQuestionsTableViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSDictionary *plist;
@property (strong, nonatomic) NSMutableArray *questions;
@property (strong, nonatomic) PXIntroManager *introManager;
@property (nonatomic, strong) AuditData *auditData;
@property (nonatomic, strong) DemographicData *demographicData;
@property (nonatomic) BOOL isOnboarding;

@end

@implementation AuditQuestionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.introManager = [PXIntroManager sharedManager];
    self.auditData = VCInjector.shared.workingAuditData;
    self.demographicData = VCInjector.shared.demographicData;
    self.isOnboarding = VCInjector.shared.isOnboarding;
    
    NSString *path;
    if (self.isOnboarding) {
        path = [[NSBundle mainBundle] pathForResource:@"AuditQuestions" ofType:@"plist"];
    } else {
        path = [[NSBundle mainBundle] pathForResource:@"AuditQuestionsFollowUp" ofType:@"plist"];
    }
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
    
    [DataServer.shared trackScreenView:@"Your drinking (Audit questions)"];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil) {
        [self _autoselect];
    }
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
        
//        NSInteger genderRow = self.demographicData.gender;
//        NSString *gender = self.plist[PXGenderKey][@"answers"][genderRow.unsignedIntegerValue][@"answer"];
//
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
                    [self.auditData clearAnswerWithQuestionId:questionID];
                    continue;
                }
            }
            
            NSMutableDictionary *question = [self.plist[questionID] mutableCopy];
//            if (!question[PXTitleKey]) {
//                NSString *genderKey = [NSString stringWithFormat:@"%@-%@", PXTitleKey, gender.lowercaseString];
//                if (question[genderKey]) {
//                    question[PXTitleKey] = question[genderKey];
//                }
//            }
            question[@"questionID"] = questionID;
            [_questions addObject:question];
            
            NSNumber *answer = [self.auditData answerWithQuestionId:questionID];
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
    if ([self.auditData answerCount] < self.questions.count) {
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

- (void)assignAuditScores:(AuditData *)auditData {
    [auditData calculateAuditScoresWithIsOnboarding:self.isOnboarding];
    
//    int auditScore = 0;
//    int auditCScore = 0;
//    int c = 0;
//    for (NSDictionary *questionDict in self.questions) {
//        NSNumber *answer = [self.auditData answerWithQuestionId:questionDict[@"questionID"]];
//        NSDictionary *answerDict = questionDict[@"answers"][answer.integerValue];
//        NSInteger score = [answerDict[@"scorevalue"] integerValue];
//        auditScore += score;
//        if (c++ < 3) {
//            auditCScore += score;
//        }
//    }
//    if (self.isOnboarding) {
//        auditData.auditScore = auditScore;
//    }
//    auditData.auditCScore = auditCScore;
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
    
    // Make "units" into a link
    NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    NSRange range = [text rangeOfString:@"units" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        CGFloat fontSize = view.textLabel.font.pointSize;
        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                         NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize]
                                         };
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
    
    NSNumber *selected = [self.auditData answerWithQuestionId:questionDict[@"questionID"]];
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
    [self.auditData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(indexPath.row)];
    
    // Rebuild the questions array when certain questions are answered
    NSString *questionID = questionDict[@"questionID"];
    if ([questionID isEqualToString:@"question1"] ||
        [questionID isEqualToString:@"gender"] ||       // obsolete i think
        [questionID isEqualToString:@"question2"] ||
        [questionID isEqualToString:@"question3"]) {
        self.questions = nil;
    }
    [self reloadTableViewAnimated];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self assignAuditScores:self.auditData];
        
        if (self.isOnboarding) {
            self.introManager.stage = PXIntroStageAuditResults;
            [self.introManager save];
        } else {
            // This will need to be done after the demographic data in the onboarding
            // @TODO DRY this up and get it into some sort of delegate or higher level VC - all this data related stuff actually. It's too important and specific to be buried like this
            self.auditData.demographicKey = self.demographicData.demographicKey;
            [self.auditData calculateActualPercentiles];
            [self.auditData saveWithLocalOnly:NO];
        }
        
        if (self.isOnboarding) {
            [self performSegueWithIdentifier:@"PXShowAuditResults" sender:nil];
        } else {
            // For re-audits skip to the feedback infographics
            [self performSegueWithIdentifier:@"AuditSkipToFeedbackSegue" sender:nil];
        }
    }
}

// for quick debugging
- (void)_autoselect
{
    NSIndexPath *idxp;
    for (int i=0; i<_questions.count; i++) {
        NSUInteger c = [_questions[i][@"answers"] count];
        NSUInteger ans = c - 1 - arc4random() % c;
        idxp = [NSIndexPath indexPathForRow:ans inSection:i];
        [self tableView:self.tableView didSelectRowAtIndexPath:idxp];
        //[self.tableView selectRowAtIndexPath:idxp animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView scrollToRowAtIndexPath:idxp atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil) {
        //[self pressedContinue:nil];
        [self alertView:nil clickedButtonAtIndex:999];
    }
}

@end
