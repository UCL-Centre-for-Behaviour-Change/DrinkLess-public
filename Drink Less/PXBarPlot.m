//
//  PXBarPlot.m
//  drinkless
//
//  Created by Edward Warrender on 02/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXBarPlot.h"
#import "PXAllStatistics.h"
#import "PXCPTBarPlot.h"
#import "PXDebug.h"

NSString *const PXDateKey        = @"date";
NSString *const PXSpecialDateKey = @"specialDate";
NSString *const PXPlotIdentifier = @"plotIdentifier";
NSString *const PXDefaultPlotIdentifier = @"Default";

static NSString *const PXMarkerIdentifier = @"Marker";
static CGFloat const PXMarginTicksX = 0.5;
static CGFloat const PXMarginLengthX = PXMarginTicksX * 2.0;
static NSUInteger const PXVisibleTicksX = 7;
static NSUInteger const PXVisibleTicksY = 10;
static NSUInteger const PXSuggestedWeeklyUnits = 14;

@interface PXBarPlot () <CPTPlotAreaDelegate, CPTBarPlotDataSource, CPTPlotSpaceDelegate, CPTPlotDataSource, CPTBarPlotDelegate>

@property (strong, nonatomic) NSMutableDictionary *maxCoordinateRanges;
@property (strong, nonatomic) NSString *xTitle;
@property (strong, nonatomic) NSString *yTitle;
@property (strong, nonatomic) NSObject *xKey;
@property (strong, nonatomic) NSObject *yKey;
@property (nonatomic) CGFloat minYValue;
@property (nonatomic) CGFloat maxYValue;
@property (nonatomic) CGFloat goalValue;
@property (nonatomic) BOOL displayAsPercentage;
@property (nonatomic) PXAxisTypeX axisTypeX;

@end

@implementation PXBarPlot

- (void)reloadData {
    [self configureXAxis];
    [self configureYAxis];
    [self.graph reloadData];
    [self updateLegendWithCount:self.plots.count];
}

- (instancetype)initWithHostingView:(CPTGraphHostingView *)hostingView {
    self = [super initWithHostingView:hostingView];
    if (self) {
        _maxCoordinateRanges = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setupGraph {
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    self.hostingView.hostedGraph = self.graph;
    
    self.graph.paddingTop = 0.0;
    self.graph.paddingRight = 0.0;
    self.graph.paddingBottom = 0.0;
    self.graph.paddingLeft = 0.0;
    
    self.graph.plotAreaFrame.paddingTop = 15.0;
    self.graph.plotAreaFrame.paddingRight = 15.0;
    self.graph.plotAreaFrame.paddingBottom = 30.0;
    self.graph.plotAreaFrame.paddingLeft = 45.0;
    self.graph.plotAreaFrame.plotArea.delegate = self;

    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.allowsMomentum        = YES;
    plotSpace.delegate              = self;
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.5;
    majorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.1];
    
    CPTMutableTextStyle *axisTextStyle = [CPTMutableTextStyle textStyle];
    axisTextStyle.color = [CPTColor colorWithCGColor:[UIColor colorWithWhite:0.33 alpha:1.0].CGColor];
    axisTextStyle.fontSize = 11.0;
    
    CPTMutableTextStyle *titleTextStyle = axisTextStyle.mutableCopy;
    titleTextStyle.fontSize = 14.0;
    
    CPTMutableLineStyle *noLineStyle = [CPTMutableLineStyle lineStyle];
    noLineStyle.lineWidth              = 0.0;
    noLineStyle.lineColor              = [CPTColor clearColor];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.orthogonalPosition = @0.0;
    x.minorTicksPerInterval       = 0;
    x.labelTextStyle              = axisTextStyle;
    x.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    x.majorTickLineStyle          = noLineStyle;
    x.labelFormatter              = [[NSNumberFormatter alloc] init];
    x.titleTextStyle = titleTextStyle;
    x.titleOffset = 25.0;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.orthogonalPosition = @0.0;
    y.minorTicksPerInterval       = 0;
    y.majorGridLineStyle          = majorGridLineStyle;
    y.labelTextStyle              = axisTextStyle;
    y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    y.majorTickLineStyle = noLineStyle;
    y.axisLineStyle = noLineStyle;
    y.titleTextStyle = titleTextStyle;
    
//    self.plots = @[@{PXPlotIdentifier: @1,
//                     PXColorKey: [UIColor drinkLessLightGreenColor]}];
}

- (PXCPTBarPlot *)createBarPlot {
    CPTMutableLineStyle *noLineStyle = [CPTMutableLineStyle lineStyle];
    noLineStyle.lineWidth              = 0.0;
    noLineStyle.lineColor              = [CPTColor clearColor];
    
    PXCPTBarPlot *barPlot       = [[PXCPTBarPlot alloc] init];
    barPlot.barWidth          = @0.5;
    barPlot.barCornerRadius   = 0.0;
    barPlot.barsAreHorizontal = NO;
    barPlot.lineStyle         = noLineStyle;
    barPlot.dataSource        = self;
    barPlot.delegate          = self;
    barPlot.isGameBarPlot     = self.isGameBarPlot;
    return barPlot;
}

- (void)setPlots:(NSArray *)plots {
    _plots = plots;
    
    for (CPTPlot *plot in self.graph.allPlots) {
        [self.graph removePlot:plot];
    }
    
    for (NSDictionary *dictionary in plots) {
        PXCPTBarPlot *barPlot = [self createBarPlot];
        barPlot.identifier = dictionary[PXPlotIdentifier];
        UIColor *color = dictionary[PXColorKey];
        barPlot.fill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:color.CGColor]];
        [self.graph addPlot:barPlot];
    }
    [self setupLegend];
    
    CPTScatterPlot *markerLinePlot = [[CPTScatterPlot alloc] init];
    markerLinePlot.identifier      = PXMarkerIdentifier;
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth            = 1.0;
    lineStyle.lineColor            = [[CPTColor blackColor] colorWithAlphaComponent:0.3];
    lineStyle.dashPattern          = @[@5, @4];
    markerLinePlot.dataLineStyle   = lineStyle;
    markerLinePlot.dataSource      = self;
    [self.graph addPlot:markerLinePlot];
}

