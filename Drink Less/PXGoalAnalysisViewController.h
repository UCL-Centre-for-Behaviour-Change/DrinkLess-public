//
//  PXGoalAnalysisViewController.h
//  drinkless
//
//  Created by Edward Warrender on 24/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXGoalProgress, PXGoalStatistics;

typedef NS_ENUM(NSInteger, PXAnalysisType) {
    PXAnalysisTypeOverview = 0,
    PXAnalysisTypeTime,
    PXAnalysisTypeScores
};

@interface PXGoalAnalysisViewController : PXTrackedViewController

- (instancetype)initWithAnalysisType:(PXAnalysisType)analysisType;

@property (strong, nonatomic) PXGoalStatistics *goalStatistics;

- (void)updateFigures;

@end
