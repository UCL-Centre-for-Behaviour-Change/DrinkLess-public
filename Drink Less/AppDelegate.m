//
//  AppDelegate.m
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>
#import "PXAppearance.h"
#import "PXIntroNavigationController.h"
#import "iRate.h"
#import "PXLocalNotificationsManager.h"
#import "TSMessage.h"
#import "PXAwesomeFloatingGroupDebug.h"
#import "PXActionPlan.h"
#import "PXCoreDataManager.h"
#import "PXGroupsManager.h"
#import "PXIntroManager.h"
#import "PXDebug.h"
#import <Google/Analytics.h>
#import "PXDeviceUID.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "NSDate+DrinkLess.h"

#import "PXDrinkRecord.h"
#import "PXDrinkRecord+Extras.h"
#import "PXAlcoholFreeRecord.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXGoal.h"
#import "PXGoal+Extras.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "DLFloatingDebugVC.h"
#import "PXDebug.h"

/////////////////////////////////////////////////////////////////////////
// MARK: - Types & Consts
/////////////////////////////////////////////////////////////////////////

static NSString * const PXUserEligibleForQuestionnaireKey = @"eligible-for-survey";


/////////////////////////////////////////////////////////////////////////
// MARK: -
/////////////////////////////////////////////////////////////////////////


@interface AppDelegate () <PXAwesomeFloatingGroupDebugDelegate>

@property (strong, nonatomic) PXAwesomeFloatingGroupDebug *awesomeGroupDebugView;
@property (strong, nonatomic) DLFloatingDebugVC *floatingDebugVC;
@property (strong, nonatomic) PXIntroManager *introManager;

@end

@implementation AppDelegate {
    BOOL _didResumeFromQuestionnaireNotification;
    BOOL _didResumeHavingQuestionnaireElgibility;
    BOOL _scheduleQuestionnaireAlertOnSuspend;
}

+ (void)initialize {
    [iRate sharedInstance].daysUntilPrompt = 7;
    [iRate sharedInstance].usesUntilPrompt = 11;
}

-(void)connectToNodeChef {

    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        // OPEN SOURCE PARSE SERVER
        configuration.applicationId = @"6c2b7d8713595aa45e7f5b98251a6f4a";
        configuration.server = @"https://drinkless-opensource-1394.nodechef.com/parse";


    }]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Allow BG music to continue to play when we make sounds
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];

    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
 //   gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app release

    [[PXLocalNotificationsManager sharedInstance] enableAllNotificationsIfFirstRun];

    NSLog(@"library:%@", [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject]);

    NSLog(@"documents:%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);

    [self connectToNodeChef];

    [PFUser enableAutomaticUser];
     [PFUser enableRevocableSessionInBackground];


    PXGroupsManager *groupsManager = [PXGroupsManager sharedManager];
#if SET_GROUP_ID_ON_LAUNCH
    groupsManager.groupID = @(SET_GROUP_ID_ON_LAUNCH);
#endif
    NSLog(@"[APP_DELEGATE] GROUP ID: %@", groupsManager.groupID);

    [[PXCoreDataManager sharedManager] loadDatabase];


    self.window.tintColor = [UIColor drinkLessGreenColor];
    [PXAppearance configureAppearance];
    [self.window makeKeyAndVisible];


    [TSMessage addCustomDesignFromFileWithName:@"PXMessageDesign.json"];

    self.introManager = [PXIntroManager sharedManager];
    if (self.introManager.stage != PXIntroStageFinished) {
        [self showIntroductionFromStage:self.introManager.stage];
    }

#if DEBUG
    // HK: This is kinda obsolete now as all the high-low stuff has been removed I think
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showGroupsPicker)];
    [swipeGesture setNumberOfTouchesRequired:2];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.window addGestureRecognizer:swipeGesture];

    // HK: New general debug bar, moving forward...
#if ENABLE_TIME_DEBUG_PANEL

    self.floatingDebugVC = [[DLFloatingDebugVC alloc] init];
    [self.window addSubview:self.floatingDebugVC.view];

//    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFloatingDebug)];
//    tapGR.numberOfTapsRequired = 2;
//    tapGR.numberOfTouchesRequired = 2;
//    [self.window addGestureRecognizer:tapGR];
#endif

#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedIntro) name:@"PXFinishIntro" object:nil];

    // Assign default settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{@"enable-sounds": @YES}];

    //Saving first run date to determine if 30 day questionaiire should be displayed
    if (![defaults objectForKey:@"firstRun"])
        [defaults setObject:[NSDate date] forKey:@"firstRun"];
