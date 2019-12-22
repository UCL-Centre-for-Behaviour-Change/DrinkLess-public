//
//  PXGaugeView.h
//  Gauge
//
//  Created by Edward Warrender on 18/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXInfographicView.h"

@protocol PXGaugeViewDelegate;

@interface PXGaugeView : PXInfographicView

@property (strong, nonatomic) NSArray *percentileZones;
@property (nonatomic) CGFloat estimate;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, weak) id <PXGaugeViewDelegate> delegate;

/** Used in gauge on AuditHistoryVC for the previous assesment */
@property (nonatomic) BOOL secondaryPercentileEnabled;
@property (nonatomic) float secondaryPercentile;

+ (CGFloat)heightForWidth:(CGFloat)width;

@end

@protocol PXGaugeViewDelegate <NSObject>

- (void)gaugeValueChanged:(PXGaugeView *)gaugeView;

@end
