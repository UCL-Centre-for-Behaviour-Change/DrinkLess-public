//
//  FollowUpTableViewController.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/11/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "FollowUpTableViewController.h"
#import "PXSolidButton.h"
#import "PXFollowUpManager.h"
#import "PFUser.h"
#import "PXIntroManager.h"

@interface FollowUpTableViewController ()

@property (nonatomic, strong) NSArray *questionsArray;
@property (nonatomic, strong) NSArray *screenQuestionsArray;
@property (weak, nonatomic) IBOutlet PXSolidButton *continueButton;
@property (nonatomic, weak) PXFollowUpManager *followUpManager;
@property (nonatomic, assign) BOOL isFemale;
@end

@implementation FollowUpTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Follow up";
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"FollowUpQuestions" ofType:@"plist"];
    self.questionsArray = [[NSMutableArray arrayWithContentsOfFile:filepath] firstObject];
    self.screenQuestionsArray = self.questionsArray[self.screenIndex];
    self.followUpManager = [PXFollowUpManager sharedManager];
    if (self.screenIndex == 3) {
        
        [self.continueButton setTitle:@"Finish" forState:UIControlStateNormal];
    }
    
    self.isFemale = [PXIntroManager sharedManager].gender.boolValue;
}

#pragma mark - Action methods

- (IBAction)pressedContinue:(id)sender {

    NSInteger answerCount = 0;
    switch (self.screenIndex) {
        case 0:
            answerCount = [self.questionsArray[0] count];
            break;
        case 1:
            answerCount = [self.questionsArray[0] count] + [self.questionsArray[1] count];
            break;
        case 2:
            answerCount = [self.questionsArray[0] count] + [self.questionsArray[1] count] + [self.questionsArray[2] count];
            break;
        case 3:
            answerCount = [self.questionsArray[0] count] + [self.questionsArray[1] count] + [self.questionsArray[2] count] + [self.questionsArray[3] count];
        default:
            break;
    }
    
    if ([[PXFollowUpManager sharedManager].answers count] < answerCount) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer all the questions" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    
    if (self.screenIndex < 3) {
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Home" bundle:[NSBundle mainBundle]];
        FollowUpTableViewController *fuVC = [sb instantiateViewControllerWithIdentifier:@"FollowUpID"];
        fuVC.screenIndex = self.screenIndex + 1;
        [self.navigationController pushViewController:fuVC animated:YES];
    }
    else {
        [self saveAnswers];    
        [self.followUpManager surveyCompleted];
        // Present result VC
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Home" bundle:[NSBundle mainBundle]];
        UIViewController *resultVC = [sb instantiateViewControllerWithIdentifier:@"FollowUpCompleteScreen"];
        resultVC.title = @"How your drinking has changed";
        UILabel *resultLbl = [resultVC.view viewWithTag:1];
        UIButton *doneBtn =  [resultVC.view viewWithTag:2];
        resultLbl.text = [NSString stringWithFormat:resultLbl.text, [PXIntroManager sharedManager].auditScore.integerValue, [self calcAuditScore]];
        [doneBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationController pushViewController:resultVC animated:YES];
    }
}

- (void)dismiss {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)saveAnswers {
    
    if ([PFUser currentUser]) {
        PFObject *pfFollowUpAnswers = [PFObject objectWithClassName:@"PXFollowUp"];
        [pfFollowUpAnswers setObject:[PFUser currentUser] forKey:@"Author"];
        
        for (NSString *key in self.followUpManager.answers) {
            [pfFollowUpAnswers setObject:[self.followUpManager.answers objectForKey:key] forKey:key];
        }
        
        [pfFollowUpAnswers setObject:@([self calcAuditScore]) forKey:@"NewScore"];
        [pfFollowUpAnswers setObject:[PXIntroManager sharedManager].auditScore forKey:@"OrigScore"];
        
        NSLog(@"[PARSE]: Saving Follow Up Answers");
        [pfFollowUpAnswers saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"[PARSE] Saved Follow Up Answers to Parse");
            } else {
                NSLog(@"[PARSE]: Error saving Follow Up Answers: %@", error);
            }
        }];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.screenQuestionsArray count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary* questionDict = self.screenQuestionsArray[section];
    NSString *genderKey = [NSString stringWithFormat:@"question-%@", self.isFemale ? @"female" : @"male"];
    return questionDict[genderKey] ? questionDict[genderKey] : questionDict[@"question"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *questionDict = self.screenQuestionsArray[section];
    NSArray *answers = questionDict[@"answers"];
    if (answers) {
        return answers.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* questionDict = self.screenQuestionsArray[indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OptionCell" forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray* answers = questionDict[@"answers"];
    if ([answers[indexPath.row] isKindOfClass:NSString.class]) {
        cell.textLabel.text = answers[indexPath.row];
    } else {
        cell.textLabel.text = answers[indexPath.row][@"answer"];
    }
    
    
    NSNumber* selected = [self.followUpManager getAnswerScreen:self.screenIndex section:indexPath.section];
    if (selected) {
        if (indexPath.row == selected.integerValue) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self.followUpManager setAnswer:indexPath.row screen:self.screenIndex section:indexPath.section];
    [self.tableView reloadData];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

// Mirrors the one in AuditQuestionsTableVC but with a slightly different data structuring
- (int)calcAuditScore {
    int auditScore = 0;
    for (int sectionIdx=0; sectionIdx<self.questionsArray.count; sectionIdx++) {
        
        NSArray *questions = self.questionsArray[sectionIdx];
        
        for (int questionIdx=0; questionIdx<questions.count; questionIdx++) {
            // Get the answer index and tally the score
            NSInteger answerIdx = [[self.followUpManager getAnswerScreen:sectionIdx section:questionIdx] integerValue];
            NSArray *answers = questions[questionIdx][@"answers"];
            NSInteger value = [answers[answerIdx] isKindOfClass:NSString.class] ? 0 : [answers[answerIdx][@"scorevalue"] integerValue];  // will be nil,0 for answers without score values
            auditScore += value;
        }
    }
    return auditScore;
}

@end
