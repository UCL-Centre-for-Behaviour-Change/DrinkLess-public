//
//  InsightsLastWeekGraphView.h
//  drinkless
//
//  Created by Hari Karam Singh on 29/10/2019.
//  Copyright © 2019 UCL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PXAllStatistics.h"

NS_ASSUME_NONNULL_BEGIN


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

typedef enum : NSUInteger {
    InsightsAverageWeekGraphRange1Month,
    InsightsAverageWeekGraphRange3Months,
    InsightsAverageWeekGraphRange6Months,
    InsightsAverageWeekGraphRange1Year,
    InsightsAverageWeekGraphRangeLifetime
} InsightsAverageWeekGraphRange;

@class InsightsGraphHostingView;

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

@interface InsightsAverageWeekGraphView : UIView

@property (nonatomic) InsightsAverageWeekGraphRange graphRange;
@property (nonatomic, strong) PXAllStatistics *allStats;
@property (nonatomic) CGFloat drinkUnitsAverage; /** Determines the dashed line placement on the latest section of the graph */
@property (nonatomic) CGFloat alcFreeDaysAverage;

@property (nonatomic, strong) InsightsGraphHostingView *hostingView;


- (void)redraw;

+ (NSUInteger)viewRangeInWeeksForTimeRange:(InsightsAverageWeekGraphRange)timeRange;

@end

NS_ASSUME_NONNULL_END
