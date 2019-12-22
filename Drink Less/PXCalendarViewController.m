
//
//  PXCalendarViewController.m
//  drinkless
//
//  Created by Edward Warrender on 12/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCalendarViewController.h"
#import "PXCalendarView.h"
#import "PXDrinkRecordListVC.h"
#import "PXGoalCalculator.h"
#import "PXCoreDataManager.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXGroupsManager.h"
#import "UIViewController+Swipe.h"
#import "PXCalendarStatistics.h"
#import "PXInfoViewController.h"

@interface PXCalendarViewController () <PXCalendarViewDataSourceDelegate>

@property (weak, nonatomic) IBOutlet PXCalendarView *calendarView;
@property (weak, nonatomic) IBOutlet UIView *noRecordsKeyView;
@property (weak, nonatomic) IBOutlet UIView *alcoholFreeKeyView;
@property (weak, nonatomic) IBOutlet UIView *drankKeyView;
@property (weak, nonatomic) IBOutlet UIView *heavyDrinkingKeyView;
@property (weak, nonatomic) IBOutlet UILabel *totalFreeDaysLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *freeDaysHeightContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyHeightContraint;




@property (strong, nonatomic) PXCalendarStatistics *calendarStatistics;
@property (strong, nonatomic) NSDate *selectedDate;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (nonatomic, getter=isHigh) BOOL high;

@end

@implementation PXCalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Calendar";
    
    self.noRecordsKeyView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.alcoholFreeKeyView.backgroundColor = [UIColor drinkLessGreenColor];
    self.drankKeyView.backgroundColor = [UIColor barOrange];
    self.heavyDrinkingKeyView.backgroundColor = [UIColor goalRedColor];
    self.totalFreeDaysLabel.textColor = [UIColor drinkLessGreenColor];
    
    self.context = [PXCoreDataManager sharedManager].managedObjectContext;
    
    __weak typeof(self) weakSelf = self;
    [self addSwipeWithCallback:^(UISwipeGestureRecognizerDirection direction) {
        if (direction == UISwipeGestureRecognizerDirectionLeft) {
            [weakSelf.calendarView increaseMonth];
        } else if (direction == UISwipeGestureRecognizerDirectionRight) {
            [weakSelf.calendarView decreaseMonth];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.high = [PXGroupsManager sharedManager].highSM.boolValue;
    BOOL hasZeroDays = NO;
    if (self.isHigh) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXAlcoholFreeRecord"];
        NSUInteger freeDays = [self.context executeFetchRequest:fetchRequest error:nil].count;
        if (freeDays > 0) {
            hasZeroDays = YES;
            self.totalFreeDaysLabel.text = [NSString stringWithFormat:@"That makes %lu alcohol free %@ so far", (long unsigned)freeDays, freeDays == 1 ? @"day" : @"days"];
        }
    }
    self.freeDaysHeightContraint.constant = self.isHigh && hasZeroDays ? 44.0 : 0.0;
    self.keyHeightContraint.constant = self.isHigh ? 44.0 : 0.0;
    
    [self.calendarView reloadData];
}

#pragma mark - PXCalendarViewDataSourceDelegate

- (NSDate *)calendarSelectedDate {
    return [NSDate date];
}

- (void)calendarWillDisplayFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    self.calendarStatistics = [PXCalendarStatistics calculateFromDate:fromDate toDate:toDate];
}

- (UIColor *)calendarColorForDate:(NSDate *)date {
    PXDayStatus status = [self.calendarStatistics statusForDate:date];
    if (status == PXDayStatusNoRecords) {
        if (date.timeIntervalSinceNow <= 0.0) {
            return [UIColor colorWithWhite:0.9 alpha:1.0];
        }
    } else {
        if (!self.isHigh) {
            return [UIColor drinkLessOrangeColor];
        } else {
            switch (status) {
                case PXDayStatusAlcoholFree:
                    return [UIColor drinkLessGreenColor];
                case PXDayStatusDrank:
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-textured-colours"]) {
                        return [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-orange"]];// [UIColor barOrange];
                    } else {
                        return [UIColor barOrange];
                    }
                case PXDayStatusHeavyDrinking:
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-textured-colours"]) {
                        return [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-red"]];//[UIColor goalRedColor];
                    } else {
                        return [UIColor goalRedColor];
                    }
                default:
                    break;
            }
        }
    }
    return [UIColor whiteColor];
}

- (void)calendarDidSelectDate:(NSDate *)date {
    // @HKS: Is this ok wrt the time zone???
    
    //if (date.timeIntervalSinceNow <= 0.0) {
        self.selectedDate = date;
        [self performSegueWithIdentifier:@"showRecords" sender:nil];
    //}
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showRecords"]) {
        PXDrinkRecordListVC *drinkRecordListVC = (PXDrinkRecordListVC *)segue.destinationViewController;
        drinkRecordListVC.context = self.context;
        drinkRecordListVC.date = self.selectedDate;
    }
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"calendar" fromViewController:self];
}

@end
