//
//  PXDashboardViewController.m
//  drinkless
//
//  Created by Edward Warrender on 08/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDashboardViewController.h"
#import "PXDiaryStreakCell.h"
#import "PXGoalCell.h"
#import "PXTaskCell.h"
#import "PXLinkCell.h"
#import "PXGoalReasonCell.h"
#import "PXCoreDataManager.h"
#import "PXGoal.h"
#import "PXGoalProgressViewController.h"
#import "PXGoalStatistics.h"
#import "PXDailyTaskManager.h"
#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "PXMoodDiaryViewController.h"
#import "OneMonthFollowUpTableViewController.h"
#import "PXGroupsManager.h"
#import "PXTabBarController.h"
#import "PXTimeCalculator.h"
#import "PXQuickLinks.h"
#import "PXInfoViewController.h"
#import "PXTipView.h"
#import "PXUnitsGuideViewController.h"
#import <Parse/Parse.h>

static NSString *const PXTaskCellIdentifier = @"taskCell";
static NSString *const PXDiaryStreakCellIdentifier = @"diaryStreakCell";
static NSString *const PXGoalCellIdentifier = @"goalCell";
static NSString *const PXGoalReasonCellIdentifier = @"goalReasonCell";
static NSString *const PXBasicCellIdentifier = @"basicCell";
static NSString *const PXLinkCellIdentifier = @"linkCell";

typedef NS_ENUM(NSInteger, PXSection) {
    PXSectionTask = 0,
    PXSectionAchievement,
    PXSectionGoal,
    PXSectionLink,
    PXSectionCount
};

@interface PXDashboardViewController ()

@property (strong, nonatomic) PXUserMoodDiaries *userMoodDiaries;
@property (strong, nonatomic) PXDailyTaskManager *dailyTaskManager;
@property (strong, nonatomic) NSMutableArray *lastWeekGoalsStatistics;
@property (strong, nonatomic) NSString *goalReason;
@property (strong, nonatomic) PXTimeCalculator *timeCalculator;
@property (strong, nonatomic) PXQuickLinks *quickLinks;
@property (strong, nonatomic) PXTipView *tipView;
@property (nonatomic, readonly) NSInteger daysUntilNextWeek;
@property (nonatomic, readonly) BOOL hasAvailableTasks;
@property (nonatomic, readonly) BOOL hasDiaryStreak;
@property (nonatomic, readonly) BOOL hasLastWeekGoals;
@property (nonatomic, readonly) BOOL hasActiveGoals;
@property (nonatomic, readonly) BOOL hasGoalReason;

@end

@implementation PXDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[PXGoalCell nib] forCellReuseIdentifier:PXGoalCellIdentifier];
    self.dailyTaskManager = [PXDailyTaskManager sharedManager];
    self.timeCalculator = [[PXTimeCalculator alloc] initWithMaxComponents:1];
    self.quickLinks = [[PXQuickLinks alloc] init];

    if (![PXGroupsManager sharedManager].highSM.boolValue) {
        self.tableView.tableHeaderView = nil;
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.userMoodDiaries = [PXUserMoodDiaries loadMoodDiaries];
    [self.userMoodDiaries calculateStreaks];

    self.goalReason = [[NSUserDefaults standardUserDefaults] objectForKey:@"goalReason"];

    [self.quickLinks reload];
    [self.dailyTaskManager checkForNewTasks];
    [self calculateGoalStatistics];

    [self.tableView reloadData];

    [self _checkAndShowPrivacyPolicyIfNeedsAcknowledgement];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [PXTrackedViewController trackScreenName:@"Dashboard"];

    NSMutableOrderedSet *taskIDsToRemove = [NSMutableOrderedSet orderedSetWithArray:self.dailyTaskManager.availableTaskIDs];
    [taskIDsToRemove intersectSet:self.dailyTaskManager.completedTaskIDs];
    NSLog(@"Completed task IDs: %@", self.dailyTaskManager.completedTaskIDs);
    [self.dailyTaskManager.completedTaskIDs removeAllObjects];

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    [sharedApplication beginIgnoringInteractionEvents];
    [self removeTasksWithIDs:taskIDsToRemove completion:^{
        [sharedApplication endIgnoringInteractionEvents];
        [self.dailyTaskManager save];
    }];
}

