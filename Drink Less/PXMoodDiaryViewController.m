//
//  PXMoodDiaryViewController.m
//  drinkless
//
//  Created by Edward Warrender on 05/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMoodDiaryViewController.h"
#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "PXGoalReflections.h"
#import "PXCoreDataManager.h"
#import "PXDailyTaskManager.h"
#import "PXGroupsManager.h"
#import "UINavigationController+Completion.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXCoreDataManager.h"
#import "PXTabBarController.h"
#import "PXMoodDiaryHeader.h"
#import "PXInfoViewController.h"
#import "UIViewController+PXHelpers.h"
#import "NSDate+DrinkLess.h"
#import "PXDrinkRecord+Extras.h"
#import "drinkless-Swift.h"

static CGFloat const PXSpacingHeight = 12.0;
static NSUInteger const PXDrankYesterdaySection = 2;
static NSUInteger const PXDrankMoreSection = 3;
static NSUInteger const PXReasonSection = 4;

@interface PXMoodDiaryViewController ()

@property (weak, nonatomic) IBOutlet UISlider *happySlider;
@property (weak, nonatomic) IBOutlet UISlider *productiveSlider;
@property (weak, nonatomic) IBOutlet UISlider *clearHeadedSlider;
@property (weak, nonatomic) IBOutlet UISlider *sleepSlider;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UITextView *reasonTextView;

@property (strong, nonatomic) NSDate *latestDrinkRecordDateInCurrentCalendar;
@property (strong, nonatomic) PXMoodDiary *moodDiaryEntry;
@property (strong, nonatomic) PXUserMoodDiaries *userMoodDiaries;
@property (strong, nonatomic) NSNumber *drankYesterday;
@property (strong, nonatomic) NSNumber *goalAchieved;
@property (strong, nonatomic) NSMutableSet *hiddenSections;
@property (nonatomic, getter = isHigh) BOOL high;
@property (nonatomic, getter = hasCompleted) BOOL completed;

@end

@implementation PXMoodDiaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.high = [PXGroupsManager sharedManager].highSM.boolValue;
    self.userMoodDiaries = [PXUserMoodDiaries loadMoodDiaries];
    self.completed = [self.userMoodDiaries fetchTodaysMoodDiary] != nil;
    
    self.title = self.isHigh ? @"Your hangover and you" : @"Your drinking diary";
    
    if (self.isHigh) {
        PXMoodDiaryHeader *moodDiaryHeader = [PXMoodDiaryHeader moodDiaryHeader];
        UIView *headerView = self.hasCompleted ? moodDiaryHeader.completedView : moodDiaryHeader.explanationView;
        headerView.frame = self.tableView.bounds;
        [headerView layoutIfNeeded];
        
        CGRect rect = headerView.frame;
        rect.size = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        headerView.frame = rect;
        self.tableView.tableHeaderView = headerView;
    }
    
    self.hiddenSections = [NSMutableSet set];
    if (self.isHigh && !self.hasCompleted) {
        self.moodDiaryEntry = [[PXMoodDiary alloc] init];
        self.hiddenSections = @[@(PXReasonSection)].mutableCopy;
    } else {
        for (NSInteger section = 0; section < self.tableView.numberOfSections; section++) {
            if (section != PXDrankYesterdaySection) {
                [self.hiddenSections addObject:@(section)];
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Mood diary"];
    
    [self checkAndShowTipIfNeeded];
}

- (BOOL)isHiddenSection:(NSInteger)section {
    return [self.hiddenSections containsObject:@(section)];
}

- (NSDate *)latestDrinkRecordDateInCurrentCalendar {
    if (!_latestDrinkRecordDateInCurrentCalendar) {
//        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
//        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", [NSDate strictDateFromToday]];
//        fetchRequest.resultType = NSDictionaryResultType;
//        NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"date"];
//        NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:@[keyPathExpression]];
//        NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
//        expressionDescription.name = @"date";
//        expressionDescription.expression = maxExpression;
//        expressionDescription.expressionResultType = NSDateAttributeType;
//        fetchRequest.propertiesToFetch = @[expressionDescription];
//
//        NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
//        NSArray *results = [context executeFetchRequest:fetchRequest error:NULL];
//        _latestDrinkRecordDate = results.firstObject[@"date"];
        
        // Fetch all possible contenders...
        NSDate *today = [NSDate strictDateFromToday];
        NSDate *latestDate = [today latestWorldDateWithSameCalendarDateAsThisOne];
        NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", latestDate];
        NSArray <PXDrinkRecord *> *drinkRecords = [context executeFetchRequest:fetchRequest error:NULL];
        // Now filter for the ones who's calendar date is before today (not sure why this doesnt include today. I'm just copying the above -HKS) and find the latest
        NSDate *latestDrinkRecDateInCurrCal;
        for (PXDrinkRecord *rec in drinkRecords) {
            NSTimeZone *tz = [NSTimeZone timeZoneForDrinkRecord:rec];
            NSDate *recDateInCurrCal = [rec.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:tz];
            if ([recDateInCurrCal compare:today] != NSOrderedAscending) {
                continue;
            }
            if (latestDrinkRecDateInCurrCal == nil) {
                latestDrinkRecDateInCurrCal = recDateInCurrCal;
                continue;
            }
            
            if ([recDateInCurrCal compare:latestDrinkRecDateInCurrCal] == NSOrderedDescending) {
                latestDrinkRecDateInCurrCal = recDateInCurrCal;
            }
        }
        _latestDrinkRecordDateInCurrentCalendar = latestDrinkRecDateInCurrCal;
    }
    return _latestDrinkRecordDateInCurrentCalendar;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return nil;
    }
    if (section == PXDrankYesterdaySection) {
        if (self.latestDrinkRecordDateInCurrentCalendar) {
            NSDateFormatter *dateFormatter = nil;
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"EEE, MMM dd yyyy";
            NSString *stringFromDate = [dateFormatter stringFromDate:self.latestDrinkRecordDateInCurrentCalendar];
            return [NSString stringWithFormat:@"Any more drinks since the last one recorded on %@?", stringFromDate];
        } else {
            return @"Any more drinks to record for yesterday?";
        }
    }
    if (section == PXReasonSection) {
        if (self.goalAchieved.boolValue) {
            return @"What helped? You can see this under “What has and hasn’t worked”";
        } else {
            return @"What got in the way? You can see this under “What has and hasn’t worked”.";
        }
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.hidden = [self isHiddenSection:indexPath.section];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:14.0];
        headerView.textLabel.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return FLT_EPSILON;
    }
    return PXSpacingHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return FLT_EPSILON;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isHiddenSection:indexPath.section]) {
        return FLT_EPSILON;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case PXDrankYesterdaySection:
        case PXDrankMoreSection:
            return YES;
        default:
            return NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    for (NSIndexPath *visibleIndexPath in tableView.indexPathsForVisibleRows) {
        if (visibleIndexPath.section == indexPath.section) {
            UITableViewCell *visibleCell = [tableView cellForRowAtIndexPath:visibleIndexPath];
            visibleCell.accessoryType = (visibleCell == cell) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
    }
    
    BOOL answer = (cell.tag == 1);
    if (indexPath.section == PXDrankYesterdaySection) {
        self.drankYesterday = @(answer);
    }
    else if (indexPath.section == PXDrankMoreSection) {
        self.goalAchieved = @(!answer);
        [self.hiddenSections removeObject:@(PXReasonSection)];
    }
    
    [UIView transitionWithView:tableView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.tableView reloadData];
    } completion:^(BOOL finished) {
        if (indexPath.section == PXDrankMoreSection) {
            NSIndexPath *reasonIndexPath = [NSIndexPath indexPathForRow:0 inSection:PXReasonSection];
            [tableView scrollToRowAtIndexPath:reasonIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }];
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"mood-diary" fromViewController:self];
}

