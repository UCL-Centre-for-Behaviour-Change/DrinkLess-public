//
//  PXEditActionPlanViewController.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXEditActionPlanViewController.h"
#import "PXPlaceholderTextViewRenamed.h"
#import "PXActionPlan.h"
#import "PXInfoViewController.h"
#import "drinkless-Swift.h"

@interface PXEditActionPlanViewController ()

@property (weak, nonatomic) IBOutlet UILabel *ifLabel;
@property (weak, nonatomic) IBOutlet UILabel *thenLabel;
@property (weak, nonatomic) IBOutlet PXPlaceholderTextViewRenamed *ifTextView;
@property (weak, nonatomic) IBOutlet PXPlaceholderTextViewRenamed *thenTextView;
@property (nonatomic) CGFloat rowHeight;

@end

@implementation PXEditActionPlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_actionPlan) {
        _actionPlan = [[PXActionPlan alloc] init];
        self.title = @"New action plan";
    } else {
        self.title = @"Edit action plan";
    }
    
    // Not enough room on 3.5"
    if (CGRectGetHeight(self.view.frame) <= 480.0) {
        self.ifTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.thenTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    
    self.ifTextView.text = self.actionPlan.ifText;
    self.thenTextView.text = self.actionPlan.thenText;
    self.ifTextView.placeholder = @"event";
    self.thenTextView.placeholder = @"action";
    [self configureTextView:self.ifTextView];
    [self configureTextView:self.thenTextView];
    
    UIColor *ifColor = [UIColor blackColor];
    UIColor *thenColor = [UIColor drinkLessGreenColor];
    self.ifLabel.textColor = ifColor;
    self.ifTextView.textColor = ifColor;
    self.thenLabel.textColor = thenColor;
    self.thenTextView.textColor = thenColor;
    
    self.rowHeight = self.tableView.rowHeight;
}

- (void)configureTextView:(UITextView *)textView {
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.textContainerInset = UIEdgeInsetsMake(1.0, 0.0, 1.0, 0.0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [self.ifTextView becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Edit action plans"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Using delegate instead of self.tableView.rowHeight as it doesn't work on iOS 7
    return self.rowHeight;
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    CGFloat tableViewHeight = self.tableView.frame.size.height;
    CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
    CGFloat footerHeight = self.tableView.sectionFooterHeight;
    CGFloat totalHeight = tableViewHeight - headerHeight - footerHeight - keyboardHeight;
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    
    [self.tableView beginUpdates];
    self.rowHeight = roundf(totalHeight / rows);
    [self.tableView endUpdates];
}

#pragma mark - Actions

- (IBAction)pressedCancel:(id)sender {
    [self.view endEditing:YES];
    [self.delegate didCancelEditing:self];
}

- (IBAction)pressedSave:(id)sender {
    [self.view endEditing:YES];
    self.actionPlan.ifText = self.ifTextView.text;
    self.actionPlan.thenText = self.thenTextView.text;
    NSString *errorMessage = self.actionPlan.errorMessage;
    if (errorMessage) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [self.delegate didFinishEditing:self];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"action-plan-edit" fromViewController:self];
}

@end