@synthesize plotData = _plotData;
- (void)setPlotData:(NSArray *)plotData
{
    _plotData = plotData;
    
    // NOTE: This is a default color scheme hack. It really should be down differently but the code of such an entangled mess of non-DRY-ness that this is the best we get for now...  Note, goal graphs have a different colour scheme to the others hence the if statement
    if (!self.plots) {
        UIColor *safeColor = [UIColor drinkLessOrangeColor];//drinkLessGreenColor];
        UIColor *failColor = [UIColor goalRedColor];

        NSMutableArray *plotDicts = NSMutableArray.new;
        for (NSDictionary *dataDict in self.plotData) {
            CGFloat units = [dataDict[@(PXConsumptionTypeUnits)] floatValue];
            // Color red if a goal is set and its been exceeded
            UIColor *barColor;
            CGFloat goal = _goalValue ?: PXSuggestedWeeklyUnits;
            if (units > goal) {
                barColor = failColor;
            } else {
                barColor = safeColor;
            }
            if (dataDict[PXPlotIdentifier]) {
                [plotDicts addObject:@{PXPlotIdentifier:dataDict[PXPlotIdentifier], PXColorKey:barColor}];
            }
        }
        self.plots = plotDicts;
    }
    
}

#pragma mark - Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    
    if ([plot.identifier isEqual:PXMarkerIdentifier]) {
        return 2;
    }
    return self.plotData.count;
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    if ([plot.identifier isEqual:PXMarkerIdentifier]) {
        if (fieldEnum == CPTScatterPlotFieldX) {
            CPTPlotRange *maxRange = self.maxCoordinateRanges[@(CPTScatterPlotFieldX)];
            return @((index == 0) ? maxRange.minLimitDouble : maxRange.maxLimitDouble);
        } else {
            return @(self.goalValue);
        }
    }
    NSDictionary *dictionary = self.plotData[index];
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        NSString *plotIdentifer = dictionary[PXPlotIdentifier];
        if (!plotIdentifer) {
            plotIdentifer = PXDefaultPlotIdentifier;
        }
        if (![plotIdentifer isEqual:plot.identifier]) {
            return nil;
        }
        
        if (fieldEnum == CPTScatterPlotFieldX) {
            if (self.xKey) {
                return dictionary[self.xKey];
            }
        }
        if (fieldEnum == CPTScatterPlotFieldY) {
            if (self.yKey) {
                return dictionary[self.yKey];
            }
        }
    }
    return @(index);
}


#pragma mark - Plot Space Delegate Methods