- (IBAction)pressedSave:(id)sender {
    if (self.drankYesterday == nil) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer whether there are any more drinks to record" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    if (self.moodDiaryEntry) {
        self.moodDiaryEntry.date = [NSDate strictDateFromToday];
        self.moodDiaryEntry.timezone = NSCalendar.currentCalendar.timeZone.name;
        self.moodDiaryEntry.happiness = @(self.happySlider.value);
        self.moodDiaryEntry.productivity = @(self.productiveSlider.value);
        self.moodDiaryEntry.sleep = @(self.sleepSlider.value);
        self.moodDiaryEntry.clearHeaded = @(self.clearHeadedSlider.value);
        self.moodDiaryEntry.reason = self.reasonTextView.text;
        self.moodDiaryEntry.comment = self.commentTextView.text;
        self.moodDiaryEntry.goalAchieved = self.goalAchieved.boolValue;
        [self.userMoodDiaries.moodDiaries addObject:self.moodDiaryEntry];
        [self.moodDiaryEntry saveAndLogToServer:self.userMoodDiaries];
        
        // Add to goal reasons
        NSString *reason = self.moodDiaryEntry.reason;
        if (reason.length != 0) {
            PXGoalReflections *goalReflections = [PXGoalReflections loadGoalReflections];
            NSMutableArray *list = self.goalAchieved.boolValue ? goalReflections.whatHasWorked : goalReflections.whatHasNotWorked;
            [list addObject:reason];
            [goalReflections save];
        }
    }
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"record-drinks"];
    
    void (^completion)();
    if (self.drankYesterday.boolValue) {
        completion = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PXShowDrinksPanelNotification object:[NSDate yesterday]];
            });
        };
    } else {
        NSDate *fromDate;
        if (self.latestDrinkRecordDateInCurrentCalendar) {
            fromDate = [NSDate nextDayFromDate:self.latestDrinkRecordDateInCurrentCalendar];
        } else {
            fromDate = [NSDate yesterday];
        }
        NSDate *toDate = [NSDate strictDateFromToday];
        NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
        [PXAlcoholFreeRecord setFreeDay:YES fromDate:fromDate toDate:toDate context:context];
    }
    
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:completion];
    } else {
        [self.navigationController popViewControllerAnimated:YES completion:completion];
    }
}

@end
