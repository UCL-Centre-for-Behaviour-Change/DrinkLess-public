//
//  PXCalculatorView.m
//  drinkless
//
//  Created by Chris Pritchard on 22/05/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCalendarView.h"
#import "PXCalendarDateButton.h"
#import "NSDate+DrinkLess.h"

static const CGFloat chosenMonthYearHeight = 44.0;
static const CGFloat weekdayHeight = 35.0;
static const CGFloat dayHeight = 55.0;
static const CGFloat progressHeight = 6.0;

@interface PXCalendarView ()

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *lineView;
@property (strong, nonatomic) UILabel *chosenMonthYearLabel;
@property (strong, nonatomic) UIButton *leftButton;
@property (strong, nonatomic) UIButton *rightButton;
@property (strong, nonatomic) UIButton *lastDayButton;
@property (strong, nonatomic) NSArray *dayStrings;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableArray *dayLabels;
@property (strong, nonatomic) NSMutableArray *dateButtonsArray;
@property (nonatomic) NSInteger chosenMonth;
@property (nonatomic) NSInteger chosenYear;
@property (nonatomic) CGSize boundsSize;

@end

@implementation PXCalendarView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialConfiguration];
}

- (void)initialConfiguration {
    self.clipsToBounds = YES;
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.contentView];
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    self.chosenMonth = dateComponents.month;
    self.chosenYear = dateComponents.year;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    self.dayStrings = @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun"];
    
    CGFloat yPosition = 0;
    CGFloat colWidth = self.bounds.size.width/self.dayStrings.count;
    
    self.dateButtonsArray = [[NSMutableArray alloc] init];
    
    self.chosenMonthYearLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, yPosition, self.frame.size.width, chosenMonthYearHeight)];
    self.chosenMonthYearLabel.textAlignment = NSTextAlignmentCenter;
    self.chosenMonthYearLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
    self.chosenMonthYearLabel.adjustsFontSizeToFitWidth = YES;
    self.chosenMonthYearLabel.minimumScaleFactor = 0.5;
    self.chosenMonthYearLabel.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.chosenMonthYearLabel.textColor = [UIColor blackColor];
    self.chosenMonthYearLabel.userInteractionEnabled = YES;
    self.chosenMonthYearLabel.text = @"May 2014";
    [self.contentView addSubview:self.chosenMonthYearLabel];
    
    yPosition += self.chosenMonthYearLabel.frame.size.height;
    
    self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.leftButton setImage:[UIImage imageNamed:@"calendarLeftArrow"] forState:UIControlStateNormal];
    [self.leftButton addTarget:self action:@selector(didTapLeft) forControlEvents:UIControlEventTouchUpInside];
    [self.chosenMonthYearLabel addSubview:self.leftButton];
    
    self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightButton setImage:[UIImage imageNamed:@"calendarRightArrow"] forState:UIControlStateNormal];
    [self.rightButton addTarget:self action:@selector(didTapRight) forControlEvents:UIControlEventTouchUpInside];
    [self.chosenMonthYearLabel addSubview:self.rightButton];
    
    self.dayLabels = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.dayStrings.count; i++) {
        UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(i*colWidth, yPosition, colWidth, weekdayHeight)];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        dayLabel.adjustsFontSizeToFitWidth = YES;
        dayLabel.minimumScaleFactor = 0.5;
        dayLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        dayLabel.text = self.dayStrings[i];
        dayLabel.tag = i;
        [self.contentView addSubview:dayLabel];
        [self.dayLabels addObject:dayLabel];
    }
    
    yPosition += weekdayHeight;
    
    CGFloat pixel = 1.0 / [UIScreen mainScreen].scale;
    self.lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, yPosition, self.frame.size.width, pixel)];
    self.lineView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    [self.contentView addSubview:self.lineView];
    
    for (NSInteger i = 0; i < 6; i++) {
        for (NSInteger j = 0; j < 7; j++) {
            PXCalendarDateButton *button = [PXCalendarDateButton buttonWithType:UIButtonTypeCustom];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.minimumScaleFactor = 0.5;
            button.iCoord = i;
            button.jCoord = j;
            [button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.dateButtonsArray addObject:button];
            [self.contentView addSubview:button];
            
            button.progressView = [[UIView alloc] init];
            button.progressView.backgroundColor = [UIColor lightGrayColor];
            [button addSubview:button.progressView];
            
            button.selectedView = [[UIView alloc] init];
            button.selectedView.userInteractionEnabled = NO;
            button.selectedView.backgroundColor = [UIColor colorWithWhite:0.57 alpha:1.0];
            button.selectedView.clipsToBounds = YES;
            [button insertSubview:button.selectedView belowSubview:button.titleLabel];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.bounds.size, self.boundsSize)) {
        self.boundsSize = self.bounds.size;
        
        CGFloat yPosition = 0;
        CGFloat colWidth = self.bounds.size.width/self.dayStrings.count;
        
        self.chosenMonthYearLabel.frame = CGRectMake(0.0, yPosition, self.frame.size.width, chosenMonthYearHeight);
        
        self.leftButton.frame = CGRectMake(0.0, yPosition, 44.0, chosenMonthYearHeight);
        self.rightButton.frame = CGRectMake((self.frame.size.width-44.0), yPosition, 44.0, chosenMonthYearHeight);
        
        yPosition += chosenMonthYearHeight;
        
        for (UILabel *label in self.dayLabels) {
            label.frame = CGRectMake(label.tag*colWidth, yPosition, colWidth, weekdayHeight);
        }
        
        yPosition += weekdayHeight;
        
        CGFloat pixel = 1.0 / [UIScreen mainScreen].scale;
        self.lineView.frame = CGRectMake(0.0, yPosition, self.frame.size.width, pixel);
        
        CGFloat buttonXOffset = 0;
        for (PXCalendarDateButton *button in self.dateButtonsArray) {
            button.frame = CGRectMake((colWidth*button.jCoord)+buttonXOffset, (dayHeight*button.iCoord)+yPosition, colWidth, dayHeight);
            button.progressView.frame = CGRectMake(pixel, button.frame.size.height-progressHeight, button.frame.size.width-(pixel  *2.0), progressHeight);
            button.selectedView.frame = CGRectMake(0.0, 0.0, button.frame.size.width*0.65, button.frame.size.width*0.65);
            button.selectedView.layer.cornerRadius = (button.selectedView.frame.size.width/2);
            button.selectedView.center = CGPointMake(button.frame.size.width/2, button.frame.size.height/2);
        }
        
        CGSize size = self.frame.size;
        size.height = CGRectGetMaxY(self.lastDayButton.frame);
        self.contentView.frame = (CGRect){CGPointZero, size};
        self.contentSize = size;
    }
}

