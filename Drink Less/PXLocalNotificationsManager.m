//
//  PXLocalNotificationsManager.m
//  chemo-diary
//
//  Created by Brio on 27/03/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

@import UserNotifications;
#import "PXLocalNotificationsManager.h"
#import "NSDate+DrinkLess.h"
#import "AppDelegate.h"
#import "PXMoodDiaryViewController.h"
#import "NSDate+DrinkLess.h"
#import "PXGroupsManager.h"
#import "PXTabBarController.h"
#import "UIViewController+RecordMemo.h"
#import "drinkless-Swift.h"

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
NSString* const PXMyPlanReminderType = @"PXMyPlanReminderType";
//NSString* const PXSurveyReminderType = @"PXSurveyReminderType";

NSString* const PXConsumptionReminderShowing = @"PXConsumptionReminderShowing";

@interface PXLocalNotificationsManager ()

@property (nonatomic, strong) NSDictionary *reminderTypes;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

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
    // Still used??
    if (![self.userDefaults objectForKey:PXGoingOutReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXGoingOutReminderType];
    }
    
    if (![self.userDefaults objectForKey:PXConsumptionReminderType]) {
        [self.userDefaults setObject:@YES forKey:PXConsumptionReminderType];

        [self.userDefaults setValue:[self defaultConsumptionDate] forKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
        [self.userDefaults synchronize];
    }
//    if (![self.userDefaults objectForKey:PXMemoWatchReminderType]) {
//        [self.userDefaults setObject:@YES forKey:PXMemoWatchReminderType];
//    }
//    if (![self.userDefaults objectForKey:PXMemoRecordReminderType]) {
//        [self.userDefaults setObject:@YES forKey:PXMemoRecordReminderType];
//    }
    [self.userDefaults synchronize];
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
    NSLog(@"Updating notification for Reminder. Removing existing notif.");

    // @TODO Fix this mess once we figure it out
    
    __block NSInteger countBeforeNew, countBeforeOld, countRemove1, countRemove2, countRemove3, countAfterRescheduleNew, countAfterRescheduleOld;
    __block BOOL dbg_conRemOn, dbg_mrtOn;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [UNUserNotificationCenter.currentNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
            
            NSLog(@"******* USERNOTIF: REQ count (before clear out existing): %li *******", requests.count);
            for (UNNotificationRequest *r in requests)
                NSLog(@"%@", r);
            countBeforeNew = requests.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                // @TODO Clean up the redundancies...
                [self removeLocalNotificationWithType:PXConsumptionReminderType ID:@"0"];
                
                 // Attempt to fix bug with old style linked against UN framework
                 // "0" was the old ID but it's a different context in UNNotifs as UILocalNotifs didnt have an ID and one was being implemented in userInfo. We're using PXConsumptionReminderType as the (UNNotif) ID now too since @"0" might have been causing problems...??
                [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:@[@"0", PXConsumptionReminderType]];
                
                // DETAILED REMOVEAL: Let's ensure we erase the old ones as something is wacky here
                __block NSMutableArray<NSString *> *idsToRemove = @[].mutableCopy;
                for (UNNotificationRequest *req in requests) {
                    if ([req.content.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXConsumptionReminderType]) {
                        [idsToRemove addObject:req.identifier];
                    }
                }
                if (idsToRemove.count) {
                    [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:idsToRemove];
                }
                
                
                
                [UNUserNotificationCenter.currentNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                    NSLog(@"******* USERNOTIF: REQ count (after clear, before re-schedule): %li *******", requests.count);
                    countRemove3 = requests.count;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if ([[self.userDefaults objectForKey:PXConsumptionReminderType] boolValue] == YES) {
                            NSDate *fireDate = [self.userDefaults objectForKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
                            if (fireDate) {
                                //            NSDate *givenDate = [self.userDefaults objectForKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
                                //            NSDate *firstFireDate = [givenDate nextOccurrenceOfTimeInDate];
                                ////            firstFireDate = [NSCalendar.currentCalendar dateFromComponents:dc];
                                //
                                // Extract the components
                                NSDateComponents *dc = [NSCalendar.currentCalendar components:NSCalendarUnitMinute|NSCalendarUnitHour fromDate:fireDate];
                                NSLog(@"Re-scheduling daily Reminder notif to begin at %@", dc);
                                
                                UNNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dc repeats:YES];
                                UNMutableNotificationContent *content = UNMutableNotificationContent.new;
                                content.title = @"";
                                content.body = @"Please complete your mood and drinks diary";
                                content.userInfo = @{KEY_LOCALNOTIFICATION_TYPE: PXConsumptionReminderType}; // for backwards compat
                                content.badge = @1;
                                UNNotificationRequest *notifReq = [UNNotificationRequest requestWithIdentifier:PXConsumptionReminderType content:content trigger:trigger];
                                [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:notifReq withCompletionHandler:^(NSError * _Nullable error) {
                                    // @TODO
                                }];
                            }
                        }
                    
                    
                        [UNUserNotificationCenter.currentNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                            NSLog(@"******* USERNOTIF: REQ count (after re-schedule): %li *******", requests.count);
                            countAfterRescheduleNew = requests.count;
                            
                            __block NSMutableArray *notifData = NSMutableArray.array;
                            for (UNNotificationRequest *req in requests) {
                                [notifData addObject:@{@"id":req.identifier, @"userInfo": req.content.userInfo}];
                            }
                            
                            
                        }];
                    }); // dispatch_async
                }];
                
            });  // dispatch_async
            
        }];
    }); // dispatch_async
}


