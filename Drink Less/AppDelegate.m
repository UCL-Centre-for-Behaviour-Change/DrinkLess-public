//
//  AppDelegate.m
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "PXAppearance.h"
#import "PXIntroNavigationController.h"
#import "PXLocalNotificationsManager.h"
#import "TSMessage.h"
#import "PXAwesomeFloatingGroupDebug.h"
#import "PXActionPlan.h"
#import "PXCoreDataManager.h"
#import "PXGroupsManager.h"
#import "PXIntroManager.h"
#import "PXDebug.h"
#import "PXDeviceUID.h"
#import "NSDate+DrinkLess.h"
#import "NSTimeZone+DrinkLess.h"
#import "NSDate+DrinkLess.h"
#import "PXEditGoalViewController.h"
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
#import "PXCoreDataManager+Debug.h"
#import "drinkless-Swift.h"

/////////////////////////////////////////////////////////////////////////
// MARK: - Types & Consts
/////////////////////////////////////////////////////////////////////////

static NSString * const PXUserEligibleForQuestionnaireKey = @"eligible-for-survey";


/////////////////////////////////////////////////////////////////////////
// MARK: -
/////////////////////////////////////////////////////////////////////////


@interface AppDelegate () <PXAwesomeFloatingGroupDebugDelegate, UNUserNotificationCenterDelegate>

@property (strong, nonatomic) PXAwesomeFloatingGroupDebug *awesomeGroupDebugView;
@property (strong, nonatomic) DLFloatingDebugVC *floatingDebugVC;
@property (strong, nonatomic) PXIntroManager *introManager;
@property (nonatomic) BOOL didLaunchViaNotification;
@property (nonatomic) BOOL isLaunching;  // disentangle fresh run from resume

@end

@implementation AppDelegate {
//    BOOL _didResumeFromQuestionnaireNotification;
//    BOOL _didResumeHavingQuestionnaireElgibility;
//    BOOL _scheduleQuestionnaireAlertOnSuspend;
}

//---------------------------------------------------------------------

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSLog(@"******* APPLICATION: DidFinishLaunchingWithOptions *******");
    /////////////////////////////////////////
    // VERISON INFO
    /////////////////////////////////////////
    {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        NSInteger prevRunVersion = [defs integerForKey:@"currentRunVersion"];
        [defs setInteger:prevRunVersion forKey:@"previousRunVersion"];
        [defs setInteger:UIApplication.versionInt forKey:@"currentRunVersion"];
        [defs synchronize];
        // also see firstRun below
    }
    
    self.isLaunching = YES;
    
    
    /////////////////////////////////////////
    // DB & PARSE INIT
    /////////////////////////////////////////
    
    NSLog(@"AppConfig: User %@ opted out of data reporting", AppConfig.userHasOptedOut ? @"HAS" : @"HAS NOT");
    DataServer.shared.isEnabled = !AppConfig.userHasOptedOut;
    [DataServer.shared connect];
    
    // Must come after the above
    [[PXCoreDataManager sharedManager] loadDatabase];
    
    
    
    // ANALYTICS
    [Analytics.shared setup];
    
    
    /////////////////////////////////////////
    // MIGRATION
    // !! Be sure to run before firstRun flag is set in userdefs or else fresh installs will try to migrate
    // ...and AFTER coredata has been init'ed...and PARSE
    /////////////////////////////////////////
    
    NSArray<MigrationError *> *errors = [MigrationManager doMigrations]; // ALWAYS calls thiszx
    BOOL isFirstError = YES;
    for (MigrationError *e in errors) {
        if (isFirstError) {
            [[UIAlertController errorAlert:e.toNSError callback:^() {
                for (MigrationError *e2 in errors) {
                    if (e2.isFatal) {
                        [NSException raise:NSGenericException format:@"Fatal migration error. %@", e2.toNSError];
                        return;
                    }
                }
            }] show];
            isFirstError = NO;
        } else {
            [[UIAlertController errorAlert:e.toNSError] show];
        }
    }
    
    ///
    /// Rater
    ///
    [AppRater.shared markRun];
    
    /////////////////////////////////////////
    // AUDIO
    /////////////////////////////////////////
    
    // Allow BG music to continue to play when we make sounds
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];

    /////////////////////////////////////////
    // ANALYTICS
    /////////////////////////////////////////
    
    
    /////////////////////////////////////////
    // PUSH/LOCAL NOTIFS
    /////////////////////////////////////////

    [[PXLocalNotificationsManager sharedInstance] enableAllNotificationsIfFirstRun];
    
    /////////////////////////////////////////
    // APPEARANCE
    /////////////////////////////////////////
    
    self.window.tintColor = [UIColor drinkLessGreenColor];
    [PXAppearance configureAppearance];
    [self.window makeKeyAndVisible];

    [TSMessage addCustomDesignFromFileWithName:@"PXMessageDesign.json"];

    
    /////////////////////////////////////////
    // GLOBALS INIT
    /////////////////////////////////////////
    
    PXGroupsManager *groupsManager = [PXGroupsManager sharedManager];
