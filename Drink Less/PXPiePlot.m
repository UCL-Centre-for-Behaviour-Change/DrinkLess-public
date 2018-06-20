//
//  PXPiePlot.m
//  drinkless
//
//  Created by Edward Warrender on 24/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPiePlot.h"

NSString *const PXValueKey = @"value";

@interface PXPiePlot () <CPTPieChartDataSource>

@property (strong, nonatomic) CPTPlotSpaceAnnotation *symbolTextAnnotation;
@property (nonatomic) CGFloat sumOfValues;

@end

@implementation PXPiePlot

- (void)setPlotData:(NSArray *)plotData {
    self.legendHidden = NO;
    [super setPlotData:plotData];
    
    [self reloadData];
}

- (void)reloadData {
    self.sumOfValues = 0.0;
    for (NSDictionary *dictionary in self.plotData) {
        self.sumOfValues += [dictionary[PXValueKey] floatValue];
    }
    [self.graph reloadData];
    
    [self updateLegendWithCount:self.plotData.count];
    [self.hostingView layoutIfNeeded];
    [self updateLayout];
}

- (void)updateLayout {
    CGRect bounds = self.hostingView.bounds;
    CPTPieChart *piePlot = self.graph.allPlots.firstObject;
    piePlot.pieRadius = (bounds.size.height - self.graph.plotAreaFrame.paddingTop - self.graph.plotAreaFrame.paddingBottom) / 2.0;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"value > 0"];
    NSInteger nonZeroValues = [self.plotData filteredArrayUsingPredicate:predicate].count;
    piePlot.labelOffset = nonZeroValues == 1 ? -piePlot.pieRadius : piePlot.pieRadius * -0.4;
}

- (void)setupGraph {
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    self.hostingView.hostedGraph = self.graph;
    
    self.graph.paddingTop = 0.0;
    self.graph.paddingRight = 0.0;
    self.graph.paddingBottom = 0.0;
    self.graph.paddingLeft = 0.0;
    
    self.graph.plotAreaFrame.paddingTop = 15.0;
    self.graph.plotAreaFrame.paddingRight = 0.0;
    self.graph.plotAreaFrame.paddingBottom = 15.0;
    self.graph.plotAreaFrame.paddingLeft = 0.0;
    
    self.graph.plotAreaFrame.masksToBorder = NO;
    self.graph.axisSet                     = nil;

    CPTPieChart *piePlot = [[CPTPieChart alloc] init];
    piePlot.dataSource = self;
    piePlot.startAngle     = M_PI_2;
    piePlot.sliceDirection = CPTPieDirectionCounterClockwise;
    piePlot.labelRotationRelativeToRadius = NO;
    piePlot.labelRotation                 = 0.0;
    [self.graph addPlot:piePlot];
    
    self.paddingBottomOffset = 20.0;
    [self setupLegend];
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index {
    static CPTMutableTextStyle *whiteText = nil;

    if (!whiteText) {
        whiteText = [[CPTMutableTextStyle alloc] init];
        whiteText.fontName = @"Helvetica";
        whiteText.fontSize = 12.0;
        whiteText.color = [CPTColor whiteColor];
    }

    NSDictionary *dictionary = self.plotData[index];
    NSNumber *value = dictionary[PXValueKey];
    CGFloat percentage = (value.floatValue / self.sumOfValues) * 100.0;
    if (percentage == 0.0) {
        return nil;
    }
    CPTTextLayer *newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.f%%", percentage] style:whiteText];
    return newLayer;
}

#pragma mark - CPTPlotDataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return self.plotData.count;
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    if (fieldEnum == CPTPieChartFieldSliceWidth) {
        NSDictionary *dictionary = self.plotData[index];
        return dictionary[PXValueKey];
    }
    return nil;
}

#pragma mark - CPTPieChartDataSource

- (CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx {
    NSDictionary *dictionary = self.plotData[idx];
    UIColor *color = dictionary[PXColorKey];
    return [CPTFill fillWithColor:[CPTColor colorWithCGColor:color.CGColor]];
}

- (NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx {
    NSDictionary *dictionary = self.plotData[idx];
    return dictionary[PXTitleKey];
}

@end
