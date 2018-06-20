//
//  PXLocalNotificationsManager.m
//  chemo-diary
//
//  Created by Brio on 27/03/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXLocalNotificationsManager.h"
#import "NSDate+DrinkLess.h"
#import "AppDelegate.h"
#import "PXMoodDiaryViewController.h"
#import "NSDate+DrinkLess.h"
#import "PXGroupsManager.h"
#import "PXTabBarController.h"
#import "UIViewController+RecordMemo.h"

#define kRepeatInterval NSDayCalendarUnit

//static NSString * const PXSurveyNotifMessage = @"Help science by responding to a brief survey?";
static NSString * const PXSurveyNotifMessage = @"Take a brief survey and enter a prize draw to win one of thirty £10 Amazon vouchers?";


NSString* const KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME = @"KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME";

NSString* const KEY_LOCALNOTIFICATION_ID = @"KEY_LOCALNOTIFICATION_ID";
NSString* const KEY_LOCALNOTIFICATION_TYPE = @"KEY_LOCALNOTIFICATION_TYPE";

NSString* const PXGoingOutReminderType = @"PXGoingOutReminderType";
NSString* const PXConsumptionReminderType = @"PXConsumptionReminderType";
NSString* const PXMemoWatchReminderType = @"PXMemoWatchReminderType";
NSString* const PXMemoRecordReminderType = @"PXMemoRecordReminderType";
NSString* const PXSurveyReminderType = @"PXSurveyReminderType";

NSString* const PXConsumptionReminderShowing = @"PXConsumptionReminderShowing";

@interface PXLocalNotificationsManager () <UIAlertViewDelegate>

@property (nonatomic, strong) NSDictionary *reminderTypes;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) UIAlertView *consumptionAlert;
@property (nonatomic, strong) UIAlertView *goingOutAlert;
@property (nonatomic, strong) UIAlertView *memoAlert;
@property (nonatomic, strong) UIAlertView *memoRecordAlert;
@property (nonatomic, strong) UIAlertView *surveyAlert;

@end

@implementation PXLocalNotificationsManager
{
    void (^_surveyAlertCallback)();
}

static NSString* KEY_REMINDER_MESSAGE = @"KEY_REMINDER_MESSAGE";
static NSString* KEY_REMINDER_INTERVAL = @"KEY_REMINDER_INTERVAL";
static NSString* KEY_REMINDER_QUESTION = @"KEY_REMINDER_QUESTION";
static NSString* KEY_REMINDER_ANSWERS = @"KEY_REMINDER_ANSWERS";

static NSString* KEY_NOTIFICATIONUSERINFO_NOTIFICATION_ID = @"KEY_NOTIFICATIONUSERINFO_NOTIFICATION_ID";

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred,^{
        _sharedObject = [[self alloc]init];
    });
    return _sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString* filepath = [[NSBundle mainBundle] pathForResource:@"ReminderTypes" ofType:@"plist"];
        _reminderTypes = [[NSDictionary alloc] initWithContentsOfFile:filepath];
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)enableAllNotificationsIfFirstRun {
    if (![self.userDefaults objectForKey:PXGoingOutReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXGoingOutReminderType];
    }
    if (![self.userDefaults objectForKey:PXConsumptionReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXConsumptionReminderType];

        [self.userDefaults setValue:[self defaultConsumptionDate] forKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
        [self.userDefaults synchronize];
    }
    if (![self.userDefaults objectForKey:PXMemoWatchReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXMemoWatchReminderType];
    }
    if (![self.userDefaults objectForKey:PXMemoRecordReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXMemoRecordReminderType];
    }
    [self.userDefaults synchronize];
}

//---------------------------------------------------------------------

- (void)scheduleSurveyNotification
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = PXSurveyNotifMessage;
    //Alert title is available from iOS 8.2
//    if ([localNotification respondsToSelector:@selector(alertTitle)]) {
//        localNotification.alertTitle = PXSurveyNotifTitle;
//    }
    //localNotification.applicationIconBadgeNumber = 1;
    localNotification.soundName = @"attention.caf";
    //localNotification.applicationIconBadgeNumber = 1;
    localNotification.userInfo = @{KEY_LOCALNOTIFICATION_ID : @"survey", KEY_LOCALNOTIFICATION_TYPE: PXSurveyReminderType};
    localNotification.repeatInterval = 0;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    //[PXLocalNotificationsManager performSelector:@selector(logScheduledNotifications) withObject:nil afterDelay:0];
}

//---------------------------------------------------------------------

- (void)showSurveyPromptAlertViewWithCallback:(void (^)())didAgreeToSurvey
{
    self.surveyAlert =  [[UIAlertView alloc] init];
    self.surveyAlert.title = PXSurveyNotifMessage;
    //self.surveyAlert.message = PXSurveyNotifBody;
    self.surveyAlert.delegate = self;
    [self.surveyAlert addButtonWithTitle:@"Yes"];
    [self.surveyAlert addButtonWithTitle:@"No thanks"];
    [self.surveyAlert show];
    
    _surveyAlertCallback = didAgreeToSurvey;
}