#if SET_GROUP_ID_ON_LAUNCH
    groupsManager.groupID = @(SET_GROUP_ID_ON_LAUNCH);
#endif
    NSLog(@"[APP_DELEGATE] GROUP ID: %@", groupsManager.groupID);
    
    self.introManager = [PXIntroManager sharedManager];
    VCInjector.shared.demographicData = [[DemographicData alloc] init]; // restores from userdefs

    // Assign default settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{@"enable-sounds": @YES,
                                 @"enable-textured-colours": @YES
                                 }];
    
    BOOL isFirstRun = [defaults objectForKey:@"firstRun"] == nil;
    AppConfig.isFirstRun = isFirstRun;  //interface to swift
    
    //Saving first run date to determine if 30 day questionaire should be displayed
    if (isFirstRun)
        [defaults setObject:[NSDate strictDateFromToday] forKey:@"firstRun"];
#if SET_FIRST_RUN_DATE_TO_DAYS_BEFORE_NOW
    NSDate *d = [[NSDate date] dateByAddingTimeInterval:-(SET_FIRST_RUN_DATE_TO_DAYS_BEFORE_NOW * 24 * 3600)];
    [defaults setObject:d forKey:@"firstRun"];
    
#endif
    [[NSUserDefaults standardUserDefaults] synchronize];

    /////////////////////////////////////////
    // NOTIFICATIONS
    /////////////////////////////////////////
    NSLog(@"[APPD] Checking Notif auth ");
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
    UNUserNotificationCenter *notifCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notifCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSLog(@"[APPD] Notif auth retuned options: %lu", options);
        
        if (error) {
            NSLog(@"[APPD] Error registering for auth: %@", error);
            [DataServer.shared logError:@"UN registerAuth error" msg:error.localizedDescription info:nil];
            return;
        }
        
        if (options != UNAuthorizationOptionNone) {
            NSLog(@"[APPD] Updating consumption reminders");
            [[PXLocalNotificationsManager sharedInstance] updateConsumptionReminder];
        } else {
            NSLog(@"[APPD] Notif auth denied");
        }
    }];
    notifCenter.delegate = self;
    
    
    /////////////////////////////////////////
    // ONBOARDING
    /////////////////////////////////////////
    if (self.introManager.stage != PXIntroStageFinished) {
//        [self showIntroductionFromStage:self.introManager.stage];
        // Initialise onboarding
        VCInjector.shared.isOnboarding = YES;
        // Be sure to get the latest one if we had an onboarding which aborted AFTER the save
        AuditData *latest = [AuditData latest];
        VCInjector.shared.workingAuditData = latest ? latest : [[AuditData alloc] init];
        VCInjector.shared.workingAuditData.date = NSDate.strictDateFromToday;
        VCInjector.shared.workingAuditData.timezone = [NSTimeZone localTimeZone];
        [self showIntroductionFromStage:0]; // Force restart if app quits
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedIntro) name:@"PXFinishIntro" object:nil];

    
    /////////////////////////////////////////
    // DEBUGGING
    /////////////////////////////////////////
    
#if DEBUG

    
#if DBG_FAKE_DEMOGRAPHIC_DATA
    DemographicData *d = VCInjector.shared.demographicData;
    
    [d setAnswerWithQuestionId:@"question0" answerValue:@(1)];
    [d setAnswerWithQuestionId:@"question1" answerValue:@(1981)];
    [d setAnswerWithQuestionId:@"question5" answerValue:@(0)];
    [d setAnswerWithQuestionId:@"question7" answerValue:@(1)];
    [d setAnswerWithQuestionId:@"question9" answerValue:@(0)];
    
    [d saveWithLocalOnly:NO];

#endif
        
    
    // HK: This is kinda obsolete now as all the high-low stuff has been removed I think
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showGroupsPicker)];
    [swipeGesture setNumberOfTouchesRequired:2];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.window addGestureRecognizer:swipeGesture];

    // HK: New general debug bar, moving forward...
#if ENABLE_TIME_DEBUG_PANEL

    self.floatingDebugVC = [[DLFloatingDebugVC alloc] init];
    [self.window.rootViewController.view addSubview:self.floatingDebugVC.view];

