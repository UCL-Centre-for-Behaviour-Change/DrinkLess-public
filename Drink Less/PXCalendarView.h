//
//  PXCalculatorView.h
//  drinkless
//
//  Created by Chris Pritchard on 22/05/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXCalendarViewDataSourceDelegate;

@class PXCalendarView;

@interface PXCalendarView : UIScrollView

@property (weak, nonatomic) IBOutlet id <PXCalendarViewDataSourceDelegate> dataSourceDelegate;

- (void)reloadData;
- (void)decreaseMonth;
- (void)increaseMonth;

@end

@protocol PXCalendarViewDataSourceDelegate <NSObject>

@optional
- (NSDate *)calendarSelectedDate;
- (UIColor *)calendarColorForDate:(NSDate *)date;
- (void)calendarWillDisplayFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
- (void)calendarDidSelectDate:(NSDate *)date;

@end
