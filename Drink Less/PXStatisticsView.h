//
//  PXStatisticsView.h
//  drinkless
//
//  Created by Edward Warrender on 23/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXAllStatistics.h"

@interface PXStatisticsView : UIView

@property (strong, nonatomic) PXAllStatistics *allStatistics;
@property (nonatomic) PXConsumptionType consumptionType;

@end
