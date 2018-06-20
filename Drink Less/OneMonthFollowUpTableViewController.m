//
//  OneMonthFollowUpTableViewController.m
//  drinkless
//
//  Created by Greg Plumbly on 10/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "OneMonthFollowUpTableViewController.h"
#import <Parse/Parse.h>
#import "PXSliderCell.h"
#import "PXDailyTaskManager.h"

@interface OneMonthFollowUpTableViewController () <PXSliderCellDelegate>

@property (strong, nonatomic) NSMutableArray *questions;
@property (strong, nonatomic) NSMutableDictionary *usersFollowUpAnswers; //Used for cell accessory etc
@property (strong, nonatomic) NSMutableDictionary *usersFollowUpAnswersForParse;

@end

@implementation OneMonthFollowUpTableViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"One month follow up"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:@"OneMonthFollowUpQuestions" ofType:@"plist"];
    self.questions = [NSMutableArray arrayWithContentsOfFile:filepath];
    self.navigationItem.title = @"Follow Up";
    self.usersFollowUpAnswers = [[NSMutableDictionary alloc] init];
    self.usersFollowUpAnswersForParse = [[NSMutableDictionary alloc] init];
    
    //Set the untouched value of sliders
    [self.usersFollowUpAnswersForParse setValue:[NSNumber numberWithFloat:5.0] forKey:@"Question4"];
    [self.usersFollowUpAnswersForParse setValue:[NSNumber numberWithFloat:5.0] forKey:@"Question5"];
    [self.usersFollowUpAnswersForParse setValue:[NSNumber numberWithFloat:5.0] forKey:@"Question6"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return self.questions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSString *questionType = nil;
    
    if (section < self.questions.count) {
        NSDictionary* questionDict = self.questions[section];
        questionType = questionDict[@"question-type"];
        NSArray* answers = questionDict[@"answers"];
        if (answers) {
            return answers.count;
        }
    }
    
    if ([questionType isEqualToString:@"slider"]) {
        return 1;
    }

    return 0 ;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* questionDict = self.questions[section];
    return questionDict[@"questiontitle"];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *questionDict = [self.questions objectAtIndex:indexPath.section];
    NSString *questionType = questionDict[@"question-type"];
    
    if ([questionType isEqualToString:@"slider"]) {
        PXSliderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sliderCell"];
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"followUpCell" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSArray *answersArray = [questionDict objectForKey:@"answers"];
        NSDictionary *answerDict = [answersArray objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [answerDict objectForKey:@"answer"];
        
        NSNumber *selected = self.usersFollowUpAnswers[questionDict[@"questionID"]];
        
        if (selected) {
            if (indexPath.row == selected.integerValue) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *questionDict = [self.questions objectAtIndex:indexPath.section];
    NSString *questionType = questionDict[@"question-type"];
    
    if ([questionType isEqualToString:@"slider"]) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [self.usersFollowUpAnswers setObject:@(indexPath.row) forKey:questionDict[@"questionID"]];
    [self.usersFollowUpAnswersForParse setObject:cell.textLabel.text forKey:questionDict[@"questionID"]];
        
    [self.tableView reloadData];
}

#pragma mark - PXSliderCellDelegate

- (void)sliderCellChangedValue:(PXSliderCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *questionDict = [self.questions objectAtIndex:indexPath.section];
    [self.usersFollowUpAnswersForParse setObject:[NSNumber numberWithFloat:cell.slider.value] forKey:questionDict[@"questionID"]];
}

- (IBAction)submitPressed:(id)sender {
    
    if ([PFUser currentUser]) {
        PFObject *pfFollowUpAnswers = [PFObject objectWithClassName:@"PXFollowUp"];
        [pfFollowUpAnswers setObject:[PFUser currentUser] forKey:@"Author"];
        
        for (NSString *key in self.usersFollowUpAnswersForParse) {
            [pfFollowUpAnswers setObject:[self.usersFollowUpAnswersForParse objectForKey:key] forKey:key];
        }
        
        [pfFollowUpAnswers saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
            if (!error) {
                NSLog(@"Saved Follow Up Answers to Parse");
            }
        }];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"completedQuestionnaire"];
    [userDefaults synchronize];
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"questionnaire"];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
