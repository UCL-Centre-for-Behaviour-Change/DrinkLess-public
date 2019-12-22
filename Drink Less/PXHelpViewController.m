//
//  PXHelpViewController.m
//  drinkless
//
//  Created by Greg Plumbly on 11/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXHelpViewController.h"
#import "PXGroupsManager.h"
#import "PXWebViewController.h"
#import "iRate.h"
#import "drinkless-Swift.h"
#import "OneMonthFollowUpTableViewController.h"

static NSInteger const PXOptOutTag = 100;
static NSTimeInterval const PXDayTimeInterval = 60 * 60 * 24;

@interface PXHelpViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableArray *navItemsArray;
@property (nonatomic, readonly) BOOL isEligibleForSurvey;

@end

@implementation PXHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"PXHelpNav" ofType:@"plist"];
    self.navItemsArray = [NSMutableArray arrayWithContentsOfFile:filepath];
    
    /////////////////////////////////////////
    // MRT TRIAL
    /////////////////////////////////////////
    // For the duration of the trial remove the reminders section
    if (MRTNotificationsManager.shared.trialIsActivelyRunning) {
        NSLog(@"MRT -- Removing 'Reminders' section whilst trial is on");
        NSMutableArray *entry = [(NSArray *)self.navItemsArray[1][@"rows"] mutableCopy];
        [entry removeObjectAtIndex:0];
        self.navItemsArray[1][@"rows"] = entry;
    }
    
    [self removeSurveyIfNeeded];
    [self.tableView reloadData];
}

- (void)removeSurveyIfNeeded {
    if (!self.isEligibleForSurvey) {
        for (NSDictionary *section in self.navItemsArray) {
            NSMutableArray *rows = section[@"rows"];
            for (NSUInteger i = 0; i < rows.count; i++) {
                if ([rows[i][@"vc"] isEqualToString:@"questionnaire"]) {
                    [rows removeObjectAtIndex:i];
                    return;
                }
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Help menu"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.navItemsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.navItemsArray[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.navItemsArray[section][@"sectiontitle"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *dictionary = self.navItemsArray[indexPath.section][@"rows"][indexPath.row];
    
    // Intercept the boolean setting for sound.
    if ([dictionary[@"identifier"] isEqualToString:@"enable-sounds"]) {
        BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"];
        cell.textLabel.text = dictionary[@"title"];
        cell.accessoryType = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if ([dictionary[@"identifier"] isEqualToString:@"enable-textured-colours"]) {
        BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable-textured-colours"];
        cell.textLabel.text = dictionary[@"title"];
        cell.accessoryType = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        NSString *viewController = dictionary[@"vc"];
        if ([viewController isEqualToString:@"PXActionPlansViewController"] && ![PXGroupsManager sharedManager].highAP.boolValue) {
            cell.textLabel.text = @"Why set an action plan?";
        } else {
            cell.textLabel.text = dictionary[@"title"];
        }
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dictionary = self.navItemsArray[indexPath.section][@"rows"][indexPath.row];
    NSString *identifier = dictionary[@"vc"] ?: dictionary[@"identifier"]; // really should change them all to "iden..."
    NSString *segueIdentifier = dictionary[@"segue"];
    NSString *resource = dictionary[@"resource"];
    
    if (identifier.length > 0) {
        if ([identifier isEqualToString:@"rate"]) {
            [[iRate sharedInstance] openRatingsPageInAppStore];
        }
        else if ([identifier isEqualToString:@"questionnaire"]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FollowUp" bundle:nil];
            OneMonthFollowUpTableViewController *followUpVC = [storyboard instantiateInitialViewController];
            [self.navigationController pushViewController:followUpVC animated:YES];
        }
        else if ([identifier isEqualToString:@"opt-out"]) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Please confirm you wish to opt-out of the study"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:@"Opt-out"
                                                            otherButtonTitles:nil, nil];
            actionSheet.tag = PXOptOutTag;
            [actionSheet showInView:tableView];
        }
        else if ([identifier isEqualToString:@"reset"]) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Reset App?"
                                                                     delegate:self
                                                            cancelButtonTitle:@"No"
                                                       destructiveButtonTitle:@"Yes"
                                                            otherButtonTitles:nil];
            actionSheet.tag = PXOptOutTag;
            [actionSheet showInView:tableView];
        }
        else if ([identifier isEqualToString:@"enable-sounds"] ||
                 [identifier isEqualToString:@"enable-textured-colours"]) {
            // Toggle the userdef and update the table cell
            NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
            BOOL enabled = [defs boolForKey:identifier];
            enabled = !enabled;
            [defs setBool:enabled forKey:identifier];
            [defs synchronize];
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else {
            UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
    else if (segueIdentifier.length > 0) {
        [self performSegueWithIdentifier:segueIdentifier sender:self];
    } else if (resource.length > 0) {
        [self performSegueWithIdentifier:@"show_HTML" sender:resource];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        switch (actionSheet.tag) {
            case PXOptOutTag:
                [self optOutUpdateParse];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"show_HTML"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        NSDictionary *dictionary = self.navItemsArray[indexPath.section][@"rows"][indexPath.row];
        PXWebViewController *webViewController = segue.destinationViewController;
        webViewController.resource = sender;
        webViewController.title = dictionary[@"title"];
    }
}

#pragma mark - Properties

- (BOOL)isEligibleForSurvey {
    return NO;  // This pulls from the wrong data "OneMonthFOllowUp..." is redundant. It wasnt working because the maths is wrong (needs a negative) so we'll just disable it.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"completedQuestionnaire"]) {
        NSDate *firstRunDate = [userDefaults objectForKey:@"firstRun"];
        if (firstRunDate.timeIntervalSinceNow < PXDayTimeInterval * 30) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Actions

- (IBAction)closeTapped:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)optOutUpdateParse {
    [DataServer.shared setUserOptOut:YES callback:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"user opted out");
            [[[UIAlertView alloc] initWithTitle:@"Opt-out successful"
                                        message:@"You have successfully opted out of the study"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"An error has occurred."
                                        message:@"Could not contact the server but your preference has been saved on your device. Would you mind letting support know?"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
    }];
    
    AppConfig.userHasOptedOut = YES;
    DataServer.shared.isEnabled = NO;
}

@end