#pragma mark - Calculations

- (void)calculateGoalStatistics {
    NSDate *thisWeek = [NSDate startOfThisWeek];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];

    dateComponents.weekOfYear = -1;
    NSDate *lastWeek = [calendar dateByAddingComponents:dateComponents toDate:thisWeek options:0];

    dateComponents.weekOfYear = 1;
    NSDate *nextWeek = [calendar dateByAddingComponents:dateComponents toDate:thisWeek options:0];

    _daysUntilNextWeek = [calendar components:NSCalendarUnitDay fromDate:[NSDate strictDateFromToday] toDate:nextWeek options:0].day;

    NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
    NSDictionary *variables = @{@"EMPTY": [NSNull null], @"TODAY": [NSDate strictDateFromToday], @"LASTWEEK": lastWeek, @"THISWEEK": thisWeek};

    self.lastWeekGoalsStatistics = [self statisticsWithContext:context template:@"lastWeekGoals" variables:variables region:PXStatisticRegionLastCompleted];

    self.activeGoalsStatistics = [self statisticsWithContext:context template:@"activeGoals" variables:variables region:PXStatisticRegionCurrentIncomplete];


 //   PXGoalStatistics *gs = [self.activeGoalsStatistics objectAtIndex:0];
  //  NSLog(@"goal stats: %@", gs.goal.targetMax);

}

- (NSMutableArray *)statisticsWithContext:(NSManagedObjectContext *)context template:(NSString *)template variables:(NSDictionary *)variables region:(PXStatisticRegion)region {
    NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:template substitutionVariables:variables];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO]];
    NSArray *goals = [context executeFetchRequest:fetchRequest error:nil];

    NSMutableArray *statistics = [NSMutableArray arrayWithCapacity:goals.count];
    for (PXGoal *goal in goals) {
        PXGoalStatistics *goalStatistics = [[PXGoalStatistics alloc] initWithGoal:goal region:region];
        [statistics addObject:goalStatistics];
    }
    return statistics;
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    NSString *resource = [PXGroupsManager sharedManager].highSM.boolValue ? @"dashboard" : @"dashboardLowSM";
    [PXInfoViewController showResource:resource fromViewController:self];
}

#pragma mark - Properties

- (BOOL)isHiddenSection:(NSInteger)section {
    if (section == PXSectionAchievement) {
        return ![PXGroupsManager sharedManager].highSM.boolValue;
    }
    return NO;
}

- (BOOL)hasAvailableTasks {
    return self.dailyTaskManager.availableTaskIDs.count != 0;
}

- (BOOL)hasDiaryStreak {
    return self.userMoodDiaries.currentStreak > 1 || self.userMoodDiaries.highestStreak > 1;
}

- (BOOL)hasLastWeekGoals {
    return self.lastWeekGoalsStatistics.count != 0;
}

- (BOOL)hasActiveGoals {
    return self.activeGoalsStatistics.count != 0;
}

- (BOOL)hasGoalReason {
    return self.goalReason.length != 0;
}

#pragma mark - Tasks

