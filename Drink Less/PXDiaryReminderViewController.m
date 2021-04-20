//
//  PXDiaryReminderViewController.m
//  drinkless
//
//  Created by Edward on 13/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDiaryReminderViewController.h"
#import "PXLocalNotificationsManager.h"
#import "drinkless-Swift.h"

@interface PXDiaryReminderViewController ()

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *toggleSwitch;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) NSDate *oldReminderDate;
@property (nonatomic) BOOL wasReminderOn;

@end

@implementation PXDiaryReminderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.wasReminderOn = [[self.userDefaults objectForKey:PXConsumptionReminderType] boolValue];
    self.oldReminderDate = [self.userDefaults objectForKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
    
    self.toggleSwitch.on = self.wasReminderOn;
    if (self.oldReminderDate) {
        self.datePicker.date = self.oldReminderDate;
    }
    
    self.tableView.rowHeight = 44.0;

    [self toggleChanged:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Reminder"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.toggleSwitch.enabled = YES;
    BOOL isReminderOn = self.toggleSwitch.on;
    NSDate *newReminderDate = self.datePicker.date;
    BOOL hasChanged = isReminderOn != self.wasReminderOn || ![newReminderDate isEqualToDate:self.oldReminderDate];
    
    if (hasChanged) {
        [self.userDefaults setValue:@(isReminderOn) forKey:PXConsumptionReminderType];
        [self.userDefaults setValue:newReminderDate forKey:KEY_USERDEFAULTS_REMINDERS_CONSUMPTION_TIME];
        [self.userDefaults synchronize];
        [[PXLocalNotificationsManager sharedInstance] updateConsumptionReminder];
    }
    
}

#pragma mark - Action

- (IBAction)toggleChanged:(id)sender {
    self.statusLabel.text = self.toggleSwitch.isOn ? @"Reminder On" : @"Reminder Off";
}

#pragma mark - UITableViewDataSource

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
