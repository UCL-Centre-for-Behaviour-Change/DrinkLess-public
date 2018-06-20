//
//  AboutYouTableViewController.m
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "AboutYouTableViewController.h"
#import "PXTextEntryCell.h"
#import "FPPopoverController.h"
#import <MessageUI/MessageUI.h>
#import "PXIntroManager.h"
#import "PXGroupsManager.h"
#import "PXSolidButton.h"
#import "PXDeviceUID.h"
#import <Parse/Parse.h>
#import <Apptimize/Apptimize.h>
#import <Google/Analytics.h>
#import "PXWebViewController.h"
//#import "PXInfoViewController.h"


static NSInteger const PXEmailAlert = 23;
static NSInteger const PXGroupQueryErrorAlert = 24;
static NSInteger const PXEmailSuggestAlert = 25;

@interface AboutYouTableViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *questionsArray;
@property (strong, nonatomic) FPPopoverController *yearPopover;
@property (strong, nonatomic) PXIntroManager *introManager;
@property (nonatomic, getter = shouldSendEmail) BOOL sendsEmail;
@property (weak, nonatomic) IBOutlet PXSolidButton *continueButton;
@property (nonatomic, assign) BOOL isEmailAlertShown;
@end

@implementation AboutYouTableViewController
{
    UINavigationController *_navVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"About You";
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Demographics" ofType:@"plist"];
    self.questionsArray = [NSMutableArray arrayWithContentsOfFile:filepath];
    self.introManager = [PXIntroManager sharedManager];
    
//    NSString *optionalAnswerKey = @"email"; // Allows email to be optional
//    if (!self.introManager.demographicsAnswers[optionalAnswerKey]) {
//        self.introManager.demographicsAnswers[optionalAnswerKey] = @"";
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXShowProgressToolbar" object:nil userInfo:nil];
    
    [Apptimize runTest:@"Email address manual entry vs send email" withBaseline:^{
        // Baseline variant "original"
        self.sendsEmail = NO;
    } andVariations:@{@"variation1": ^{
        // Variant "Alert and then send email"
        self.sendsEmail = YES;
    }}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"About you questions"];
}

- (void)showYearsListAtIndexPath:(NSIndexPath*)indexPath{
    NSDictionary* questionDict = self.questionsArray[indexPath.section];
    PXTextEntryCell* cell = (PXTextEntryCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    PXYearList* yearListVC = [[PXYearList alloc] initWithNibName:@"PXYearList" bundle:nil];
    yearListVC.delegate = self;
    yearListVC.cellIndexPath = indexPath;
    yearListVC.selectedYear = [self.introManager.demographicsAnswers[questionDict[@"questionID"]] integerValue];
    
    self.yearPopover = [[FPPopoverController alloc] initWithViewController:yearListVC];
    self.yearPopover.border = NO;
    self.yearPopover.tint = FPPopoverWhiteTint;
    self.yearPopover.contentSize = CGSizeMake(120.0, 300.0);
    [self.yearPopover presentPopoverFromView:cell];
    
    [yearListVC highlightSelectedYear];
}


- (IBAction)pressedContinue:(id)sender {
    [self.view endEditing:YES];
    
    if (self.introManager.demographicsAnswers.count < self.questionsArray.count) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please answer all the questions" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    // No longer asked
//    NSString *email = self.introManager.demographicsAnswers[@"email"];
//    if (!self.isEmailAlertShown && !email.length) {
//        
//        UIAlertView *emailAlertView = [[UIAlertView alloc] initWithTitle:@"Enter your email address and you could win £500. Your address is safe with us." message:nil delegate:self cancelButtonTitle:@"Enter Email" otherButtonTitles:@"No thanks", nil];
//        [emailAlertView show];
//        emailAlertView.tag = PXEmailSuggestAlert;
//        self.isEmailAlertShown = YES;
//        return;
//    }
    
    // Check if they conform to the criteria for a group and query from Parse: https://github.com/PortablePixels/DrinkLess/issues/183
    // Some preliminary info needed for the checks
    NSInteger auditScore = self.introManager.auditScore.integerValue;
    NSDate *now = [NSDate date];
    NSInteger currentYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:now];
    NSInteger age = currentYear - [self.introManager.demographicsAnswers[@"question1"] integerValue];
    BOOL isUK = [self.introManager.demographicsAnswers[@"question5"] isEqual:@0];
    
    BOOL isSerious = [self.introManager.demographicsAnswers[@"question9"] isEqual:@0];
    
    // Note: technically age is 18+ but we only have their year so it would include 17.x year olds too
    
    /*if (auditScore >= 8 &&
        age >= 19// &&
        //isUK &&   // no longer asked
        //email && email.length &&
        //isSerious
        ) {
        NSLog(@"GroupID: Setting via Parse");
        [self queryAndSetGroupIDFromParse];
        
    } else {*/
        NSLog(@"GroupID: 0");
        [PXGroupsManager sharedManager].groupID = @0;
        // We'll save to parse later (see PXIntroManager)
        //[[PXGroupsManager sharedManager] saveToParse];
        [self acknowledgeStageCompletion];
    //}
}