// Handle notifications (e.g. show an alert in the app)
- (void)showNotification:(UNNotification *)notification {
    
    NSDictionary *userInfo = notification.request.content.userInfo;
    
    if ([userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXConsumptionReminderType]) {
        
        
        
        
        NSDictionary *consumptionReminder = self.reminderTypes[PXConsumptionReminderType];
        NSArray *possibleAnswers = consumptionReminder[KEY_REMINDER_ANSWERS];
        
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:consumptionReminder[KEY_REMINDER_QUESTION]
                                    message:nil
                                    preferredStyle:UIAlertControllerStyleAlert];
    
        
        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
            UIAlertActionStyle style = idx == 0 ? UIAlertActionStyleDefault : UIAlertActionStyleCancel;
            [alert addAction: [UIAlertAction actionWithTitle:answer style:style handler:^(UIAlertAction * _Nonnull action) {
                if (action.style != UIAlertActionStyleCancel) {
                    [self presentMoodDiaryIfNotCurrentlyShowing];
                }
            }]];
        }];
        
        [alert show];
        
    } else if ([userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXMyPlanReminderType]) {
        [[UIAlertController simpleAlertWithTitle:notification.request.content.title
                                             msg:notification.request.content.body
                                       buttonTxt:@"Ok"] show];
        
    }
//   } else if ([userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXGoingOutReminderType]) {
//        NSDictionary *consumptionReminder = self.reminderTypes[PXGoingOutReminderType];
//        self.goingOutAlert =  [[UIAlertView alloc] init];
//        self.goingOutAlert.title = consumptionReminder[KEY_REMINDER_QUESTION];
//        self.goingOutAlert.delegate = self;
//        NSArray *possibleAnswers = consumptionReminder[KEY_REMINDER_ANSWERS];
//        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
//            [self.goingOutAlert addButtonWithTitle:answer];
//        }];
//        [self.goingOutAlert show];
//    }
//    else if ([userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXMemoRecordReminderType]) {
//        NSDictionary *memoReminder = self.reminderTypes[PXMemoRecordReminderType];
//        self.memoRecordAlert =  [[UIAlertView alloc] init];
//        self.memoRecordAlert.title = memoReminder[KEY_REMINDER_QUESTION];
//        self.memoRecordAlert.delegate = self;
//        NSArray *possibleAnswers = memoReminder[KEY_REMINDER_ANSWERS];
//        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
//            [self.memoRecordAlert addButtonWithTitle:answer];
//        }];
//        [self.memoRecordAlert show];
//    }
//    else if ([userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXMemoWatchReminderType]) {
//        NSDictionary *memoReminder = self.reminderTypes[PXMemoWatchReminderType];
//        self.memoAlert =  [[UIAlertView alloc] init];
//        self.memoAlert.title = memoReminder[KEY_REMINDER_QUESTION];
//        self.memoAlert.delegate = self;
//        NSArray *possibleAnswers = memoReminder[KEY_REMINDER_ANSWERS];
//        [possibleAnswers enumerateObjectsUsingBlock:^(NSString *answer, NSUInteger idx, BOOL *stop) {
//            [self.memoAlert addButtonWithTitle:answer];
//        }];
//        [self.memoAlert show];
}

//---------------------------------------------------------------------

//#pragma mark - uialertview delegate

//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (alertView == self.consumptionAlert) {
//        switch (buttonIndex) {
//            case 0:
//                [self presentMoodDiaryIfNotCurrentlyShowing];
//                break;
//            default:
//                break;
//        }
//    } else if (alertView == self.goingOutAlert) {
//        switch (buttonIndex) {
//            case 0:
//                [[NSNotificationCenter defaultCenter] postNotificationName:PXShowDrinksPanelNotification object:nil];
//                break;
//            default:
//                break;
//        }
//    } else if (alertView == self.memoRecordAlert ) {
//        switch (buttonIndex) {
//            case 0:
//                [self presentRecordMemo];
//                break;
//            default:
//                break;
//        }
//    } else if (alertView == self.memoAlert) {
//        switch (buttonIndex) {
//            case 0:
//                [self presentWatchMemoIfNotCurrentlyShowing];
//                break;
//            default:
//                break;
//        }
//    } else if (alertView == self.surveyAlert) {
//        switch (buttonIndex) {
//            case 0:
//                _surveyAlertCallback();
//                break;
//
//            default:
//                break;
//        }
//        _surveyAlertCallback = nil;
//    } else if (alertView == self.planAlert) {
//
//    }
//}

#pragma mark - navigation

- (void)presentMoodDiaryIfNotCurrentlyShowing {
    UIViewController *presentingVC = [((AppDelegate *)[UIApplication sharedApplication].delegate) topMostViewController];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Activities" bundle:nil];
    UINavigationController *navigationController = [storyBoard instantiateViewControllerWithIdentifier:@"PXMoodDiaryNC"];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
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

// @deprecated
- (void)removeLocalNotificationWithType:(NSString*)type ID:(NSString*)ID {
    
    NSArray *allLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];

    for (UILocalNotification *localNotification in allLocalNotifications) {
        NSDictionary *userInfo = localNotification.userInfo;

        if ([userInfo[KEY_LOCALNOTIFICATION_ID] isEqualToString:ID] && [userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:type]) {
            // I dont think this is working in the context of the UNNotif's we're using
            [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            break;
        }
    }
}


@end
