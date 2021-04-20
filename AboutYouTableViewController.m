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
#import <MessageUI/MessageUI.h>
#import "PXIntroManager.h"
#import "PXGroupsManager.h"
#import "PXSolidButton.h"
#import "PXDeviceUID.h"
//#import <Apptimize/Apptimize.h>
#import "PXWebViewController.h"
#import "drinkless-Swift.h"

static NSInteger const PXEmailAlert = 23;
static NSInteger const PXGroupQueryErrorAlert = 24;
static NSInteger const PXEmailSuggestAlert = 25;

@interface AboutYouTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UINavigationController *navVC;
@property (strong, nonatomic) NSMutableArray *questionsArray;
@property (strong, nonatomic) PopoverVC *yearPopover;
@property (strong, nonatomic) PXIntroManager *introManager;
@property (nonatomic, getter = shouldSendEmail) BOOL sendsEmail;
@property (weak, nonatomic) IBOutlet PXSolidButton *continueButton;
@property (nonatomic, assign) BOOL isEmailAlertShown;

@property (nonatomic) BOOL isOnboarding;
@property (nonatomic, strong) DemographicData *demographicData;
@property (nonatomic, strong) AuditData *auditData;

@end

@implementation AboutYouTableViewController
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"About You";
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Demographics" ofType:@"plist"];
    self.questionsArray = [NSMutableArray arrayWithContentsOfFile:filepath];
    self.introManager = [PXIntroManager sharedManager];
    self.demographicData = VCInjector.shared.demographicData;
    self.auditData = VCInjector.shared.workingAuditData;
    self.isOnboarding = VCInjector.shared.isOnboarding;

    // Sanity check:
    NSAssert(self.isOnboarding, @"This VC should only exist in an Onboarding context!");
    
    
//    NSString *optionalAnswerKey = @"email"; // Allows email to be optional
//    if (!self.introManager.demographicsAnswers[optionalAnswerKey]) {
//        self.introManager.demographicsAnswers[optionalAnswerKey] = @"";
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXShowProgressToolbar" object:nil userInfo:nil];
    
//    [Apptimize runTest:@"Email address manual entry vs send email" withBaseline:^{
//        // Baseline variant "original"
//        self.sendsEmail = NO;
//    } andVariations:@{@"variation1": ^{
//        // Variant "Alert and then send email"
//        self.sendsEmail = YES;
//    }}];
    
#if DEBUG
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_autoselect)];
    gr.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:gr];
#endif
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"About you questions"];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"about-you"]) {
        [self _autoselect];
    }
}

- (void)showYearsListAtIndexPath:(NSIndexPath*)indexPath{
    NSDictionary* questionDict = self.questionsArray[indexPath.section];
    PXTextEntryCell* cell = (PXTextEntryCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    PXYearList* yearListVC = [[PXYearList alloc] initWithNibName:@"PXYearList" bundle:nil];
    yearListVC.delegate = self;
    yearListVC.cellIndexPath = indexPath;
    yearListVC.selectedYear = [(NSNumber *)[self.demographicData answerWithQuestionId:questionDict[@"questionID"]] integerValue];
    
    self.yearPopover = [[PopoverVC alloc] initWithContentVC:yearListVC preferredSize:CGSizeMake(120, 300) sourceView:cell.contentView sourceRect:cell.contentView.frame];

    [self presentViewController:self.yearPopover animated:YES completion:nil];
    
//    [self.yearPopover presentPopoverFromView:cell];
    
    [yearListVC highlightSelectedYear];
}


- (IBAction)pressedContinue:(id)sender {
    [self.view endEditing:YES];
    
    if (self.demographicData.answerCount < self.questionsArray.count) {
        [[UIAlertController simpleAlertWithTitle:nil msg:@"Please answer all the questions" buttonTxt:@"Ok"] showIn:self];
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

    // Note we've been forcing group0 for a while now
    // Check if they conform to the criteria for a group and query from Parse: https://github.com/PortablePixels/DrinkLess/issues/183
    // Some preliminary info needed for the checks
//    NSInteger auditScore = self.auditData.auditScore;
//    NSDate *now = [NSDate date];
//    NSInteger currentYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:now];
//    NSInteger age = currentYear - [self.demographicData answerWithQuestionId:@"question1"].integerValue;
//    BOOL isUK = [[self.demographicData answerWithQuestionId:@"question5"] isEqual:@0];
//    BOOL isSerious = [[self.demographicData answerWithQuestionId:@"question9"] isEqual:@0];
//
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
    
    // Save the demographic info if updated during the a follow up audit, but not the onboarding stage
    NSAssert(self.isOnboarding, @"Should only be on AboutYouVC if onboarding");
    self.introManager.stage = PXIntroStageSlider;
    [self.introManager save];  // hks note: if we want to save the group id then
    [self.demographicData saveWithLocalOnly:NO];
    
 
    
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
        
        NSNumber* selected = (NSNumber *)[self.demographicData answerWithQuestionId:questionDict[@"questionID"]];
//        self.introManager.demographicsAnswers[questionDict[@"questionID"]];
        if (selected) {
            if (indexPath.row == selected.integerValue) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        
        return cell;
        
    } else if ([questionType isEqualToString:@"yearEntry"]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YearCell" forIndexPath:indexPath];
        NSInteger year = ((NSNumber *)[self.demographicData answerWithQuestionId:questionDict[@"questionID"]]).integerValue;
        //[self.introManager.demographicsAnswers[questionDict[@"questionID"]] integerValue];
        if (year == 0 ) {
            cell.textLabel.text = @"Tap to select";
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)year];
        }
        return cell;
        
    } else {
        NSString *cellIdentifier = nil;
        BOOL emailEntry = NO;
        
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
        cell.textField.text = ((NSNumber *)[self.demographicData answerWithQuestionId:questionDict[@"questionID"]]).stringValue;
//        self.introManager.demographicsAnswers[questionDict[@"questionID"]];
        
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
        [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(indexPath.row)];
        //[self.introManager.demographicsAnswers setObject:@(indexPath.row) forKey:questionDict[@"questionID"]];
        [self.tableView reloadData];
    }
}

