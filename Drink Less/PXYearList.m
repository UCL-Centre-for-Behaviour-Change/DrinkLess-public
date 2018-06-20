//
//  PXDateList.m
//  Drink Less
//
//  Created by Chris Pritchard on 04/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXYearList.h"

static NSInteger const minimumAge = 16;

@interface PXYearList ()

@property (nonatomic) NSInteger currentYear;

@end

@implementation PXYearList

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    self.currentYear = components.year - minimumAge;
    
    [self highlightSelectedYear];
}

- (void)highlightSelectedYear {
    if (self.selectedYear == 0) {
        return;
    }
    
    NSIndexPath* selectedPath = [NSIndexPath indexPathForRow:(self.currentYear - self.selectedYear) inSection:0];
    [self.tableView scrollToRowAtIndexPath:selectedPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YearCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"YearCell"];
    }
    
    NSInteger year = self.currentYear - indexPath.row;
    
    cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)year];
    
    if (self.selectedYear == year) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger year = self.currentYear - indexPath.row;
    [self.delegate yearList:self chosenYear:year];
}

@end
