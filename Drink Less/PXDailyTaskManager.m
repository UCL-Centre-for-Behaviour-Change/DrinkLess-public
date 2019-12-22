//
//  PXDailyTaskManager.m
//  drinkless
//
//  Created by Edward Warrender on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDailyTaskManager.h"
#import "PXGroupsManager.h"
#import "PXFollowUpSurveyManager.h"
#import "PXDebug.h"
#import "drinkless-Swift.h"

static NSString *const PXLastCheckDateKey = @"taskDate";
static NSString *const PXAvailableTasksIDsKey = @"availableTasksIDs";
static NSString *const PXCompletedTasksIDsKey = @"completedTasksIDs";
static NSString *const PXSeenRandomTasksIDsKey = @"seenTasksIDs";
static NSString *const PXDayCounterKey = @"dayCounter";

@interface PXDailyTaskManager ()

@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) PXGroupsManager *groupsManager;
@property (strong, nonatomic) NSDate *lastCheckDate;
@property (strong, nonatomic) NSMutableSet *seenRandomTasksIDs;
@property (nonatomic) NSInteger dayCounter;

@end

@implementation PXDailyTaskManager

+ (instancetype)sharedManager {
    static PXDailyTaskManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DailyTasks" ofType:@"plist"];
        _tasks = [NSDictionary dictionaryWithContentsOfFile:path];
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _groupsManager = [PXGroupsManager sharedManager];
        [self load];
    }
    return self;
}

#pragma mark - Persistence

- (void)load {
    _lastCheckDate = [self.userDefaults objectForKey:PXLastCheckDateKey];
    _availableTaskIDs = [NSMutableArray arrayWithArray:[self.userDefaults objectForKey:PXAvailableTasksIDsKey]];
    _completedTaskIDs = [NSMutableSet setWithArray:[self.userDefaults objectForKey:PXCompletedTasksIDsKey]];
    _seenRandomTasksIDs = [NSMutableSet setWithArray:[self.userDefaults objectForKey:PXSeenRandomTasksIDsKey]];
    _dayCounter = [self.userDefaults integerForKey:PXDayCounterKey];
    // ^^^ Why does that need to be here?
}

- (void)save {
    [self.userDefaults setObject:_lastCheckDate forKey:PXLastCheckDateKey];
    [self.userDefaults setObject:_availableTaskIDs forKey:PXAvailableTasksIDsKey];
    [self.userDefaults setObject:_completedTaskIDs.allObjects forKey:PXCompletedTasksIDsKey];
    [self.userDefaults setObject:_seenRandomTasksIDs.allObjects forKey:PXSeenRandomTasksIDsKey];
    [self.userDefaults setInteger:_dayCounter forKey:PXDayCounterKey];
    [self.userDefaults synchronize];
}

#pragma mark - Tasks

- (void)completeTaskWithID:(NSString *)identifier {
    // (why the conditional? or why not check completedTaskIds instead)
    if ([self.availableTaskIDs containsObject:identifier]) {
        [self.completedTaskIDs addObject:identifier];
    }
    [self save];
}

- (void)checkForNewTasks {
#if DBG_DASHBOARD_TASK_FORCE_RECHECK
    self.lastCheckDate = nil;
#endif
    NSDate *previousCheckDate = self.lastCheckDate;
    NSDate *today = [NSDate strictDateFromToday];
    if ([today isEqualToDate:previousCheckDate]) return;
    
    // Every 3 days show a selection of the "random" tasks (I think! -HK) This seems weird way to track the days lapsed
    if (previousCheckDate) {
        self.dayCounter += [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:previousCheckDate toDate:today options:0].day;
        if (labs(self.dayCounter) >= 3) {
            self.dayCounter = 0;
        }
    }

    self.completedTaskIDs = [NSMutableSet set];
    self.availableTaskIDs = [NSMutableArray array];
    NSMutableArray *randomIDs = [NSMutableArray array];

    // Add task associated the user's group. Random's we'll add just one from...
    for (NSString *identifier in self.tasks.allKeys) {
        NSDictionary *task = self.tasks[identifier];
        BOOL eligible = [self isEligibleForTaskWithID:identifier];
        if (eligible) {
            if ([task[@"random"] boolValue]) {
                [randomIDs addObject:identifier];
            } else {
                [self.availableTaskIDs addObject:identifier];
            }
        }
    }
    
    // RANDOM TASK
    // Add random task every 3 days
    BOOL forceRandom = NO;
#if DBG_DASHBOARD_FORCE_RANDOM
    forceRandom = YES;
#endif
    if (self.dayCounter == 0 || forceRandom) {
        // Reset to show again after all have been shown
        NSMutableArray *remainingRandomIDs = randomIDs.mutableCopy;
        [remainingRandomIDs removeObjectsInArray:self.seenRandomTasksIDs.allObjects];
        if (remainingRandomIDs.count == 0) {
            remainingRandomIDs = randomIDs;
            self.seenRandomTasksIDs = [NSMutableSet set];
        }
        
        // Select one at random and add it to the available and seen
        NSUInteger randomIndex = arc4random_uniform((u_int32_t)remainingRandomIDs.count);
        NSString *identifier = remainingRandomIDs[randomIndex];
        [self.availableTaskIDs addObject:identifier];
        [self.seenRandomTasksIDs addObject:identifier];
    }
    
    // AUDIT REPORT FOLLOW UP
    // Queue up if after 28 days
    AuditData *latestAuditData = AuditData.latest;
    NSDate *lastDate = [latestAuditData.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:AuditData.latest.timezone];
    
    NSInteger daysSinceLastAuditFollowUp = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:lastDate toDate:today options:0].day;
    BOOL forceShowAudit = NO;
#if DBG_DASHBOARD_TASK_FORCE_SHOW_AUDIT
    forceShowAudit = YES;
#endif
    NSInteger SHOW_AFTER_DAYS = 28;
#if DBG_DASHBOARD_SHOW_AUDIT_TASK_AFTER_DAYS
    SHOW_AFTER_DAYS = DBG_DASHBOARD_SHOW_AUDIT_TASK_AFTER_DAYS;
#endif
    
    if (daysSinceLastAuditFollowUp < SHOW_AFTER_DAYS && !forceShowAudit) {
        [self.availableTaskIDs removeObject:@"audit-follow-up"];
    }
    
    self.lastCheckDate = today;
    [self save];
}

//---------------------------------------------------------------------

- (BOOL)isEligibleForTaskWithID:(NSString *)identifier {
    NSDictionary *task = self.tasks[identifier];
    NSString *group = task[@"group"];
    if (group) {
        if ([self.groupsManager respondsToSelector:NSSelectorFromString(group)]) {
            if (![[self.groupsManager valueForKey:group] boolValue]) {
                return NO;
            }
        }
    }
    return YES;
}

@end
