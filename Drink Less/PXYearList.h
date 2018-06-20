//
//  PXDateList.h
//  Drink Less
//
//  Created by Chris Pritchard on 04/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXYearList;

@protocol PXYearListDelegate <NSObject>
- (void)yearList:(PXYearList*)dateList chosenYear:(NSInteger)year;
@end

@interface PXYearList : UITableViewController

- (void)highlightSelectedYear;

@property (nonatomic, assign) id <PXYearListDelegate> delegate;
@property (nonatomic, strong) NSIndexPath* cellIndexPath;
@property (nonatomic) NSInteger selectedYear;

@end