#if SET_FIRST_RUN_DATE_TO_DAYS_BEFORE_NOW
    NSDate *d = [[NSDate date] dateByAddingTimeInterval:-(SET_FIRST_RUN_DATE_TO_DAYS_BEFORE_NOW * 24 * 3600)];
    [defaults setObject:d forKey:@"firstRun"];

#endif
    [[NSUserDefaults standardUserDefaults] synchronize];

    [Fabric with:@[[Crashlytics class]]];

#if POPULATE_WITH_DATA
    //[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(_popuplateWithData) userInfo:nil repeats:NO];
    [self _popuplateWithData];
#endif

    return YES;
}

- (void)showIntroductionFromStage:(PXIntroStage)introStage {
    // TEMP
#ifdef FORCE_INTRO_STAGE
    introStage = FORCE_INTRO_STAGE;
#endif


    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PXIntroNavigationController* introNav = (PXIntroNavigationController*)[storyboard instantiateInitialViewController];
    [self.window.rootViewController presentViewController:introNav animated:NO completion:^{
    }];

    /*if (introStage == PXIntroStageConsent) {
        UIStoryboard *consentStoryboard = [UIStoryboard storyboardWithName:@"Consent" bundle:nil];
        UINavigationController *navController = [consentStoryboard instantiateInitialViewController];
        [introNav.topViewController presentViewController:navController animated:NO completion:NULL];
    } else*/ if (introStage == PXIntroStagePrivacyPolicy) {
        // ? and what about AboutYou?
    } else {
        for (NSInteger i = PXIntroStageAuditQuestions; i <= introStage; i++) {
            NSString* vcID = [NSString stringWithFormat:@"PXIntroVC%li", (long)i];
            UIViewController* viewController = [storyboard instantiateViewControllerWithIdentifier:vcID];
            [introNav pushViewController:viewController animated:NO];
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXUpdateProgressBar" object:@(introStage)];
}

- (void)finishedIntro {
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
    } else {
        [[PXLocalNotificationsManager sharedInstance] updateConsumptionReminder];
    }
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];

    // SURVEY
    // For new users only, determine whether they qualify for the survey and schedule it to show in background
    if (self.introManager.qualifiesForQuestionnaire) {
        NSLog(@"******* QUESTIONNAIRE: User eligible, will schedule on suspend *******");
        _scheduleQuestionnaireAlertOnSuspend = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PXUserEligibleForQuestionnaireKey];  // set a flag so we can do an alert if they come back later having ignored the localnotif
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSLog(@"******* QUESTIONNAIRE: User not eligible *******");
    }
}