- (void)removeTasksWithIDs:(NSMutableOrderedSet *)identifiers completion:(void (^)(void))completion {
    NSString *identifier = identifiers.firstObject;
    if (!identifier && completion) {
        completion();
        return;
    }
    __block NSUInteger index = [self.dailyTaskManager.availableTaskIDs indexOfObject:identifier];
    __block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:PXSectionTask];

    [UIView animateWithDuration:0.5 animations:^{
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];

    } completion:^(BOOL finished) {
        PXTaskCell *cell = (PXTaskCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [UIView transitionWithView:cell duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            cell.completed = YES;

        } completion:^(BOOL finished) {
            [self.dailyTaskManager.availableTaskIDs removeObjectAtIndex:index];
            [identifiers removeObject:identifier];

            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            if (!self.hasAvailableTasks) {
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:PXSectionTask]] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView endUpdates];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 300), dispatch_get_main_queue(), ^{
                [self removeTasksWithIDs:identifiers completion:completion];
            });
        }];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PXSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return nil;
    }
    switch (section) {
        case PXSectionTask:
            return @"We suggest";
        case PXSectionAchievement:
            return @"Your achievements";
        case PXSectionGoal:
            return @"Your active goals";
        case PXSectionLink:
            return @"Quick links";
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return CGFLOAT_MIN;
    }

    if (![PXGroupsManager sharedManager].highSM.boolValue && section == PXSectionTask) {
        return CGFLOAT_MIN;
    }

    return tableView.sectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return CGFLOAT_MIN;
    }
    return [super tableView:tableView heightForFooterInSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isHiddenSection:section]) {
        return 0;
    }
    switch (section) {
        case PXSectionTask:
            if (self.hasAvailableTasks) {
                return self.dailyTaskManager.availableTaskIDs.count;
            } else {
                return 1;
            }
        case PXSectionAchievement: {
            NSInteger rows;
            if (self.hasLastWeekGoals) {
                rows = self.lastWeekGoalsStatistics.count;
            } else {
                rows = 1;
            }
            if (self.hasDiaryStreak) {
                rows++;
            }
            return rows;
        }
        case PXSectionGoal: {
            NSInteger rows;
            if (self.hasActiveGoals) {
                rows = self.activeGoalsStatistics.count;
            } else {
                rows = 1;
            }
            if (self.hasGoalReason) {
                rows++;
            }
            return rows;
        }
        case PXSectionLink:
            return self.quickLinks.links.count;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case PXSectionAchievement: {
            if (self.hasDiaryStreak && indexPath.row == 0) {
                PXDiaryStreakCell *cell = [self cellForDiaryStreak];
                return [self autolayoutHeightForCell:cell];
            }
            if (self.hasLastWeekGoals) {
                return 54.0;
            }
            break;
        }
        case PXSectionGoal: {
            if (self.hasGoalReason && indexPath.row == 0) {
                PXGoalReasonCell *cell = [self cellForGoalReason];
                return [self autolayoutHeightForCell:cell];
            }
            if (self.hasActiveGoals) {
                return 54.0;
            } else {
                return 64.0;
            }
        }
        default:
            break;
    }
    return 44.0;
}

- (CGFloat)autolayoutHeightForCell:(UITableViewCell *)cell {
    CGRect rect = cell.bounds;
    rect.size.width = self.tableView.bounds.size.width;
    cell.bounds = rect;
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    return [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case PXSectionTask:
            if (self.hasAvailableTasks) {
                NSString *identifier = self.dailyTaskManager.availableTaskIDs[indexPath.row];
                NSDictionary *task = self.dailyTaskManager.tasks[identifier];
                return [self cellForTask:task];
            } else {
                return [self basicCellForSection:indexPath.section];
            }
        case PXSectionAchievement: {
            NSInteger row = indexPath.row;
            if (self.hasDiaryStreak) {
                row--;
                if (indexPath.row == 0) {
                    return [self cellForDiaryStreak];
                }
            }
            if (self.hasLastWeekGoals) {
                PXGoalStatistics *goalStatistics = self.lastWeekGoalsStatistics[row];
                return [self cellForGoalStatistics:goalStatistics section:indexPath.section];
            } else {
                return [self basicCellForSection:indexPath.section];
            }
        }
        case PXSectionGoal: {
            NSInteger row = indexPath.row;
            if (self.hasGoalReason) {
                row--;
                if (indexPath.row == 0) {
                    return [self cellForGoalReason];
                }
            }
            if (self.hasActiveGoals) {
                PXGoalStatistics *goalStatistics = self.activeGoalsStatistics[row];
                return [self cellForGoalStatistics:goalStatistics section:indexPath.section];
            } else {
                return [self basicCellForSection:indexPath.section];
            }
        }
        case PXSectionLink: {
            NSDictionary *link = self.quickLinks.links[indexPath.row];
            return [self cellForLink:link indexPath:indexPath];
        }
        default:
            return nil;
    }
}

- (PXDiaryStreakCell *)cellForDiaryStreak {
    PXDiaryStreakCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXDiaryStreakCellIdentifier];
    [cell showCurrentStreak:self.userMoodDiaries.currentStreak highestStreak:self.userMoodDiaries.highestStreak];
    return cell;
}