/** Will prompt and retry until successful which solves the app suspension problem */
- (void)queryAndSetGroupIDFromParse {
    NSLog(@"Querying Parse::getGroup...");
    
    // Cant do this if not actually querying parse! [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self.continueButton setTitle:@"One moment..." forState:UIControlStateNormal];
    self.continueButton.enabled = NO;
    
    // NOTES: https://github.com/PortablePixels/DrinkLess/issues/207
    // Let everyone default to groupID 0 so they get all the features
    [PXGroupsManager sharedManager].groupID = @0; // should be redundant but just in case it triggers something
    [self acknowledgeStageCompletion];
//    NSLog(@"[PARSE]: Querying for groupID");
//    [PFCloud
//     callFunctionInBackground:@"getGroup"
//     withParameters:nil
//     block:^(NSString *groupID, NSError *error) {
//         
//         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//         [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
//         self.continueButton.enabled = YES;
//         
//         if (error) {
//             NSLog(@"[PARSE]: Error querying groupID: %@", error);
//
//             // Prompt to retry if error (assume a network connection issue)
//             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"We're sorry, but we can't setup the app until there's a better connection to the internet. Please come back and try again and we'll get you drinking less." delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
//             alertView.tag = PXGroupQueryErrorAlert;
//             alertView.delegate = self;
//             [alertView show];
//         } else {
//             // Else assign group and end the stage...
//             NSLog(@"[PARSE]: Success. Assigning queried groupID: %@", groupID);
//             [PXGroupsManager sharedManager].groupID = @(groupID.integerValue);
//             // We'll save to parse later (see PXIntroManager)
//             [self acknowledgeStageCompletion];
//         }
//     }];
}

- (void)acknowledgeStageCompletion {
    
    self.introManager.stage = PXIntroStageSlider;
    [self.introManager save];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                          action:@"continue_and_confirm_on_about_you_questions"  // Event action (required)
                                                           label:@"continue"          // Event label
                                                           value:nil] build]];    // Event value
    
    
    //UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PXIntroVC3"];
    //[self.navigationController pushViewController:vc animated:YES];
    
    [self performSegueWithIdentifier:@"PXShowSliders" sender:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.questionsArray.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary* questionDict = self.questionsArray[section];
    return questionDict[@"questiontitle"];
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDictionary* questionDict = self.questionsArray[section];
    return questionDict[@"questionfooter"];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
//    spesical for email footer
//    https://github.com/PortablePixels/DrinkLess/issues/190
    if (section != 6) {
        
        return nil;
    }
    NSInteger offSet = 16;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.origin.x + offSet,
                                                               0,
                                                               tableView.frame.size.width - offSet * 2,
                                                               40)];
    label.numberOfLines = 0;
    label.font = [UIFont boldSystemFontOfSize:14.];
    label.text = @"Win a £500 voucher simply by letting us email you";
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(tableView.frame.origin.x,
                                                            0,
                                                            tableView.frame.size.width,
                                                            80)];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *questionDict = self.questionsArray[section];
    NSArray *answers = questionDict[@"answers"];
    if (answers) {
        return answers.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* questionDict = self.questionsArray[indexPath.section];
    NSString* questionType = questionDict[@"type"];
    
    if ([questionType isEqualToString:@"option"]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OptionCell" forIndexPath:indexPath];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSArray* answers = questionDict[@"answers"];
        cell.textLabel.text = answers[indexPath.row];
        
        NSNumber* selected = self.introManager.demographicsAnswers[questionDict[@"questionID"]];
        if (selected) {
            if (indexPath.row == selected.integerValue) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        
        return cell;
        
    } else if ([questionType isEqualToString:@"yearEntry"]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YearCell" forIndexPath:indexPath];
        NSInteger year = [self.introManager.demographicsAnswers[questionDict[@"questionID"]] integerValue];
        if (year == 0 ) {
            cell.textLabel.text = @"Tap to select";
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)year];
        }
        return cell;
        
    } else {
        NSString *cellIdentifier = nil;
        BOOL emailEntry;
        
        if ([questionType isEqualToString:@"textEntry"]) {
            cellIdentifier = @"TextEntryCell";
        } else if ([questionType isEqualToString:@"numberEntry"]) {
            cellIdentifier = @"NumberEntryCell";
        } else if ([questionType isEqualToString:@"emailEntry"]) {
            cellIdentifier = @"EmailEntryCell";
            emailEntry = YES;
        }
        PXTextEntryCell *cell = (PXTextEntryCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textField.placeholder = questionDict[@"placeholder"];
        cell.textField.delegate = self;
        cell.textField.tag = indexPath.section;
        cell.textField.text = self.introManager.demographicsAnswers[questionDict[@"questionID"]];
        
        cell.textField.userInteractionEnabled = !(emailEntry && self.shouldSendEmail);
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
        cell.textField.autocorrectionType = emailEntry ? UITextAutocorrectionTypeNo : UITextAutocorrectionTypeDefault;
        
        return cell;
    }
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *type = self.questionsArray[indexPath.section][@"type"];
    if ([type isEqualToString:@"emailEntry"]) {
        return self.shouldSendEmail;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary* questionDict = self.questionsArray[indexPath.section];
    NSString* questionType = questionDict[@"type"];
    
    if ([questionType isEqualToString:@"textEntry"]) {
        PXTextEntryCell* cell = (PXTextEntryCell*)[tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
    } else if ([questionType isEqualToString:@"yearEntry"]) {
        [self showYearsListAtIndexPath:indexPath];
    } else if ([questionType isEqualToString:@"emailEntry"]) {
        [self showEmailAlert];
    } else if ([questionType isEqualToString:@"option"]) {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.introManager.demographicsAnswers setObject:@(indexPath.row) forKey:questionDict[@"questionID"]];
        [self.tableView reloadData];
    }
}

- (void)showEmailAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"No need to type your email address, just click Send on the next screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    alertView.tag = PXEmailAlert;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PXEmailAlert) {
        [self showComposeEmail];
    } else if (alertView.tag == PXGroupQueryErrorAlert) {
        [self queryAndSetGroupIDFromParse]; // i.e. retry...
    }
    else if (alertView.tag == PXEmailSuggestAlert) {
        
        if (buttonIndex == 1) {
        
            [self pressedContinue:nil];
        }
    }

}

