//
//  PXGoalsHeader.m
//  drinkless
//
//  Created by Edward Warrender on 18/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalsHeader.h"
#import <Parse/Parse.h>

static NSString *const PXGoalReasonKey = @"goalReason";

@interface PXGoalsHeader () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *placeholderView;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) UIView *headerView;

@property (strong, nonatomic) NSString *goalReason;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation PXGoalsHeader

@synthesize goalReason = _goalReason;

- (id)init {
    self = [super init];
    if (self) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self.class) bundle:nil];
    [nib instantiateWithOwner:self options:nil];
    
    self.textView.text = self.goalReason;
    self.textView.textColor = [UIColor drinkLessGreenColor];
    self.textView.textContainer.lineFragmentPadding = 0.0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
}

- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    [self setHeaderView:nil animated:NO];
}

- (void)animateAppearance {
    if (self.headerView == self.contentView) {
        CGRect endRect = self.textView.frame;
        CGRect startRect = endRect;
        startRect.origin.y = CGRectGetMinY(self.titleLabel.frame);
        self.textView.frame = startRect;
        
        self.textView.alpha = 0.0;
        [UIView animateWithDuration:0.8 delay:0.3 usingSpringWithDamping:0.5 initialSpringVelocity:0.0 options:0 animations:^{
            self.textView.alpha = 1.0;
            self.textView.frame = endRect;
        } completion:nil];
    }
}

#pragma mark - Header

- (void)setHeaderView:(UIView *)headerView animated:(BOOL)animated {
    if (!headerView) {
        headerView = (self.goalReason.length == 0) ? self.placeholderView : self.contentView;
    }
    _headerView = headerView;
    [self updateHeaderViewHeightAnimated:animated];
}

- (void)updateHeaderViewHeightAnimated:(BOOL)animated {
    if (self.headerView == self.contentView) {
        CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, CGFLOAT_MAX)];
        self.textViewHeightConstraint.constant = size.height;
    }
    CGRect rect = self.headerView.frame;
    CGFloat height = [self.headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    rect.size.height = ceilf(height);
    self.headerView.frame = rect;
    
    if (animated) [self.tableView beginUpdates];
    self.tableView.tableHeaderView = self.headerView;
    if (animated) [self.tableView endUpdates];
}

#pragma mark - Actions

- (IBAction)tappedPlaceholder:(id)sender {
    [self setHeaderView:self.contentView animated:YES];
    [self.textView becomeFirstResponder];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateHeaderViewHeightAnimated:NO];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.goalReason = textView.text;
    [self setHeaderView:nil animated:YES];
}

#pragma mark - Model

- (NSString *)goalReason {
    if (!_goalReason) {
        _goalReason = [self.userDefaults objectForKey:PXGoalReasonKey];
    }
    return _goalReason;
}

- (void)setGoalReason:(NSString *)goalReason {
    _goalReason = goalReason;
    [self.userDefaults setObject:goalReason forKey:PXGoalReasonKey];
    [self.userDefaults synchronize];
    
    PFObject *object = [PFObject objectWithClassName:@"PXGoalReason"];
    object[@"user"] = [PFUser currentUser];
    object[@"reason"] = goalReason;
    [object saveEventually];
}

@end
