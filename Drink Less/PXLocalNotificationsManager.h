//
//  PXLocalNotificationsManager.h
//  chemo-diary
//
//  Created by Brio on 27/03/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

extern NSString* const KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_ACTIVE;
extern NSString* const KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME;

extern NSString* const KEY_LOCALNOTIFICATION_ID;
extern NSString* const KEY_LOCALNOTIFICATION_TYPE;

extern NSString* const PXGoingOutReminderType;
extern NSString* const PXConsumptionReminderType;
extern NSString* const PXMemoWatchReminderType;
extern NSString* const PXMemoRecordReminderType;
//extern NSString* const PXSurveyReminderType;

@interface PXLocalNotificationsManager : NSObject

@property (nonatomic) BOOL consumptionReminderShowing;

+ (instancetype)sharedInstance;

- (void)updateConsumptionReminder;

-(void)showNotification:(UILocalNotification *)notification;

- (void)presentMoodDiaryAfterDrinksTrackerIfNeeded;
- (void)presentMoodDiaryIfNotCurrentlyShowing;

/**
 * schedules a local notification
 * @param date (first) firedate of the notification
 * @param message message to be displayed in notification center
 * @param type type of notification (stored in userinfo)
 * @param ID (numeric) ID of notification (stored in userinfo)
 * @param repeat repeat interval of notification (0 for no repeat)
 */
- (void)addLocalNotificationForDate:(NSDate*)date message:(NSString*)message type:(NSString*)type ID:(NSString*)ID repeat:(NSCalendarUnit)repeatInterval;

/**
 * convenience method with no repeats
 */
- (void)addLocalNotificationForDate:(NSDate*)date message:(NSString*)message type:(NSString*)type ID:(NSString*)ID;

/** removes a local notification if the following parameters match:
 * @param type type must match the type stored in userinfo
 * @param ID ID must match the ID stored in userinfo
 */
- (void)removeLocalNotificationWithType:(NSString*)type ID:(NSString*)ID;

/** all scheduled local notifications for a given type
 * @param type type stored in the userinfo that needs to match
 * @return array of matching local notifications
 */
- (NSArray*)allLocalNotificationsWithType:(NSString*)type;


/** Does not include the newly added Survey notification which needs to be enabled manually */
- (void)enableAllNotificationsIfFirstRun;

///** Schedules a one off. To be used on suspend... */
//- (void)scheduleSurveyNotification;
//
///** Used to show an in-app alert if the user comes back after having ignored the notif */
//- (void)showSurveyPromptAlertViewWithCallback:(void(^)(void))didAgreeToSurvey;

@end