//    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFloatingDebug)];
//    tapGR.numberOfTapsRequired = 2;
//    tapGR.numberOfTouchesRequired = 2;
//    [self.window addGestureRecognizer:tapGR];
#endif


    ////////////////////////////////////////
    // MARK: DEBUG STARTUP STUFF
    ////////////////////////////////////////
    
    //[PXCoreDataManager.sharedManager dbg_deleteCustomDrinkServings];

    if (Debug.ENABLED) {
        [self _popuplateWithData];
    
    }
    
    //[self _cleanupDuplicateAlcoholFreeDays];

// New Swift port
    [Debug doHook:@"AppLaunch" arg1:nil];

    
#endif //DEBUG
    
    return YES;
}

// Handles notifs while app is open
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    [[PXLocalNotificationsManager sharedInstance] showNotification:notification];
    completionHandler(UNNotificationPresentationOptionSound);
    
}

// Handles notif while app suspended or killed
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response withCompletionHandler:(nonnull void (^)(void))completionHandler {
    
    [[PXLocalNotificationsManager sharedInstance] showNotification:response.notification];
    completionHandler();
}


/**  HKS NOTE! We only call this with 0 now. Onboarding is no longer pick up where you left off. It would need some rethinking if we reimplement this as we have more screens now and have abandoned the VC id naming scheme used below */
- (void)showIntroductionFromStage:(PXIntroStage)introStage {
    // TEMP
#ifdef FORCE_INTRO_STAGE
    introStage = FORCE_INTRO_STAGE;
#endif


    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PXIntroNavigationController* introNav = (PXIntroNavigationController*)[storyboard instantiateInitialViewController];
    introNav.modalPresentationStyle = UIModalPresentationFullScreen;
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

//---------------------------------------------------------------------

- (void)finishedIntro {
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];

    VCInjector.shared.isOnboarding = NO;
    
//    // SURVEY
//    // For new users only, determine whether they qualify for the survey and schedule it to show in background
//    if (self.introManager.qualifiesForQuestionnaire) {
//        NSLog(@"******* QUESTIONNAIRE: User eligible, will schedule on suspend *******");
//        _scheduleQuestionnaireAlertOnSuspend = YES;
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PXUserEligibleForQuestionnaireKey];  // set a flag so we can do an alert if they come back later having ignored the localnotif
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    } else {
//        NSLog(@"******* QUESTIONNAIRE: User not eligible *******");
//    }
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


- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"******* APPLICATION: WillResignActive  *******");
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"******* APPLICATION: DidEnterBackground  *******");

//    if (_scheduleQuestionnaireAlertOnSuspend) {
//        NSLog(@"******* SURVEY: Scheduling survey notification *******");
//        [[PXLocalNotificationsManager sharedInstance] scheduleSurveyNotification];
//        _scheduleQuestionnaireAlertOnSuspend = NO;
//    }

    if (!self.introManager.isParseUpdated) {
        [self.introManager save];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

    NSLog(@"******* APPLICATION: WillEnterForeground  *******");

//    // QUESTIONAIRRE SURVEY
//    if ([NSUserDefaults.standardUserDefaults boolForKey:PXUserEligibleForQuestionnaireKey]) {
//        NSLog(@"******* SURVEY: App resumed with survey eligibility flag set (might be from a notif too). *******");
//        _didResumeHavingQuestionnaireElgibility = YES;
//        [NSUserDefaults.standardUserDefaults setBool:NO forKey:PXUserEligibleForQuestionnaireKey];
//        [NSUserDefaults.standardUserDefaults synchronize];
//    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"******* APPLICATION: DidBecomeActive  *******");

    application.applicationIconBadgeNumber = 0;
    
    self.isLaunching = NO;  // clear flag for disentangling fresh run / resume
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
    NSURL *url = [NSURL URLWithString:urlStr];
    [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} completionHandler:nil];
}

//---------------------------------------------------------------------

