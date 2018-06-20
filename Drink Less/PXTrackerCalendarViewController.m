//
//  PXTrackerCalendarViewController.m
//  drinkless
//
//  Created by Edward Warrender on 08/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackerCalendarViewController.h"
#import "PXCalendarView.h"
#import "UIViewController+Swipe.h"

@interface PXTrackerCalendarViewController () <PXCalendarViewDataSourceDelegate>

@property (weak, nonatomic) IBOutlet PXCalendarView *calendarView;

@end

@implementation PXTrackerCalendarViewController

@synthesize panelViewController = _panelViewController;
@synthesize referenceDate = _referenceDate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    [self addSwipeWithCallback:^(UISwipeGestureRecognizerDirection direction) {
        if (direction == UISwipeGestureRecognizerDirectionLeft) {
            [weakSelf.calendarView increaseMonth];
        } else if (direction == UISwipeGestureRecognizerDirectionRight) {
            [weakSelf.calendarView decreaseMonth];
        }
    }];
}

#pragma mark - Properties

- (void)setReferenceDate:(NSDate *)referenceDate {
    _referenceDate = referenceDate;
    
    [self.calendarView reloadData];
}

#pragma mark - PXCalendarViewDataSourceDelegate

- (NSDate *)calendarSelectedDate {
    return self.referenceDate;
}

- (void)calendarDidSelectDate:(NSDate *)date {
    if (date.timeIntervalSinceNow <= 0.0) {
        self.panelViewController.referenceDate = date;
        self.panelViewController.datePicking = NO;
    }
}

@end