//- (void)saveDeviceId {
//
//    PFObject *user = [PFUser currentUser];
//    [user setObject:[PXDeviceUID uid] forKey:@"DeviceId"];
//    NSLog(@"[PARSE]: Saving deviceID %@ to user: %@", [PXDeviceUID uid], user);
//    [user saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            NSLog(@"Saved DeviceID to Parse");
//        }
//        else {
//            NSLog(@"Error saving DeviceID: %@", error);
//
//            if (error.code == 206) { // session is invalid
//                NSLog(@"[PARSE]: Trying again...");
//
//                [PFUser becomeInBackground:[PFUser currentUser].sessionToken block:^(PFUser *user, NSError *error) {
//                    PFObject *updatedUser = [PFUser currentUser];
//                    [updatedUser saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
//                        if (succeeded) {
//                            NSLog(@"[PARSE] Saved Follow Up Answers to Parse");
//                        } else {
//                            NSLog(@"[PARSE]: Error saving deviceID: %@", error);
//                        }
//                    }];
//                }];
//            }
//        }
//    }];
//}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [PFPush storeDeviceToken:deviceToken];
    [[PFInstallation currentInstallation] saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"ERROR didFailtToRegister: %@", error);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        [[PXLocalNotificationsManager sharedInstance] updateConsumptionReminder];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"******* APPLICATION: didReceiveLocalNotification  *******");

    if ([notification.userInfo[KEY_LOCALNOTIFICATION_TYPE] isEqualToString:PXSurveyReminderType]) {
        _didResumeFromQuestionnaireNotification = YES;
    } else {
        [[PXLocalNotificationsManager sharedInstance] showNotification:notification];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"******* APPLICATION: DidEnterBackground  *******");

    if (_scheduleQuestionnaireAlertOnSuspend) {
        NSLog(@"******* SURVEY: Scheduling survey notification *******");
        [[PXLocalNotificationsManager sharedInstance] scheduleSurveyNotification];
        _scheduleQuestionnaireAlertOnSuspend = NO;
    }

    if (!self.introManager.isParseUpdated) {
        [self.introManager save];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

    NSLog(@"******* APPLICATION: WillEnterForeground  *******");

    // QUESTIONAIRRE SURVEY
    if ([NSUserDefaults.standardUserDefaults boolForKey:PXUserEligibleForQuestionnaireKey]) {
        NSLog(@"******* SURVEY: App resumed with survey eligibility flag set (might be from a notif too). *******");
        _didResumeHavingQuestionnaireElgibility = YES;
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:PXUserEligibleForQuestionnaireKey];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    application.applicationIconBadgeNumber = 0;

    // Careful here as this is triggered after a uialertview closes
    if (_didResumeFromQuestionnaireNotification) {
        NSLog(@"******* SURVEY: Opening survey URL *******");
        [self _openSurveyURL];
        _scheduleQuestionnaireAlertOnSuspend = NO;
        _didResumeHavingQuestionnaireElgibility = NO;
        _didResumeFromQuestionnaireNotification = NO;
    } else if (_didResumeHavingQuestionnaireElgibility) {
//        NSLog(@"******* SURVEY: Showing survey alert prompt *******");
//        // Show in-app alert as they've ignored the localnotif
//        [PXLocalNotificationsManager.sharedInstance showSurveyPromptAlertViewWithCallback:^{
//            [self _openSurveyURL];
//        }];
//        _scheduleQuestionnaireAlertOnSuspend = NO;
//        _didResumeHavingQuestionnaireElgibility = NO;
//        _didResumeFromQuestionnaireNotification = NO;
    }
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)showGroupsPicker {
    //Remove before submissions
    if (self.awesomeGroupDebugView) {
        [self.awesomeGroupDebugView removeFromSuperview];
        self.awesomeGroupDebugView = nil;
    } else {
        self.awesomeGroupDebugView = [[PXAwesomeFloatingGroupDebug alloc] init];
        self.awesomeGroupDebugView.delegate = self;
        self.awesomeGroupDebugView.frame = CGRectMake(20, 20, 160, 300);
        self.awesomeGroupDebugView.backgroundColor =[UIColor redColor];
        [self.window addSubview:self.awesomeGroupDebugView];
    }
}
- (void)toggleFloatingDebug {
    //Remove before submissions
    if (self.floatingDebugVC) {
        [self.floatingDebugVC.view removeFromSuperview];
        self.floatingDebugVC = nil;
    } else {
        self.floatingDebugVC = [[DLFloatingDebugVC alloc] init];
        [self.window addSubview:self.floatingDebugVC.view];
    }
}