- (PXTaskCell *)cellForTask:(NSDictionary *)task {
    PXTaskCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXTaskCellIdentifier];
    cell.titleLabel.text = task[@"title"];
    cell.completed = NO;
    return cell;
}

- (PXGoalCell *)cellForGoalStatistics:(PXGoalStatistics *)goalStatistics section:(NSInteger)section {
    PXGoalCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXGoalCellIdentifier];
    PXGoal *goal = goalStatistics.goal;
    NSDictionary *data = goalStatistics.data;
    NSString *consumption = [PXGoalCalculator titleForGoalType:goal.goalType.integerValue quantity:data[PXQuantityKey]];
    cell.titleLabel.text = goal.title;

    if (section == PXSectionAchievement) {
        PXGoalStatus status = [goalStatistics.data[PXStatusKey] integerValue];
        cell.iconImageView.image = [PXGoalCalculator imageForGoalStatus:status thumbnail:YES];
        cell.subtitleLabel.text = [self textForLastWeekStatus:status];
        cell.showProgress = NO;
    }
    else {
        NSDate *toDate = data[PXToDateKey];
        NSString *time = [self.timeCalculator timeBetweenNowAndDate:toDate];

        if ([PXGroupsManager sharedManager].highSM.boolValue) {
            cell.subtitleLabel.text = [NSString stringWithFormat:@"So far %@, ends in %@", consumption, time];
        } else {
            cell.subtitleLabel.text = goal.overview;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        NSDate *fromDate = data[PXFromDateKey];
        NSTimeInterval remaining = -[fromDate timeIntervalSinceNow];
        NSTimeInterval total = [toDate timeIntervalSinceDate:fromDate];
        cell.showProgress = YES;
        cell.radialProgressLayer.progress = remaining / total;
    }
    return cell;
}

- (NSString *)textForLastWeekStatus:(PXGoalStatus)status {
    switch (status) {
        case PXGoalStatusExceeded:
            return @"You smashed this goal last week";
        case PXGoalStatusHit:
            return @"Well done, you hit last week's goal";
        case PXGoalStatusNear:
            return @"Close! Nearly hit last week's goal";
        case PXGoalStatusMissed:
            return @"Missed it. Each week is a new start";
        default:
            return @"Not enough data collected";
    }
}

- (PXGoalReasonCell *)cellForGoalReason {
    PXGoalReasonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXGoalReasonCellIdentifier];
    cell.explanationLabel.text = self.goalReason;
    return cell;
}

- (PXLinkCell *)cellForLink:(NSDictionary *)link indexPath:(NSIndexPath *)indexPath {
    PXLinkCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXLinkCellIdentifier];
    cell.iconImageView.image = [UIImage imageNamed:link[@"iconName"]];
    cell.titleLabel.text = link[@"title"];
    return cell;
}