/** Added Nov'18. */
- (void)_cleanupDuplicateAlcoholFreeDays
{
    // Lets do it as a one-off for now
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BOOL done = [defs boolForKey:@"AlcoholFreeDuplicatesCleaned"];
    if (done) {
        logd(@"Alc Free duplicate checks done already. Skipping.");
        return;
    }
    [defs setBool:YES forKey:@"AlcoholFreeDuplicatesCleaned"];
    [defs synchronize];
    
    // Fetch all the Alc Free records...
    NSManagedObjectContext *context = PXCoreDataManager.sharedManager.managedObjectContext;
    NSFetchRequest *req = [PXAlcoholFreeRecord alcoholFreeRecordFetchRequest];
    req.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    NSError *error;
    NSArray <PXAlcoholFreeRecord *> *records = [context executeFetchRequest:req error:&error];
    if (error) {
        [[UIAlertController errorAlert:error] show];
        return;
    }
    
    logd(@"Checking for duplicate Alcohol Free days in %lu records...", records.count);
    
    
    // Loop through and check adjacent records for ones with same calendar date
    const int EXTEND = 20;  // amount to keep checking beyond when different cal date is found
    NSMutableSet <PXAlcoholFreeRecord *> *recsToDelete = NSMutableSet.set;
    NSMutableDictionary <NSDate *, NSNumber *> *datesDupsCount = NSMutableDictionary.dictionary;
    
    for (int i=0; i<=(int)records.count - 2; i++) {

        PXAlcoholFreeRecord *rec = records[i];
        NSTimeZone *recTZ = [NSTimeZone timeZoneForAlcoholFreeRecord:rec];
        NSDate *normedDate = [rec.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:recTZ];

        int compareUpperBounds = MIN(i+1 + EXTEND, (int)records.count-1);

        logd(@"Checking Alc Free Record idx=%i date=%@ tz=%@ (normed: %@) UB=%i", i, rec.date, recTZ, [NSDateFormatter localizedStringFromDate:normedDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], compareUpperBounds);
        
        for (int j=i+1; j<=compareUpperBounds; j++) {
            PXAlcoholFreeRecord *compareRec = records[j];
            NSTimeZone *compareRecTZ = [NSTimeZone timeZoneForAlcoholFreeRecord:compareRec];
            NSDate *normedCompareDate = [compareRec.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:compareRecTZ];
            
            BOOL isSameCalendarDate = [normedDate isSameCalendarDateAs:normedCompareDate];
            if (isSameCalendarDate) {
                int cnt = [datesDupsCount[normedDate] intValue];
                datesDupsCount[normedDate] = @(cnt+1);
                [recsToDelete addObject:compareRec];
                
                // Extend the search
                compareUpperBounds = MIN(j + EXTEND, (int)records.count-1);
                
                logd(@"Duplicate found! idx=%i date=%@ tz=%@ (normed: %@). UB extended to %i", i, compareRec.date, compareRecTZ, [NSDateFormatter localizedStringFromDate:normedCompareDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], compareUpperBounds);
            }
        }
        
        // While we're at it, look for a drink record with the same calendar date and erase this entry if so.
        NSFetchRequest *req2 = [PXDrinkRecord fetchRequestForCalendarDate:normedDate context:context];
        BOOL drinksOnDate = [context executeFetchRequest:req2 error:nil].count > 0;
        if (drinksOnDate) {
            int cnt = [datesDupsCount[normedDate] intValue];
            datesDupsCount[normedDate] = @(cnt+1);
            [recsToDelete addObject:rec];
        }
    }
        
    // Now do the deletions
    for (PXAlcoholFreeRecord *rec in recsToDelete) {
        [context deleteObject:rec];
    }
    [context save:&error];
    if (error) {
        [[UIAlertController errorAlert:error] show];
        return;
    } else {
        logd(@"Deleted %li Alcohol Free Records", recsToDelete.count);
    }
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - DEBUG
/////////////////////////////////////////////////////////////////////////

- (void)_popuplateWithData
{//return;
    if (!Debug.ENABLED) {
        return;
    }
    
    
    BOOL DO_RANDOM_ADDER = Debug.DATA_POPULATION.DO_DRINKS_RANDOM;
    BOOL DO_MOOD_DIARY = Debug.DATA_POPULATION.DO_MOOD_DIARY;
    NSUInteger QUANTITY_MAX = Debug.DATA_POPULATION.MAX_DRINK_QUANTITY;
    BOOL ERASE = Debug.DATA_POPULATION.DO_ERASE;
    NSUInteger DAYS_BACK = Debug.DATA_POPULATION.DAYS_BACK;
    
    
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
    if (Debug.DATA_POPULATION.DO_DRINKS_SPECIFIC) {
        
        NSLog(@"DEBUG: ******* POPULATING WITH SPECIFIC DRINK DATA *******");
        
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
    }

    
    /////////////////////////////////////////
    // RANDOM ADDER
    /////////////////////////////////////////
    
    if (DO_RANDOM_ADDER) {
        NSLog(@"DEBUG: ******* POPULATING WITH RANDOM DRINK DATA *******");
        
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
    }
    
    /////////////////////////////////////////
    // GOALS
    /////////////////////////////////////////

    if (Debug.DATA_POPULATION.DO_GOALS) {
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
    }

    /////////////////////////////////////////
    // MOOD DIARY DATA
    /////////////////////////////////////////

    if (DO_MOOD_DIARY) {
        // Delete existing...
        NSLog(@"DEBUG: ******* POPULATING MOOD DIARY DATA *******");
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
}


@end