-(void)showComposeEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Drinkless Demographics"];
        NSString *msgBody = [NSString stringWithFormat:@"It's really important for us to understand whether this app helps you to drink less. And because you might stop using the app, the best way for us to contact you is by email.\n\nIf you give us your email address we'll be in touch in a month with a few questions that should take about two minutes to complete and you’ll be entered into a draw to win a £500 voucher.\n\nWe will only email you about this study and will never give or sell your email address to anyone else.\n\nThank you for helping science.\n\nDavid Crane\nClaire Garnett\nSusan Michie (Principal Investigator)\n\nID:%@\niOS version:%@", [PFUser currentUser].objectId, [UIDevice currentDevice].systemVersion];
        [mail setMessageBody:msgBody isHTML:NO];
        [mail setToRecipients:@[@"followup@drinklessalcohol.org"]];
        [self presentViewController:mail animated:YES completion:NULL];
    }
    else {
        NSLog(@"This device cannot send email");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
        case MFMailComposeResultSaved:
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"questionID == %@", @"email"];
            NSMutableDictionary *question = [self.questionsArray filteredArrayUsingPredicate:predicate].firstObject;
            if (question) {
                [self.questionsArray removeObject:question];
                [self.tableView reloadData];
            }
        } break;
            
        default:
            NSLog(@"Email cancelled or failed");
            break;
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSDictionary* questionDict = self.questionsArray[textField.tag];
    [self.introManager.demographicsAnswers setObject:textField.text forKey:questionDict[@"questionID"]];
}

#pragma mark PXYearListDelegate methods

- (void)yearList:(PXYearList *)dateList chosenYear:(NSInteger)year {
    NSDictionary* questionDict = self.questionsArray[dateList.cellIndexPath.section];
    [self.introManager.demographicsAnswers setObject:@(year) forKey:questionDict[@"questionID"]];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:dateList.cellIndexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)year];
    
    [self.yearPopover dismissPopoverAnimated:YES];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
/////////////////////////////////////////////////////////////////////////

- (IBAction)termsConditionsPressed {
    _navVC = [[UINavigationController alloc] init];
    PXWebViewController *webVC = [[PXWebViewController alloc] init];
    webVC.resource = @"terms-conditions";
    webVC.view.tag = 440; // skip the tip. See UIVC+PXHelpers
    webVC.title = @"Terms & Conditions";
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismissTermsConditions)];
    [webVC.navigationItem setRightBarButtonItem:closeBtn];
    
    _navVC.viewControllers = @[webVC];
    _navVC.view.backgroundColor = UIColor.whiteColor;
    _navVC.view.opaque = YES;
    [self presentViewController:_navVC animated:YES completion:nil];
    //[PXInfoViewController showResource:@"terms-conditions" fromViewController:self];
}

- (void)dismissTermsConditions {
    [_navVC dismissViewControllerAnimated:YES completion:^{
        _navVC = nil;
    }];
}


@end