- (UITableViewCell *)basicCellForSection:(NSInteger)section {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PXBasicCellIdentifier];
    switch (section) {
        case PXSectionTask:
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 1;
            cell.textLabel.text = @"Good work, you're all done today";
            break;
        case PXSectionAchievement:
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 1;
            cell.textLabel.text = [NSString stringWithFormat:@"Goal feedback coming in %li %@", (long)self.daysUntilNextWeek, self.daysUntilNextWeek == 1 ? @"day" : @"days"];
            break;
        case PXSectionGoal:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.text = @"Would you like to set a goal to reduce your drinking?";
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PXTabBarController *tabBarController = (PXTabBarController *)self.tabBarController;

    switch (indexPath.section) {
        case PXSectionTask:
            if (self.hasAvailableTasks) {
                NSString *identifier = self.dailyTaskManager.availableTaskIDs[indexPath.row];
                if ([identifier isEqualToString:@"approach-avoidance"]) {
                    tabBarController.selectedIndex = 3;
                }
                else if ([identifier isEqualToString:@"identity"]) {
                    tabBarController.selectedIndex = 4;
                }
                else if ([identifier isEqualToString:@"normative-misperceptions"]) {
                    [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXReviewAuditVC"]];
                }
                else if ([identifier isEqualToString:@"action-plans"]) {
                    [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXActionPlansViewController"]];
                }
                else if ([identifier isEqualToString:@"alcohol-effects"]) {
                    [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXHowAlcoholEffectsVC"]];
                }
                else if ([identifier isEqualToString:@"questionnaire"]) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FollowUp" bundle:nil];
                    OneMonthFollowUpTableViewController *followUpVC = [storyboard instantiateInitialViewController];
                    [self.navigationController pushViewController:followUpVC animated:YES];
                }
                else if ([identifier isEqualToString:@"record-drinks"]) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Progress" bundle:nil];
                    PXMoodDiaryViewController *moodDiaryVC = [storyboard instantiateViewControllerWithIdentifier:@"PXMoodDiaryVC"];
                    [self.navigationController pushViewController:moodDiaryVC animated:YES];
                }
                else if ([identifier isEqualToString:@"follow-up"]) {

                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
                    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"FollowUpID"];
                    [self.navigationController pushViewController:viewController animated:YES];
                }
            }
            break;
        case PXSectionAchievement: {
            NSInteger row = indexPath.row;
            if (self.hasDiaryStreak) {
                row--;
                if (indexPath.row == 0) {
                    break;
                }
            }
            if (![PXGroupsManager sharedManager].highSM.boolValue) {

                break;
            }
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if ([cell.reuseIdentifier isEqualToString:PXBasicCellIdentifier]) {
                break;
            }
            if (self.hasLastWeekGoals) {
                PXGoalStatistics *goalStatistics = self.lastWeekGoalsStatistics[row];
                PXGoalProgressViewController *goalProgressVC = [[PXGoalProgressViewController alloc] initWithGoal:goalStatistics.goal];
                [self.navigationController pushViewController:goalProgressVC animated:YES];
            }
            else {
                [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXGoalsNavTVC", @"PXYourGoalsVC"]];
            }
            break;
        }
        case PXSectionGoal: {
            NSInteger row = indexPath.row;
            if (self.hasGoalReason) {
                row--;
                if (indexPath.row == 0) {
                    break;
                }
            }
            if (![PXGroupsManager sharedManager].highSM.boolValue) {

                break;
            }
            if (self.hasActiveGoals) {
                PXGoalStatistics *goalStatistics = self.activeGoalsStatistics[row];
                PXGoalProgressViewController *goalProgressVC = [[PXGoalProgressViewController alloc] initWithGoal:goalStatistics.goal];
                [self.navigationController pushViewController:goalProgressVC animated:YES];
                break;
            }
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if ([cell.reuseIdentifier isEqualToString:PXBasicCellIdentifier]) {

                [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXGoalsNavTVC", @"PXYourGoalsVC"]];
            }
            break;
        }
        case PXSectionLink: {
            NSString *identifier = self.quickLinks.links[indexPath.row][@"identifier"];

            if ([identifier isEqualToString:@"alcohol-effects"]) {
                [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXHowAlcoholEffectsVC"]];
            }
            else if ([identifier isEqualToString:@"calendar"]) {
                [tabBarController selectTabAtIndex:1 storyboardName:@"Progress" pushViewControllersWithIdentifiers:@[@"PXCalendarVC"]];
            }
            else if ([identifier isEqualToString:@"units"]) {
                [self presentViewController:[PXUnitsGuideViewController navigationController] animated:YES completion:nil];
            }
            else if ([identifier isEqualToString:@"drinking-guidelines"]) {
                PXWebViewController *webViewController = [[PXWebViewController alloc] initWithResource:@"drinking-guidelines"];
             //   webViewController.resource = @"drinking-guidelines";
                 webViewController.view.backgroundColor = [UIColor whiteColor];
                webViewController.title = @"Drinking guidelines";
                [self.navigationController pushViewController:webViewController animated:YES];
            }

            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)_checkAndShowPrivacyPolicyIfNeedsAcknowledgement {
    PFUser *currentUser = [PFUser currentUser];
    if ([currentUser[@"acknowledgedPrivacyPolicy"] isEqual: @YES]) {
        PXWebViewController *vc = [[PXWebViewController alloc] initWithResource:@"privacy-changed"];
        [vc setOpenedOutsideOnboarding:YES];
        [vc.view setBackgroundColor:[UIColor whiteColor]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

@end