//---------------------------------------------------------------------


- (NSDate*)defaultConsumptionDate {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    // Extract date components into components1
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];

    // Combine date and time into components3
    NSDateComponents *components3 = [[NSDateComponents alloc] init];

    [components3 setYear:components1.year];
    [components3 setMonth:components1.month];
    [components3 setDay:components1.day];

    [components3 setHour:11];
    [components3 setMinute:5];
    [components3 setSecond:0];

    // Generate a new NSDate from components3.
    NSDate *combinedDate = [[gregorianCalendar dateFromComponents:components3] nextOccurrenceOfTimeInDate];
    return combinedDate;
}

- (void)updateConsumptionReminder {
    [self removeLocalNotificationWithType:PXConsumptionReminderType ID:@"0"];
    if ([[self.userDefaults objectForKey:PXConsumptionReminderType] boolValue] == YES) {
        if ([self.userDefaults objectForKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME]) {
            NSDate *givenDate = [self.userDefaults objectForKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
            NSDate *firstFireDate = [givenDate nextOccurrenceOfTimeInDate];

            [self addLocalNotificationForDate:firstFireDate
                                      message:@"Please complete your diary"
                                         type:PXConsumptionReminderType
                                           ID:@"0"
                                       repeat:NSCalendarUnitDay];
        }
    }
}


- (void)showNotification:(UILocalNotification *)notification {
    if ([notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXConsumptionReminderType]) {
        NSDictionary *consumptionReminder = self.reminderTypes[PXConsumptionReminderType];
        self.consumptionAlert =  [[UIAlertView alloc] init];
        self.consumptionAlert.title = consumptionReminder[KEY_REMINDER_QUESTION];
        self.consumptionAlert.delegate = self;
        NSArray *possibleAnswers = consumptionReminder[KEY_REMINDER_ANSWERS];
        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
            [self.consumptionAlert addButtonWithTitle:answer];
        }];
        [self.consumptionAlert show];
    }
    else if ([notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXGoingOutReminderType]) {
        NSDictionary *consumptionReminder = self.reminderTypes[PXGoingOutReminderType];
        self.goingOutAlert =  [[UIAlertView alloc] init];
        self.goingOutAlert.title = consumptionReminder[KEY_REMINDER_QUESTION];
        self.goingOutAlert.delegate = self;
        NSArray *possibleAnswers = consumptionReminder[KEY_REMINDER_ANSWERS];
        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
            [self.goingOutAlert addButtonWithTitle:answer];
        }];
        [self.goingOutAlert show];
    }
    else if ([notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXMemoRecordReminderType]) {
        NSDictionary *memoReminder = self.reminderTypes[PXMemoRecordReminderType];
        self.memoRecordAlert =  [[UIAlertView alloc] init];
        self.memoRecordAlert.title = memoReminder[KEY_REMINDER_QUESTION];
        self.memoRecordAlert.delegate = self;
        NSArray *possibleAnswers = memoReminder[KEY_REMINDER_ANSWERS];
        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
            [self.memoRecordAlert addButtonWithTitle:answer];
        }];
        [self.memoRecordAlert show];
    }
    else if ([notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXMemoWatchReminderType]) {
        NSDictionary *memoReminder = self.reminderTypes[PXMemoWatchReminderType];
        self.memoAlert =  [[UIAlertView alloc] init];
        self.memoAlert.title = memoReminder[KEY_REMINDER_QUESTION];
        self.memoAlert.delegate = self;
        NSArray *possibleAnswers = memoReminder[KEY_REMINDER_ANSWERS];
        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
            [self.memoAlert addButtonWithTitle:answer];
        }];
        [self.memoAlert show];
    }
}




//---------------------------------------------------------------------

- (BOOL)notificationIsSurveyType:(UILocalNotification *)notification
{
    return [notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXSurveyReminderType];
}

//---------------------------------------------------------------------

#pragma mark - uialertview delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.consumptionAlert) {
        switch (buttonIndex) {
            case 0:
                [self presentMoodDiaryIfNotCurrentlyShowing];
                break;
            default:
                break;
        }
    } else if (alertView == self.goingOutAlert) {
        switch (buttonIndex) {
            case 0:
                [[NSNotificationCenter defaultCenter] postNotificationName:PXShowDrinksPanelNotification object:nil];
                break;
            default:
                break;
        }
    } else if (alertView == self.memoRecordAlert ) {
        switch (buttonIndex) {
            case 0:
                [self presentRecordMemo];
                break;
            default:
                break;
        }
    } else if (alertView == self.memoAlert) {
        switch (buttonIndex) {
            case 0:
                [self presentWatchMemoIfNotCurrentlyShowing];
                break;
            default:
                break;
        }
    } else if (alertView == self.surveyAlert) {
        switch (buttonIndex) {
            case 0:
                _surveyAlertCallback();
                break;
                
            default:
                break;
        }
        _surveyAlertCallback = nil;
    }
}