- (UIViewController*)topMostViewController
{
    UIViewController *topController = self.window.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (void)floatingToolbar:(PXAwesomeFloatingGroupDebug *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);

    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));

    if (CGRectContainsRect(self.window.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_openSurveyURL
{
    NSString *urlStr = [NSString stringWithFormat:@"https://uclpsych.eu.qualtrics.com/jfe/form/SV_4PzFlmlT8ViAbgp?devid=%@", [PXDeviceUID uid]];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:urlStr]];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - DEBUG
/////////////////////////////////////////////////////////////////////////

- (void)_popuplateWithData
{//return;
    NSLog(@"DEBUG: ******* POPULATING WITH TEST DATA *******");
    static const NSUInteger DAYS_BACK = 90;  // 3 months/12 weeks
    static const NSUInteger QUANTITY_MAX = 3; // 0-3 per day
    static const BOOL ERASE = NO;
    NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;

    if (ERASE) {

        NSLog(@"DEBUG: ******* ERASING EXISTING DRINK DATA *******");
        NSFetchRequest *allGoals = [[NSFetchRequest alloc] init];
        [allGoals setEntity:[NSEntityDescription entityForName:@"PXGoal" inManagedObjectContext:context]];
        [allGoals setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        NSArray *goals = [context executeFetchRequest:allGoals error:nil];
        NSLog(@"******* Erasing %lu goals *******", goals.count);
        for (NSManagedObject *goal in goals) {
            [context deleteObject:goal];
        }
        NSFetchRequest *allDRs = [[NSFetchRequest alloc] init];
        [allDRs setEntity:[NSEntityDescription entityForName:@"PXDrinkRecord" inManagedObjectContext:context]];
        [allDRs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        NSArray *drs = [context executeFetchRequest:allDRs error:nil];
        NSLog(@"******* Erasing %lu drink records *******", drs.count);
        for (NSManagedObject *dr in drs) {
            [context deleteObject:dr];
        }
        [context save:nil];
        NSFetchRequest *allAFRs = [[NSFetchRequest alloc] init];
        [allAFRs setEntity:[NSEntityDescription entityForName:@"PXAlcoholFreeRecord" inManagedObjectContext:context]];
        [allAFRs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        NSArray *afrs = [context executeFetchRequest:allAFRs error:nil];
        NSLog(@"******* Erasing %lu alcohol free records *******", afrs.count);
        for (NSManagedObject *rec in afrs) {
            [context deleteObject:rec];
        }
        [context save:nil];
    }


    // Need to do this to get the drink record template entried back in. A bit lame that user data and template data is mixed in unless I'm missing something
    [[PXCoreDataManager sharedManager] loadDatabase];


    /////////////////////////////////////////
    // DRINK RECORDS
    /////////////////////////////////////////

    // Get the drink templates...
    // See PXTrackerDrinksVC::fetchedResultsController and segue hook methods
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == nil && groupName == 'standardTemplate'"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"drink.index" ascending:YES]];

    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [fetchedResultsController performFetch:nil];


    /////////////////////////////////////////
    // SPECIFIC ADDER
    /////////////////////////////////////////
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    PXDrinkRecord *referenceRecord = [fetchedResultsController objectAtIndexPath:indexPath];

    NSTimeZone *caliTZ = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
    NSTimeZone *japanTZ = [NSTimeZone timeZoneWithName:@"Japan"];
    NSCalendar *caliCal = NSCalendar.currentCalendar.copy;
    NSCalendar *japanCal = NSCalendar.currentCalendar.copy;
    caliCal.timeZone = caliTZ;
    japanCal.timeZone = japanTZ;

    {
        NSDateComponents *dateComps = [NSDateComponents new];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:context];
        newRecord.abv = @3;  // taken from defaults

        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 9;
        dateComps.hour = 0; dateComps.minute = 1;
        dateComps.timeZone = caliTZ;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging DRINK at %@", recDate);
        newRecord.date = recDate;
        newRecord.timezone = dateComps.timeZone.name;
        newRecord.price = @1;
        newRecord.quantity = @1;
        newRecord.servingID = @2; // id of plist entry

        [context refreshObject:newRecord mergeChanges:YES];
        [context save:nil];
    }
    {
        NSDateComponents *dateComps = [NSDateComponents new];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:context];
        newRecord.abv = @3;  // taken from defaults

        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 10;
        dateComps.hour = 0; dateComps.minute = 1;
        dateComps.timeZone = japanTZ;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging DRINK at %@", recDate);
        newRecord.date = recDate;
        newRecord.timezone = dateComps.timeZone.name;
        newRecord.price = @2;
        newRecord.quantity = @2;
        newRecord.servingID = @2; // id of plist entry

        [context refreshObject:newRecord mergeChanges:YES];
        [context save:nil];
    }
    {
        NSDateComponents *dateComps = [NSDateComponents new];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:context];
        newRecord.abv = @3;  // taken from defaults

        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 11;
        dateComps.hour = 23; dateComps.minute = 50;
        dateComps.timeZone = caliTZ;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging DRINK at %@", recDate);
        newRecord.date = recDate;
        newRecord.timezone = dateComps.timeZone.name;
        newRecord.price = @3;
        newRecord.quantity = @3;
        newRecord.servingID = @2; // id of plist entry

        [context refreshObject:newRecord mergeChanges:YES];
        [context save:nil];
    }
    {
        NSDateComponents *dateComps = [NSDateComponents new];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:context];
        newRecord.abv = @3;  // taken from defaults

        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 12;
        dateComps.hour = 23; dateComps.minute = 50;
        dateComps.timeZone = japanTZ;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging DRINK at %@", recDate);
        newRecord.date = recDate;
        newRecord.timezone = dateComps.timeZone.name;
        newRecord.price = @4;
        newRecord.quantity = @4;
        newRecord.servingID = @2; // id of plist entry

        [context refreshObject:newRecord mergeChanges:YES];
        [context save:nil];
    }

    {
        NSDateComponents *dateComps = [NSDateComponents new];
        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 13;
        dateComps.hour = 00; dateComps.minute = 50;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging FREE at %@", recDate);
        [PXAlcoholFreeRecord setFreeDay:YES date:recDate context:context];
    }
    {
        NSDateComponents *dateComps = [NSDateComponents new];
        dateComps.year = 2018; dateComps.month = 4; dateComps.day = 14;
        dateComps.hour = 23; dateComps.minute = 50;
        NSDate *recDate = [NSCalendar.currentCalendar dateFromComponents:dateComps];
        logd(@"Logging FREE at %@", recDate);
        [PXAlcoholFreeRecord setFreeDay:YES date:recDate context:context];
    }

//    NSDate *d = [[NSDate date] dateByAddingTimeInterval:-3600.0*24.0*(NSTimeInterval)i];

    /////////////////////////////////////////
    // RANDOM ADDER
    /////////////////////////////////////////

    // Add one per day
    for (NSUInteger i=0; i<DAYS_BACK; i++) {
        // Just beer for now
        int quantity = round(arc4random() % (QUANTITY_MAX+1));
        NSDate *d = [[NSDate date] dateByAddingTimeInterval:-3600.0*24.0*(NSTimeInterval)i];
        if (quantity == 0) {
            [PXAlcoholFreeRecord setFreeDay:YES date:d context:context];
            continue;
        };

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        PXDrinkRecord *referenceRecord = [fetchedResultsController objectAtIndexPath:indexPath];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:context];

        newRecord.date = d;
        newRecord.abv = @5.5;  // taken from defaults
        newRecord.price = @5.57;
        newRecord.quantity = @(quantity);
        newRecord.servingID = @2; // id of plist entry
        [context refreshObject:newRecord mergeChanges:YES];
        [context save:nil];
        NSLog(@"DEBUG: ******* Added drink record %i of %i. Quantity=%i, Date=%@  *******", (int)(i+1), (int)DAYS_BACK, (int)newRecord.quantity.integerValue, newRecord.date);

    }

    /////////////////////////////////////////
    // GOALS
    /////////////////////////////////////////

    // Create a few goals at the beginning of that time period
    for (NSNumber *typeNum in @[@(PXGoalTypeUnits), @(PXGoalTypeFreeDays), @(PXGoalTypeCalories), @(PXGoalTypeSpending)]) {

        PXGoal *goal = (PXGoal *)[PXGoal createInContext:context];
        goal.goalType = typeNum;

        int weeksBack = round(arc4random() % (3+1) + 2);
        NSDate *d = [[NSDate date] dateByAddingTimeInterval:-24.0*3600.0*(NSTimeInterval)weeksBack];
        goal.startDate = [d startOfWeek];
        goal.recurring = @YES; // ?

        // GOAL VALUES:
        // Choose the target based on the type. These are weekly values
        switch (typeNum.integerValue) {
            case PXGoalTypeUnits: goal.targetMax = @23; break;
            case PXGoalTypeFreeDays: goal.targetMax = @3; break;
            case PXGoalTypeCalories: goal.targetMax = @2100; break;
            default:
            case PXGoalTypeSpending: goal.targetMax = @40;  break;
        }
        [context save:nil];
        NSLog(@"DEBUG: ******* Goal saved: %@ *******", goal);
    }


    /////////////////////////////////////////
    // MOOD DIARY DATA
    /////////////////////////////////////////

    // Delete existing...
    NSLog(@"DEBUG: ******* ERASING EXISTING MOOD DATA *******");
    [PXUserMoodDiaries deleteAllData];

    // One per day going back
    // See PXMoodDiaryViewController
    PXUserMoodDiaries *userMoodDiaries = [PXUserMoodDiaries loadMoodDiaries];
    for (NSUInteger i=1; i<=DAYS_BACK; i++) { // skip today so we can still prog enter it
        NSDate *d = [[NSDate date] dateByAddingTimeInterval:-3600.0*24.0*(NSTimeInterval)i];
        PXMoodDiary *entry = [[PXMoodDiary alloc] init];
        entry.date = d;
        entry.happiness = @(arc4random() % 11);
        entry.productivity = @(arc4random() % 11);
        entry.sleep = @(arc4random() % 11);
        entry.clearHeaded = @(arc4random() % 11);
        entry.reason = @"A good reason";
        entry.comment = @"A good comment";
        entry.goalAchieved = (BOOL)(arc4random()%2);
        // goal reflections??
        [userMoodDiaries.moodDiaries addObject:entry];
        NSLog(@"******* SAVED MOOD: %@ *******", entry);
        [userMoodDiaries save];
    }
}


@end