- (CPTPlotRange *)plotSpace:(CPTXYPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate {
    CPTPlotRange *maxRange = self.maxCoordinateRanges[@(coordinate)];
    CPTMutablePlotRange *changedRange = newRange.mutableCopy;
    [changedRange shiftEndToFitInRange:maxRange];
    [changedRange shiftLocationToFitInRange:maxRange];
    newRange = changedRange;
    return newRange;
}

#pragma mark - Actions

- (void)setXTitle:(NSString *)xTitle yTitle:(NSString *)yTitle xKey:(NSObject *)xKey yKey:(NSObject *)yKey minYValue:(CGFloat)minYValue maxYValue:(CGFloat)maxYValue goalValue:(CGFloat)goalValue displayAsPercentage:(BOOL)displayAsPercentage axisTypeX:(PXAxisTypeX)axisTypeX showLegend:(BOOL)showLegend {
    _xTitle = xTitle;
    _yTitle = yTitle;
    _xKey = xKey;
    _yKey = yKey;
    _minYValue = minYValue;
    _maxYValue = maxYValue;
    _goalValue = goalValue;
    _displayAsPercentage = displayAsPercentage;
    _axisTypeX = axisTypeX;
    self.legendHidden = !showLegend;
    
    CPTPlot *markerLinePlot = [self.graph plotWithIdentifier:PXMarkerIdentifier];
    markerLinePlot.hidden = (_goalValue == 0.0);
    
    self.plotData = self.plotData; // quick hack to redo bar colours when goal is set
    [self reloadData];
}



- (void)configureXAxis {
    self.paddingBottomOffset = self.xTitle ? 55.0 : 30.0;
    self.graph.plotAreaFrame.paddingBottom = self.paddingBottomOffset;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.title = self.xTitle;
    
    if (self.axisTypeX == PXAxisTypeTitle) {
        NSArray *titles = [self.plotData valueForKey:PXTitleKey];
        NSMutableSet *xLabels = [NSMutableSet setWithCapacity:titles.count];
        NSMutableSet *xLocations = [NSMutableSet setWithCapacity:titles.count];
        
        for (NSInteger i = 0; i < titles.count; i++) {
            NSString *title = titles[i];
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:title textStyle:x.labelTextStyle];
            label.tickLocation = @(i);
            label.offset = x.majorTickLength;
            [xLabels addObject:label];
            [xLocations addObject:@(i)];
        }
        x.axisLabels = xLabels;
        x.majorTickLocations = xLocations;
        x.labelingPolicy = CPTAxisLabelingPolicyNone;
    }
    else if (self.axisTypeX == PXAxisTypeDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = self.xAxisDateFormat;
        NSDateFormatter *specialDateFormatter = [[NSDateFormatter alloc] init];
        specialDateFormatter.dateFormat = self.xAxisSpecialDateFormat;
        
        NSMutableSet *xLabels = [NSMutableSet setWithCapacity:self.plotData.count];
        NSMutableSet *xLocations = [NSMutableSet setWithCapacity:self.plotData.count];
        
        for (NSUInteger i = 0; i < self.plotData.count; i++) {
            NSDictionary *dictionary = self.plotData[i];
            NSDate *date = dictionary[PXDateKey];
            NSString *text;
            if ([dictionary[PXSpecialDateKey] boolValue]) {
                text = [specialDateFormatter stringFromDate:date];
            } else {
                text = [dateFormatter stringFromDate:date];
            }
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:text textStyle:x.labelTextStyle];
            label.tickLocation = @(i);
            label.offset = x.majorTickLength;
            [xLabels addObject:label];
            [xLocations addObject:@(i)];
        }
        x.axisLabels = xLabels;
        x.majorTickLocations = xLocations;
        x.labelingPolicy = CPTAxisLabelingPolicyNone;
    }
    else {
        x.axisLabels = nil;
        x.majorTickLocations = nil;
        x.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    }
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    CGFloat length = self.plotData.count - 1;
    length += PXMarginLengthX;
    CGFloat minXValue = [self.plotData.firstObject[self.xKey] floatValue];
    minXValue -= PXMarginTicksX;
    CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@(minXValue)
                                                                      length:@(length)];
    self.maxCoordinateRanges[@(CPTCoordinateX)] = xRange.copy;
    CGFloat visibleLength = MIN(self.plotData.count, PXVisibleTicksX) - 1;
    visibleLength += PXMarginLengthX;
    CGFloat xScale = visibleLength / length;
    [xRange expandRangeByFactor:@(xScale)];
    xRange.location = @(minXValue + length - visibleLength);
    plotSpace.xRange = xRange;
}

- (void)configureYAxis {
    CGFloat leftPadding = self.xTitle ? 60.0 : 45.0;
    self.graph.plotAreaFrame.paddingLeft = leftPadding;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *y = axisSet.yAxis;
    y.titleOffset = leftPadding - 30.0;
    y.title = self.yTitle;
    
    CGFloat length = self.maxYValue - self.minYValue;
    CGFloat yMajorLength;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    if (self.displayAsPercentage) {
        yMajorLength = 20.0;
        numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        numberFormatter.multiplier = @1.0;
    } else {
        NSUInteger ticksY = MIN(ceilf(length), PXVisibleTicksY - 1);
        yMajorLength = length / ticksY;
    }
    y.labelFormatter = numberFormatter;
    y.majorIntervalLength = @(yMajorLength);
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:@(self.minYValue)
                                                                      length:@(length)];
    self.maxCoordinateRanges[@(CPTCoordinateY)] = yRange.copy;
    plotSpace.yRange = yRange;
}

#pragma mark - CPTBarPlotDelegate

-(void)barPlot:(nonnull CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)idx {
    if (![self.delegate respondsToSelector:@selector(barPlot:didSelectItemAtIndex:)]) {
        return;
    }
    
    [self.delegate barPlot:self didSelectItemAtIndex:idx];
}

@end
