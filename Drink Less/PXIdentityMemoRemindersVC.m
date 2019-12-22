//
//  PXIdentityMemoRemindersVC.m
//  drinkless
//
//  Created by Chris Pritchard on 25/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityMemoRemindersVC.h"
#import "PXIdentityMemoReminderVC.h"
#import "drinkless-Swift.h"

@interface PXIdentityMemoRemindersVC ()

@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@end

@implementation PXIdentityMemoRemindersVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Memos menu"];
}

- (PXMemoReminderType)memoReminderTypeForSection:(NSInteger)section {
    if (section == 0) {
        return PXMemoReminderRecordType;
    } else if (section == 1) {
        return PXMemoReminderWatchType;
    }
    return NSNotFound;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    PXMemoReminderType reminderType = [self memoReminderTypeForSection:indexPath.section];
    
    if ([segue.identifier isEqualToString:@"addReminder"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PXIdentityMemoReminderVC *reminderVC = (PXIdentityMemoReminderVC *)navigationController.topViewController;
        reminderVC.memoReminderType = reminderType;
    }
    else if ([segue.identifier isEqualToString:@"editReminder"]) {
        PXIdentityMemoReminderVC *reminderVC = segue.destinationViewController;
        PXMemoReminder *reminder = [[PXMemoManager sharedInstance] memoReminderAtIndex:indexPath.row - 1 forType:reminderType];
        reminderVC.existingReminder = reminder;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Record Memos";
    } else if (section == 1) {
        return @"Watch Memos";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PXMemoManager sharedInstance] numberOfMemoRemindersForType:[self memoReminderTypeForSection:section]] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXMemoReminderType reminderType = [self memoReminderTypeForSection:indexPath.section];
    BOOL isButton = (indexPath.row == 0);
    if (isButton) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addCell" forIndexPath:indexPath];
        cell.textLabel.textColor = self.tableView.tintColor;
        if (reminderType == PXMemoReminderRecordType) {
            cell.textLabel.text = @"Add Record Memo Reminder";
        } else if (reminderType == PXMemoReminderWatchType){
            cell.textLabel.text = @"Add Watch Memo Reminder";
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailCell" forIndexPath:indexPath];
        PXMemoReminder *reminder = [[PXMemoManager sharedInstance] memoReminderAtIndex:indexPath.row - 1 forType:reminderType];
        cell.textLabel.text = [self.dateFormatter stringFromDate:reminder.reminderDate];
        cell.detailTextLabel.text = reminder.isOn ? @"On" : @"Off";
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isButton = (indexPath.row == 0);
    return !isButton;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[PXMemoManager sharedInstance] removeMemoReminderAtIndex:indexPath.row - 1 forType:[self memoReminderTypeForSection:indexPath.section]];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
