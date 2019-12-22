//
//  ReviewAuditTableViewController.m
//  drinkless
//
//  Created by Greg Plumbly on 04/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "drinkless-Swift.h"
#import "ReviewAuditTableViewController.h"
#import "PXIntroManager.h"


static NSString *const PXGenderKey = @"gender";
static NSString *const PXTitleKey = @"questiontitle";
static NSString *const PXQuestionKey = @"question";
static NSString *const PXAnswerKey = @"answer";
static NSString *const PXAnswersKey = @"answers";

@interface ReviewAuditTableViewController ()

@property (strong, nonatomic) NSMutableArray *questionsAndAnswers;
@property (nonatomic, strong) AuditData *auditData;

@end

@implementation ReviewAuditTableViewController

+ (instancetype)reviewAuditViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Activities" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"reviewAuditVC"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.navigationItem.title = @"Audit review";
//
//    self.auditData = AuditData.latestRecorded()
//
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"AuditQuestions" ofType:@"plist"];
//    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
//
//    NSArray *questionIDs = [plist.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        return [obj1 compare:obj2 options:NSNumericSearch];
//    }];
//
//    NSNumber *genderIndex = self.introManager.auditAnswers[PXGenderKey];
//    NSString *gender = plist[PXGenderKey][PXAnswersKey][genderIndex.unsignedIntegerValue][PXAnswerKey];
//
//    self.questionsAndAnswers = [NSMutableArray arrayWithCapacity:questionIDs.count];
//    for (NSString *questionID in questionIDs) {
//        NSDictionary *information = plist[questionID];
//        NSInteger answerIndex = [self.introManager.auditAnswers[questionID] integerValue];
//        NSString *answer = information[PXAnswersKey][answerIndex][PXAnswerKey];
//        NSString *question = information[PXTitleKey];
//        if (!question) {
//            NSString *genderKey = [NSString stringWithFormat:@"%@-%@", PXTitleKey, gender.lowercaseString];
//            question = information[genderKey];
//        }
//        NSDictionary *dictionary = @{PXQuestionKey: question,
//                                     PXAnswerKey: answer};
//        [self.questionsAndAnswers addObject:dictionary];
//    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    
    [DataServer.shared trackScreenView:@"Review audit"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.questionsAndAnswers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *question = self.questionsAndAnswers[section][PXQuestionKey];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEEE MMMM d, YYYY"];
    NSString *dateString = [dateFormat stringFromDate:today];
    
    if (section == 0) {
        return [NSString stringWithFormat:@"You gave the following answers on %@:\n\n%@", dateString, question];
    }
    return question;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"auditReviewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.questionsAndAnswers[indexPath.section][PXAnswerKey];
    return cell;
}

@end