- (void)reloadData {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 1;
    dateComponents.month = self.chosenMonth;
    dateComponents.year = self.chosenYear;
    
    if ([self.dataSourceDelegate respondsToSelector:@selector(calendarWillDisplayFromDate:toDate:)]) {
        NSDate *fromDate = [calendar dateFromComponents:dateComponents];
        NSDateComponents *oneMonthComponent = [[NSDateComponents alloc] init];
        oneMonthComponent.month = 1;
        NSDate *toDate = [calendar dateByAddingComponents:oneMonthComponent toDate:fromDate options:0];
        [self.dataSourceDelegate calendarWillDisplayFromDate:fromDate toDate:toDate];
    }
    
    NSInteger dayDate = 1;
    NSRange daysInMonthRange = [calendar rangeOfUnit:NSCalendarUnitDay
                                              inUnit:NSCalendarUnitMonth
                                             forDate:[calendar dateFromComponents:dateComponents]];
    
    NSInteger daysInMonth = daysInMonthRange.length;
    NSInteger firstWeekday = [self firstWeekdayIndexForMonth:self.chosenMonth];
    
    for (NSInteger i = 0; i < self.dateButtonsArray.count; i++) {
        PXCalendarDateButton *dateButton = self.dateButtonsArray[i];
        dateButton.selectedView.hidden = YES;
        [dateButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        if (i < firstWeekday) {
            dateButton.tag = 0;
            [dateButton setTitle:@"" forState:UIControlStateNormal];
            dateButton.progressView.hidden = YES;
        } else {
            if (dayDate <= daysInMonth) {
                self.lastDayButton = dateButton;
                dateButton.tag = dayDate;
                [dateButton setTitle:[NSString stringWithFormat:@"%li", (long)dayDate] forState:UIControlStateNormal];
                
                NSDate *date = [NSDate dateFromComponentDay:dayDate month:self.chosenMonth year:self.chosenYear];
                UIColor *color;
                if ([self.dataSourceDelegate respondsToSelector:@selector(calendarColorForDate:)]) {
                    color = [self.dataSourceDelegate calendarColorForDate:date];
                } else {
                    color = [UIColor whiteColor];
                }
                dateButton.progressView.backgroundColor = color;
                dateButton.progressView.hidden = NO;
                
                if ([self.dataSourceDelegate respondsToSelector:@selector(calendarSelectedDate)]) {
                    if ([NSDate isDate:[self.dataSourceDelegate calendarSelectedDate] sameDayAsDate:date]) {
                        dateButton.selectedView.hidden = NO;
                        [dateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    }
                }
                dayDate++;
            } else {
                dateButton.tag = 0;
                [dateButton setTitle:@"" forState:UIControlStateNormal];
                dateButton.progressView.hidden = YES;
            }
        }
    }
    
    NSString *dateString = [NSString stringWithFormat: @"%ld", (long)self.chosenMonth];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"MM"];
    NSDate *myDate = [self.dateFormatter dateFromString:dateString];
    [self.dateFormatter setDateFormat:@"MMMM"];
    NSString *stringFromDate = [self.dateFormatter stringFromDate:myDate];
    
    self.chosenMonthYearLabel.text = [NSString stringWithFormat:@"%@ %li", stringFromDate, (long)self.chosenYear];
    
    self.boundsSize = CGSizeZero;
    [self setNeedsLayout];
}

- (NSInteger)firstWeekdayIndexForMonth:(NSInteger)monthIndex {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger firstWeekDay = 2;
    [calendar setFirstWeekday:firstWeekDay];
    NSDateComponents *weekdayComps = [[NSDateComponents alloc] init];
    weekdayComps.day = 1;
    weekdayComps.month = monthIndex;
    weekdayComps.year = self.chosenYear;
    
    //get weekday index
    NSDate *weekDate = [calendar dateFromComponents:weekdayComps];
    NSDateComponents *components = [calendar components: NSCalendarUnitWeekday fromDate: weekDate];
    NSInteger weekdayIndex = [components weekday] - firstWeekDay;
    if (weekdayIndex < 0) {
        weekdayIndex = 7 + weekdayIndex;
    }
    return weekdayIndex;
}

- (void)didTapLeft {
    self.chosenMonth--;
    if (self.chosenMonth <= 0) {
        self.chosenMonth = 12;
        self.chosenYear--;
    }
    
    [self reloadData];
}

- (void)didTapRight {
    self.chosenMonth++;
    if (self.chosenMonth > 12) {
        self.chosenMonth = 1;
        self.chosenYear++;
    }
    
    [self reloadData];
}

- (void)didTapButton:(UIButton *)dateButton {
    if ([self.dataSourceDelegate respondsToSelector:@selector(calendarDidSelectDate:)]) {
        NSInteger dayDate = dateButton.tag;
        NSDate *date = [NSDate dateFromComponentDay:dayDate month:self.chosenMonth year:self.chosenYear];
        [self.dataSourceDelegate calendarDidSelectDate:date];
    }
}

- (void)decreaseMonth {
    if (self.leftButton.enabled) {
        [self didTapLeft];
    }
}

- (void)increaseMonth {
    if (self.rightButton.enabled) {
        [self didTapRight];
    }
}

@end
