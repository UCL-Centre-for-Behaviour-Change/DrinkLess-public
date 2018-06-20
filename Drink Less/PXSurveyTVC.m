//
//  PXSensationSeekingTVC.m
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXSurveyTVC.h"
#import "PXSurveyQuestionCell.h"
#import "PXSurveyTextField.h"
#import "PXPreSurveyVC.h"

@interface PXSurveyTVC () <UITextFieldDelegate>

@property (nonatomic, strong) NSArray *questions;
@property (nonatomic, strong) NSMutableArray *answers;

@end

@implementation PXSurveyTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.surveyType;

    NSString* filepath = [[NSBundle mainBundle] pathForResource:self.surveyType ofType:@"plist"];
    NSDictionary *surveyDictionary = [[NSDictionary alloc] initWithContentsOfFile:filepath];
    self.questions = surveyDictionary[@"Questions"];
    self.answers = [NSMutableArray array];
    [self.questions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.answers addObject:@""];
    }];
}

- (IBAction)submitTapped:(UIButton *)sender {
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.questions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXSurveyQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SensationQuestionCell" forIndexPath:indexPath];
    
    cell.questionLabel.text = self.questions[indexPath.row];
    cell.answerTextField.delegate = self;
    cell.answerTextField.indexPath = indexPath;
    cell.answerTextField.text = self.answers[indexPath.row];
    return cell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - textfield delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.submitButton.enabled = NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isKindOfClass:[PXSurveyTextField class]]) {
        [self.answers setObject:textField.text atIndexedSubscript:[(PXSurveyTextField*)textField indexPath].row];
    }
    self.submitButton.enabled = YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
