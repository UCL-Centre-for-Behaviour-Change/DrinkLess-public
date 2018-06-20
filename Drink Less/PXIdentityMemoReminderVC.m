//
//  PXIdentityMemoReminderVC.m
//  drinkless
//
//  Created by Chris on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityMemoReminderVC.h"

@interface PXIdentityMemoReminderVC ()

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *toggleSwitch;

@end

@implementation PXIdentityMemoReminderVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(leave)];
    }
    if (self.existingReminder) {
        self.memoReminderType = self.existingReminder.reminderType;
        self.datePicker.date = self.existingReminder.reminderDate;
        self.toggleSwitch.on = self.existingReminder.isOn;
    }
    
    self.tableView.rowHeight = 44.0;
    self.datePicker.minimumDate = [NSDate date];
    [self toggleChanged:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Record memo"];
}

- (IBAction)toggleChanged:(id)sender {
    self.statusLabel.text = self.toggleSwitch.isOn ? @"Reminder On" : @"Reminder Off";
}

- (IBAction)tappedSaveButton:(id)sender {
    if (self.existingReminder) {
        self.existingReminder.reminderDate = self.datePicker.date;
        self.existingReminder.isOn = self.toggleSwitch.on;
        [[PXMemoManager sharedInstance] save];
    } else {
        [[PXMemoManager sharedInstance] addMemoReminder:self.datePicker.date memoReminderType:self.memoReminderType isOn:self.toggleSwitch.on];
    }
    [self leave];
}

- (void)leave {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.memoReminderType == PXMemoReminderRecordType) {
        return @"Set a reminder to record a video";
    }
    if (self.memoReminderType == PXMemoReminderWatchType) {
        return @"Set a reminder to watch a video";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:16.0];
        headerView.textLabel.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
        headerView.textLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1.0];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0;
}

@end