// Still used??
- (void)showEmailAlert {
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"No need to type your email address, just click Send on the next screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    alertView.tag = PXEmailAlert;
//
//    [alertView show];
//
    
    [[UIAlertController simpleAlertWithTitle:nil msg:@"No need to type your email address, just click Send on the next screen" buttonTxt:@"Ok" callback:nil] showIn:self];
    
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (alertView.tag == PXEmailAlert) {
//        [self showComposeEmail];
//    } else if (alertView.tag == PXGroupQueryErrorAlert) {
//        [self queryAndSetGroupIDFromParse]; // i.e. retry...
//    }
//    else if (alertView.tag == PXEmailSuggestAlert) {
//
//        if (buttonIndex == 1) {
//
//            [self pressedContinue:nil];
//        }
//    }
//
//}

-(void)showComposeEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Drinkless Demographics"];
        NSString *msgBody = [NSString stringWithFormat:@"It's really important for us to understand whether this app helps you to drink less. And because you might stop using the app, the best way for us to contact you is by email.\n\nIf you give us your email address we'll be in touch in a month with a few questions that should take about two minutes to complete and you’ll be entered into a draw to win a £500 voucher.\n\nWe will only email you about this study and will never give or sell your email address to anyone else.\n\nThank you for helping science.\n\nDavid Crane\nClaire Garnett\nSusan Michie (Principal Investigator)\n\nID:%@\niOS version:%@", [DataServer.shared userId], [UIDevice currentDevice].systemVersion];
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
//    NSAssert(NO, @"Not obsolete after all...!);
//    return;
    NSDictionary* questionDict = self.questionsArray[textField.tag];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:textField.text];
//    [self.introManager.demographicsAnswers setObject:textField.text forKey:questionDict[@"questionID"]];
}

#pragma mark PXYearListDelegate methods

- (void)yearList:(PXYearList *)dateList chosenYear:(NSInteger)year {
    NSDictionary* questionDict = self.questionsArray[dateList.cellIndexPath.section];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(year)];
//    [self.introManager.demographicsAnswers setObject:@(year) forKey:questionDict[@"questionID"]];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:dateList.cellIndexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)year];
    
    [self.yearPopover dismissViewControllerAnimated:YES completion:nil];
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
    __weak AboutYouTableViewController *wself = self;
    [self.navVC dismissViewControllerAnimated:YES completion:^{
        wself.navVC = nil;
    }];
}

//---------------------------------------------------------------------

// for quick debugging
- (void)_autoselect
{
    NSDictionary *questionDict;
    NSIndexPath *idxp;
    
    // Gender
    questionDict = self.questionsArray[0];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(1)];
    idxp = [NSIndexPath indexPathForItem:0 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:idxp];

    
    // b year
    questionDict = self.questionsArray[1];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(1979)];
    
    // country
    questionDict = self.questionsArray[2];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(0)];
    idxp = [NSIndexPath indexPathForItem:0 inSection:2];
    [self tableView:self.tableView didSelectRowAtIndexPath:idxp];

    // job
    questionDict = self.questionsArray[3];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(0)];
    idxp = [NSIndexPath indexPathForItem:0 inSection:3];
    [self tableView:self.tableView didSelectRowAtIndexPath:idxp];

    
    // why using app
    questionDict = self.questionsArray[4];
    [self.demographicData setAnswerWithQuestionId:questionDict[@"questionID"] answerValue:@(0)];
    idxp = [NSIndexPath indexPathForItem:0 inSection:4];
    [self tableView:self.tableView didSelectRowAtIndexPath:idxp];

    [self.tableView scrollToRowAtIndexPath:idxp atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"about-you"]) {
        [self pressedContinue:nil];
    }
}

@end
