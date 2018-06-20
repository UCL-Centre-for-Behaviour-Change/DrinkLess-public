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
#import "PXFollowUpManager.h"

static NSString *const PXTaskDateKey = @"taskDate";
static NSString *const PXAvailableTasksIDsKey = @"availableTasksIDs";
static NSString *const PXCompletedTasksIDsKey = @"completedTasksIDs";
static NSString *const PXSeenTasksIDsKey = @"seenTasksIDs";
static NSString *const PXDayCounterKey = @"dayCounter";

@interface PXDailyTaskManager ()

@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) PXGroupsManager *groupsManager;
@property (strong, nonatomic) NSDate *taskDate;
@property (strong, nonatomic) NSMutableSet *seenTaskIDs;
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
    _taskDate = [self.userDefaults objectForKey:PXTaskDateKey];
    _availableTaskIDs = [NSMutableArray arrayWithArray:[self.userDefaults objectForKey:PXAvailableTasksIDsKey]];
    _completedTaskIDs = [NSMutableSet setWithArray:[self.userDefaults objectForKey:PXCompletedTasksIDsKey]];
    _seenTaskIDs = [NSMutableSet setWithArray:[self.userDefaults objectForKey:PXSeenTasksIDsKey]];
    _dayCounter = [self.userDefaults integerForKey:PXDayCounterKey];
    [self checkAddingFollowUp];
}

- (void)save {
    [self.userDefaults setObject:_taskDate forKey:PXTaskDateKey];
    [self.userDefaults setObject:_availableTaskIDs forKey:PXAvailableTasksIDsKey];
    [self.userDefaults setObject:_completedTaskIDs.allObjects forKey:PXCompletedTasksIDsKey];
    [self.userDefaults setObject:_seenTaskIDs.allObjects forKey:PXSeenTasksIDsKey];
    [self.userDefaults setInteger:_dayCounter forKey:PXDayCounterKey];
    [self.userDefaults synchronize];
}

- (void)checkAddingFollowUp {
    
    BOOL showFollowUpSurvey = [[PXFollowUpManager sharedManager] hasDone];
    if (!showFollowUpSurvey) {
     
        if (![self.availableTaskIDs containsObject:@"follow-up"]) {
            [self.availableTaskIDs addObject:@"follow-up"];
        }
    }
    else {
        if ([self.availableTaskIDs containsObject:@"follow-up"]) {
            [self.availableTaskIDs removeObject:@"follow-up"];
        }
    }
}

#pragma mark - Tasks

- (void)completeTaskWithID:(NSString *)identifier {
    if ([self.availableTaskIDs containsObject:identifier]) {
        [self.completedTaskIDs addObject:identifier];
    }
    [self save];
}

- (void)checkForNewTasks {
    NSDate *previousDate = self.taskDate;
    self.taskDate = [NSDate strictDateFromToday];
    if ([self.taskDate isEqualToDate:previousDate]) return;
    
    if (previousDate) {
        self.dayCounter += [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:previousDate toDate:self.taskDate options:0].day;
        if (labs(self.dayCounter) >= 3) {
            self.dayCounter = 0;
        }
    }
    self.completedTaskIDs = [NSMutableSet set];
    self.availableTaskIDs = [NSMutableArray array];
    NSMutableArray *randomIDs = [NSMutableArray array];
    
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
    if (self.dayCounter == 0) {
        NSMutableArray *remainingRandomIDs = randomIDs.mutableCopy;
        [remainingRandomIDs removeObjectsInArray:self.seenTaskIDs.allObjects];
        if (remainingRandomIDs.count == 0) {
            remainingRandomIDs = randomIDs;
            self.seenTaskIDs = [NSMutableSet set];
        }
        NSUInteger randomIndex = arc4random_uniform((u_int32_t)remainingRandomIDs.count);
        NSString *identifier = remainingRandomIDs[randomIndex];
        [self.availableTaskIDs addObject:identifier];
        [self.seenTaskIDs addObject:identifier];
    }
    [self checkAddingFollowUp];
    [self save];
}

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