#pragma mark - navigation

- (void)presentMoodDiaryIfNotCurrentlyShowing {
    UIViewController *presentingVC = [((AppDelegate *)[UIApplication sharedApplication].delegate) topMostViewController];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Progress" bundle:nil];
    UINavigationController *navigationController = [storyBoard instantiateViewControllerWithIdentifier:@"PXMoodDiaryNC"];
    
    if (![presentingVC isKindOfClass:[navigationController class]]) {
        [presentingVC presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)presentMoodDiaryAfterDrinksTrackerIfNeeded {
    if (self.consumptionReminderShowing) {
        self.consumptionReminderShowing = NO;
        [self presentMoodDiaryIfNotCurrentlyShowing];
    }
}

- (void)presentRecordMemo {
    UIViewController *presentingVC = [(AppDelegate*)[[UIApplication sharedApplication] delegate] topMostViewController];
    [presentingVC recordVideoMemo];
}

- (void)presentWatchMemoIfNotCurrentlyShowing {
//    UIViewController *presentingVC = [(AppDelegate*)[[UIApplication sharedApplication] delegate] topMostViewController];
//    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"PXIdentity" bundle:nil];
//    UIViewController* vc = [storyBoard instantiateViewControllerWithIdentifier:@"PXIdentityMemosVC"];
//    if (![presentingVC isKindOfClass:[vc class]]) {
//        [presentingVC presentViewController:vc animated:YES completion:nil];
//    }
    // Need to ensure this is a proper navigation within the Tabbar structure, not a modal popup
    // github: https://github.com/PortablePixels/DrinkLess/issues/180
    PXTabBarController *tabVC = (id)[(AppDelegate*)[[UIApplication sharedApplication] delegate] topMostViewController];
    if (![tabVC isKindOfClass:[PXTabBarController class]]) {
        NSLog(@"WARNING: Expected PXTabBarController at root but %@ found", NSStringFromClass(PXTabBarController.class));
        return;
    }
    [tabVC selectTabAtIndex:4 storyboardName:@"PXIdentity" pushViewControllersWithIdentifiers:@[@"PXIdentityMemosVC"]];
}

#pragma mark - Local Notifications

+ (void)logScheduledNotifications {
    NSLog(@"all current notifications:");
    NSArray* notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *notification in notifications) {
        NSLog(@"date:%@, repeat:%lu, message:%@ type:%@ ID:%@", notification.fireDate, (unsigned long)notification.repeatInterval, notification.alertBody, notification.userInfo[KEY_LOCALNOTIFICATION_TYPE], notification.userInfo[KEY_LOCALNOTIFICATION_ID]);
    }
}

- (void)addLocalNotificationForDate:(NSDate*)date message:(NSString*)message type:(NSString*)type ID:(NSString*)ID {
    [self addLocalNotificationForDate:date message:message type:type ID:ID repeat:0];
}

- (void)addLocalNotificationForDate:(NSDate*)date message:(NSString*)message type:(NSString*)type ID:(NSString*)ID repeat:(NSCalendarUnit)repeatInterval {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = date;
    localNotification.alertBody = message;
    //Alert title is available from iOS 8.2
    if ([localNotification respondsToSelector:@selector(alertTitle)]) {
         localNotification.alertTitle = @"Reminder";
    }
    localNotification.soundName = @"attention.caf";
    localNotification.applicationIconBadgeNumber = 1;
    localNotification.userInfo = @{KEY_LOCALNOTIFICATION_ID : ID, KEY_LOCALNOTIFICATION_TYPE: type};
    localNotification.repeatInterval =repeatInterval;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    [PXLocalNotificationsManager performSelector:@selector(logScheduledNotifications) withObject:nil afterDelay:0];
}

- (void)removeLocalNotificationWithType:(NSString*)type ID:(NSString*)ID {
    NSArray *allLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];

    for (UILocalNotification *localNotification in allLocalNotifications) {
        NSDictionary *userInfo = localNotification.userInfo;

        if ([userInfo[KEY_LOCALNOTIFICATION_ID] isEqualToString:ID] && [userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:type]) {
            [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            break;
        }
    }
    [PXLocalNotificationsManager performSelector:@selector(logScheduledNotifications) withObject:nil afterDelay:0];
}

- (NSArray*)allLocalNotificationsWithType:(NSString*)type {
    NSArray *allLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];

    NSMutableArray *matchingType = [NSMutableArray array];

    for (UILocalNotification *localNotification in allLocalNotifications) {
        if ([localNotification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:type]) {
            [matchingType addObject:localNotification];
        }
    }
    return [matchingType copy];
}

@end
