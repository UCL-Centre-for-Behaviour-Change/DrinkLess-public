//
//  InsightsLastWeekGraphView.m
//  drinkless
//
//  Created by Hari Karam Singh on 29/10/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

#import "InsightsAverageWeekGraphView.h"
#import "CorePlot-CocoaTouch.h"
#import "drinkless-Swift.h"


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

@interface InsightsAverageWeekGraphView() <CPTPlotSpaceDelegate, CPTBarPlotDataSource, CPTBarPlotDelegate>

@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTXYPlotSpace *alcFreePlotSpace;
@property (nonatomic, strong) CPTXYPlotSpace *drinkingPlotSpace;
@property (nonatomic, strong) CPTBarPlot *alcFreePlot;
@property (nonatomic, strong) CPTBarPlot *drinkingPlot;
@property (nonatomic, strong) CPTScatterPlot *alcFreeRunningAvgPlot; // the coloured line graph
@property (nonatomic, strong) CPTScatterPlot *drinkingRunningAvgPlot;
@property (nonatomic, strong) CPTScatterPlot *alcFreeFixedRangeAvgPlot;  // the dotted line
@property (nonatomic, strong) CPTScatterPlot *drinkingFixedRangeAvgPlot;

/** Convenience props */
@property (nonatomic, readonly) CPTPlotRange *xMaxRange;
@property (nonatomic, readonly) CPTPlotRange *xViewRange;
@property (nonatomic, readonly) CPTPlotRange *alcFreeYRange;
@property (nonatomic, readonly) CPTPlotRange *drinkingYRange;

@end


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

@implementation InsightsAverageWeekGraphView

+ (NSUInteger)viewRangeInWeeksForTimeRange:(InsightsAverageWeekGraphRange)timeRange {
    switch (timeRange) {
        case InsightsAverageWeekGraphRange1Month: return 4;
        case InsightsAverageWeekGraphRange3Months: return 13;
        case InsightsAverageWeekGraphRange6Months: return 26;
        case InsightsAverageWeekGraphRange1Year: return 52;
        case InsightsAverageWeekGraphRangeLifetime: return 52; // 9 months
        default: return 999999;
    }
}


//////////////////////////////////////////////////////////
// MARK: - Life Cycle
//////////////////////////////////////////////////////////

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hostingView = [[InsightsGraphHostingView alloc] init];
    self.hostingView.frame = self.bounds;
    self.hostingView.collapsesLayers = NO;
    self.hostingView.allowPinchScaling = NO;
    self.hostingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.hostingView];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[graph]|" options:kNilOptions metrics:nil views:@{@"graph": self.hostingView}]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[graph]|" options:kNilOptions metrics:nil views:@{@"graph": self.hostingView}]];
    [self setNeedsLayout];
    
    [self _setupGraphStructureAndFormat];
    self.hostingView.hostedGraph = self.graph;
    
    self.graphRange = InsightsAverageWeekGraphRange3Months;
    
//    self.backgroundColor = UIColor.purpleColor;
//    self.hostingView.backgroundColor = UIColor.blueColor;
//    self.graph.backgroundColor = UIColor.yellowColor.CGColor;
}

- (void)redraw {
    [self _drawGraphForCurrentData];
    
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    self.hostingView.
//}


//////////////////////////////////////////////////////////
// MARK: - Properties
//////////////////////////////////////////////////////////

- (CPTPlotRange *)xMaxRange {
    NSParameterAssert(self.allStats);
    // Not sure why I need to do a -0.5 and a -1 shim here to make it fit...
    return [CPTPlotRange plotRangeWithLocation:@(0) length:@((NSInteger)self.allStats.weeklySummaries.count - 2 - 1)];
}

- (CPTPlotRange *)alcFreeYRange {
    NSInteger max = 7;// [self.allStats.maxValues[@(PXConsumptionTypeAlcoholFreeDays)] integerValue];
    
    // Create it as ±max so we only occupy half the graph
    return [CPTPlotRange plotRangeWithLocation:@(-max) length:@(2 * max)];
}

- (CPTPlotRange *)drinkingYRange {
    NSInteger max = [self.allStats.maxValues[@(PXConsumptionTypeUnits)] integerValue];
    
    // Don't let it go below 7
    max = MAX(max, 7);
    
    // Create it as ±max so we only occupy half the graph. Invert it so it's the bottom of the graph
    return [CPTPlotRange plotRangeWithLocation:@(max) length:@(-2 * max)];
}

- (CPTPlotRange *)xViewRange {
    NSUInteger weeksWidth = [self.class viewRangeInWeeksForTimeRange:self.graphRange];
    NSUInteger recordCount = self.allStats.weeklySummaries.count - 2;
   // NSAssert(recordCount >= weeksWidth, @"Need at least %lu (+ 2) weekly records", recordCount);
    
    return [CPTPlotRange plotRangeWithLocation:@(recordCount - weeksWidth) length:@(weeksWidth)];
}

//////////////////////////////////////////////////////////
// MARK: - Graph Confiuration
//////////////////////////////////////////////////////////

- (void)_setupGraphStructureAndFormat {
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
    self.graph = graph;
    graph.paddingTop = 0.0;
    graph.paddingRight = 0.0;
    graph.paddingBottom = 0.0;
    graph.paddingLeft = 0.0;
    graph.plotAreaFrame.paddingTop = 0.0;
    graph.plotAreaFrame.paddingRight = 0.0;
    graph.plotAreaFrame.paddingBottom = 0.0;
    graph.plotAreaFrame.paddingLeft = 30;
    graph.plotAreaFrame.plotArea.delegate = self; //?
    
    // Create two plotspaces for the two subgraphs
    self.alcFreePlotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    self.alcFreePlotSpace.allowsUserInteraction = YES;
    self.alcFreePlotSpace.allowsMomentum = YES;
    self.alcFreePlotSpace.delegate = self;

    self.drinkingPlotSpace = (CPTXYPlotSpace *)[self.graph newPlotSpace];
    [graph addPlotSpace:self.drinkingPlotSpace];
    self.drinkingPlotSpace.allowsUserInteraction = YES;
    self.drinkingPlotSpace.allowsMomentum = YES;
    self.drinkingPlotSpace.delegate = self;

    // Create custom labels for axis
    CPTMutableLineStyle *noLineStyle = [CPTMutableLineStyle lineStyle];
    noLineStyle.lineWidth              = 0.0;
    noLineStyle.lineColor              = [CPTColor clearColor];
    CPTMutableLineStyle *yMajorLineStyle = [CPTMutableLineStyle lineStyle];
    yMajorLineStyle.lineWidth              = 0.5;
    yMajorLineStyle.lineColor              = [CPTColor colorWithCGColor:[UIColor colorWithWhite:0.7 alpha:1].CGColor];
    
    CPTXYAxis *x = ((CPTXYAxisSet *)graph.axisSet).xAxis;
    x.orthogonalPosition = @0.0;
    x.minorTicksPerInterval = 0;
    x.axisLineStyle = noLineStyle;
//    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    x.majorTickLineStyle = noLineStyle;
    x.titleTextStyle = [CPTTextStyle textStyleWithAttributes:@{}];
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.majorTickLength = 1.0;
    
    CPTXYAxis *y = ((CPTXYAxisSet *)graph.axisSet).yAxis;
    y.orthogonalPosition = @0.0;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:1.0];
    y.minorTicksPerInterval = 0;
    y.labelingPolicy = CPTAxisLabelingPolicyNone; //CPTAxisLabelingPolicyLocationsProvided;
    y.axisLineStyle = noLineStyle;
    y.majorTickLineStyle = noLineStyle;
    y.minorTickLineStyle = noLineStyle;
    y.majorTickLength = 1;
    y.titleOffset = 17;
    
//    y.hidden = YES;
//    y.labelingPolicy = CPTAxisLabelingPolicyNone;
//    for (CPTAxisLabel *axisLabel in y.axisLabels) {
//        axisLabel.contentLayer.hidden = YES;
//    }
    y.title = @"← UNITS   |   ALC FREE →";
    y.titleRotation = M_PI_2;
    CPTMutableTextStyle *style = [CPTMutableTextStyle textStyle];
    style.fontSize = 8.0;
    style.color = [CPTColor colorWithCGColor:[UIColor colorWithWhite:0.7 alpha:1.0].CGColor];
    y.titleTextStyle = style;
}

//---------------------------------------------------------------------

- (void)_drawGraphForCurrentData
{
    // Calculate the ranges...
    // View portal range
    self.alcFreePlotSpace.xRange = self.xViewRange;
    self.alcFreePlotSpace.yRange = self.alcFreeYRange;
    self.drinkingPlotSpace.xRange = self.xViewRange;
    self.drinkingPlotSpace.yRange = self.drinkingYRange;

    CPTXYAxis *x = ((CPTXYAxisSet *)self.graph.axisSet).xAxis;
    CPTXYAxis *y = ((CPTXYAxisSet *)self.graph.axisSet).yAxis;

    // Setup x axis labels
    x.labelingPolicy = CPTAxisLabelingPolicyNone;

//    y.majorTickLocations = [NSSet setWithArray:@[@(self.alcFreeDaysAverage),@(-self.alcFreeDaysAverage), @(-self.drinkUnitsAverage)]];
    
    
    // 1 month = every month
    // 3 months = every month on the month
    // 6 months = every month
    // 1 year = every other
    // lifetime = every year, max 6 iterations
    
    // Make major and minor tick locations & labels
    NSDate *lastWeekEndDate = [self.allStats.weeklySummaries[1] endDate];
    NSDateFormatter *dateLabelFormatter = [[NSDateFormatter alloc] init];
    dateLabelFormatter.calendar = NSCalendar.currentCalendar;
    [dateLabelFormatter setLocalizedDateFormatFromTemplate:@"MMM yy"];
    NSString *lastEntryLabel = nil;
    NSMutableDictionary *tickLabels = [NSMutableDictionary dictionaryWithCapacity:self.allStats.weeklySummaries.count]; // approx
    
    // Just get a label every month and we'll worry about skips in the next step
    for (int i=1; i<self.allStats.weeklySummaries.count-1; i++) {
        PXWeekSummary *weekSumm = self.allStats.weeklySummaries[i];
        NSDate *endDate = weekSumm.endDate;
        NSString *entryLabel = [dateLabelFormatter stringFromDate:endDate];
        entryLabel = entryLabel.uppercaseString;
        if (lastEntryLabel == nil) {
            lastEntryLabel = entryLabel;
        } else if (![entryLabel isEqualToString:lastEntryLabel]) {
            // Month change!
            lastEntryLabel = entryLabel;
            tickLabels[@(i-1)] = entryLabel;
        } else {
            tickLabels[@(i-1)] = @"";
        }
    }
    
    // Now do the tick locations and labels
    NSUInteger skipModulus = 1;
    if (self.graphRange == InsightsAverageWeekGraphRange1Year ||
        self.graphRange == InsightsAverageWeekGraphRangeLifetime) {
        skipModulus = 2;
    }
    NSUInteger skipCnt = 1;
    NSMutableSet *minorTickLocations = [NSMutableSet set];
    NSMutableSet *majorTickLocations = [NSMutableSet set];
    NSMutableSet *axisLabels = [NSMutableSet set];
    for (NSNumber *location in [tickLabels.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]]) {
        NSString *label = tickLabels[location];
        BOOL doMajorTick = NO;
        if (label.length > 0) {
            if (skipCnt++ % skipModulus == 0) {
                doMajorTick = YES;
            }
        }
        if (!doMajorTick) {
            [minorTickLocations addObject:location];
        } else {
            [majorTickLocations addObject:location];
            // And make a label
            CPTMutableTextStyle *style = [CPTMutableTextStyle textStyle];
            style.fontSize = 8.5;
            style.fontName = @"HelveticaNeue-Bold";
            style.color = [CPTColor colorWithCGColor:[UIColor colorWithWhite:0.7 alpha:1.0].CGColor];
            CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:label textStyle:style];
            newLabel.tickLocation = location;
            newLabel.offset = x.majorTickLength; // ??
            [axisLabels addObject:newLabel];
        }
    }
    x.majorTickLocations = majorTickLocations;
    //x.minorTickLocations = minorTickLocations;
    x.axisLabels = axisLabels;
    
        // Y AXIS
//        y.visibleRange = [CPTPlotRange plotRangeWithLocation:@(-10) length:@15];
//        y.visibleAxisRange = [CPTPlotRange plotRangeWithLocation:@(-10) length:@15];

        
    /////////////////////////////////////////
    // PLOTS
    /////////////////////////////////////////
    
    // Clear out existing
    for (CPTPlot *plot in self.graph.allPlots) {
        [self.graph removePlot:plot];
    }
    
    
    CPTMutableLineStyle *noLineStyle = [CPTMutableLineStyle lineStyle];
    noLineStyle.lineWidth              = 0.0;
    noLineStyle.lineColor              = [CPTColor clearColor];
    
    
    /////////////////////////////////////////
    // THE PLOTS
    /////////////////////////////////////////

    {
        CPTBarPlot *plot       = [[CPTBarPlot alloc] init];
        plot.barWidth          = @0.8;//@(1.0/12.0);
        plot.barOffset         = @0;//@(j++ / 12.0);
        plot.barCornerRadius   = 0.0;
        plot.barsAreHorizontal = NO;
        plot.lineStyle         = noLineStyle;
        plot.dataSource        = self;
        plot.delegate          = self;
        plot.zPosition = 100;
        plot.identifier = @100;
        plot.fill = [CPTFill fillWithColor:[CPTColor greenColor]];
        [self.graph addPlot:plot toPlotSpace:self.alcFreePlotSpace];
        self.alcFreePlot = plot;
    }
    {
        CPTBarPlot *plot       = [[CPTBarPlot alloc] init];
        plot.barWidth          = @0.8;//@(1.0/12.0);
        plot.barOffset         = @0;//@(j++ / 12.0);
        plot.barCornerRadius   = 0;
        plot.barsAreHorizontal = NO;
        plot.lineStyle         = noLineStyle;
        plot.dataSource        = self;
        plot.delegate          = self;
        plot.zPosition = 100;
        plot.identifier = @101;
        plot.fill = [CPTFill fillWithColor:[CPTColor redColor]];
        [self.graph addPlot:plot toPlotSpace:self.drinkingPlotSpace];
        self.drinkingPlot = plot;
        
    }
    // BACKGROUND COLOR LINE GRAPH
    {
        CPTScatterPlot *plot   = [[CPTScatterPlot alloc] init];
        plot.areaBaseValue = @0.0;
        plot.masksToBounds = YES;
        CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineWidth = 0.5;
        UIColor *lineCol = [UIColor.drinkLessGreenColor colorWithAlphaComponent:0.5];
        lineStyle.lineColor = [CPTColor colorWithCGColor:lineCol.CGColor];
        plot.dataLineStyle = lineStyle;
        UIColor *gradCol1 = [UIColor.gaugeYellowColor colorWithAlphaComponent:0.1];
        UIColor *gradCol2 = [UIColor.gaugeGreenColor colorWithAlphaComponent:0.4];
        CPTGradient *grad = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:gradCol1.CGColor] endingColor:[CPTColor colorWithCGColor:gradCol2.CGColor]];
        grad.angle = 90;
        plot.areaFill = [CPTFill fillWithGradient:grad];
        plot.dataSource = self;
//        plot.delegate = self;
        plot.identifier = @102;
        plot.zPosition = 98;
        [self.graph addPlot:plot toPlotSpace:self.alcFreePlotSpace];
        self.alcFreeRunningAvgPlot = plot;
    }
    {
        CPTScatterPlot *plot   = [[CPTScatterPlot alloc] init];
        plot.areaBaseValue = @0.0;
        CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineWidth = 0.5;
        UIColor *lineCol = [UIColor.gaugeRedColor colorWithAlphaComponent:0.5];
        lineStyle.lineColor = [CPTColor colorWithCGColor:lineCol.CGColor];
        plot.dataLineStyle = lineStyle;
        UIColor *gradCol1 = [UIColor.gaugeRedColor colorWithAlphaComponent:0.1];
        UIColor *gradCol2 = [UIColor.gaugeRedColor colorWithAlphaComponent:0.4];
        CPTGradient *grad = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:gradCol1.CGColor] endingColor:[CPTColor colorWithCGColor:gradCol2.CGColor]];
        grad.angle = -90;
        plot.areaFill = [CPTFill fillWithGradient:grad];
        plot.dataSource = self;
        //        plot.delegate = self;
        plot.identifier = @103;
        plot.zPosition = 98;
        [self.graph addPlot:plot toPlotSpace:self.drinkingPlotSpace];
        self.drinkingRunningAvgPlot = plot;
    }
    // FIXED RANGE DASHED LINE
    {
        CPTScatterPlot *plot   = [[CPTScatterPlot alloc] init];
        CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineWidth = 1.0;
        UIColor *lineCol = [UIColor.gaugeGreenColor colorWithAlphaComponent:0.5];
        lineStyle.lineColor = [CPTColor colorWithCGColor:lineCol.CGColor];
        lineStyle.dashPattern = @[@5,@4];
        plot.dataLineStyle = lineStyle;
        plot.dataSource = self;
        //        plot.delegate = self;
        plot.identifier = @104;
        plot.zPosition = 99;
        [self.graph addPlot:plot toPlotSpace:self.alcFreePlotSpace];
        self.alcFreeFixedRangeAvgPlot = plot;
    }
    {
        CPTScatterPlot *plot   = [[CPTScatterPlot alloc] init];
        CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineWidth = 1.0;
        UIColor *lineCol = [UIColor.gaugeRedColor colorWithAlphaComponent:0.5];
        lineStyle.lineColor = [CPTColor colorWithCGColor:lineCol.CGColor];
        lineStyle.dashPattern = @[@5,@4];
        plot.dataLineStyle = lineStyle;
        plot.dataSource = self;
        //        plot.delegate = self;
        plot.identifier = @105;
        plot.zPosition = 99;
        [self.graph addPlot:plot toPlotSpace:self.drinkingPlotSpace];
        self.drinkingFixedRangeAvgPlot = plot;
    }
}


//////////////////////////////////////////////////////////
// MARK: - Data Sources & Delegates
//////////////////////////////////////////////////////////

- (void)didFinishDrawing:(CPTPlot *)plot
{
    [self _doGraphShims];
    
//    // Separate them a bit to make room for the x axis labels
//    if (plot == self.drinkingPlot) {
//        CGRect f = self.drinkingPlot.frame;
//        f.origin.y = -7;
//        self.drinkingPlot.frame =
//        self.drinkingRunningAvgPlot.frame =
//        self.drinkingFixedRangeAvgPlot.frame = f;
//    }
//    if (plot == self.alcFreePlot) {
//        CGRect f = self.alcFreePlot.frame;
//        f.origin.y = 7;
//        self.alcFreePlot.frame =
//        self.alcFreeRunningAvgPlot.frame =
//        self.alcFreeFixedRangeAvgPlot.frame = f;
//    }
//
//    // just do this every time. we're using abs positions so its fine
//    // Move up the x labels
//    CPTXYAxis *x = ((CPTXYAxisSet *)self.graph.axisSet).xAxis;
//    CGRect r = x.bounds;
//    r.origin.y = 8;
//    x.bounds = r;
}

//---------------------------------------------------------------------

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    NSUInteger dataPoints = MAX(0, self.allStats.weeklySummaries.count - 2);
    if (plot == self.drinkingPlot || plot == self.alcFreePlot) {
        return dataPoints;
    } else if (plot == self.drinkingRunningAvgPlot || plot == self.alcFreeRunningAvgPlot) {
        return ceil((float)dataPoints / 4.0) + 1;
    } else if (plot == self.drinkingFixedRangeAvgPlot || plot == self.alcFreeFixedRangeAvgPlot) {
    return 2;
    }
    return 0;
}

//---------------------------------------------------------------------

/** Return the value for the plot */
- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    // MAIN PLOTS
    if (plot == self.alcFreePlot || plot == self.drinkingPlot) {
        if (fieldEnum == CPTCoordinateX) {
            return @(idx + 0.5);   // shim them to left align
        }
        PXWeekSummary *weekSumm = self.allStats.weeklySummaries[idx+1]; // start after the first (incomplete week)
        NSNumber *valNum;
        if (plot == self.alcFreePlot) {
            valNum = @(weekSumm.alcoholFreeDays);
        } else {
            valNum = @(weekSumm.totalUnits);
        }
        return valNum;
    }
    
    // RUNNING AVG PLOTS (every 4th bar)
    if (plot == self.drinkingRunningAvgPlot || plot == self.alcFreeRunningAvgPlot) {
        if (fieldEnum == CPTCoordinateX) {
            return @(idx * 4);
        }
        // Get (up to) 2 weeks ahead and behind week summs
        NSUInteger cnt = self.allStats.weeklySummaries.count;
        NSInteger r0 = MAX(0, (NSInteger)idx * 4 - 2);
        NSInteger r1 = MIN((NSInteger)cnt-1, (NSInteger)idx * 4 + 2 - 1);
        NSArray *weekSumms = [self.allStats.weeklySummaries subarrayWithRange:NSMakeRange(r0, r1-r0+1)];
        // Averages
        CGFloat drinksAvg = 0;
        CGFloat alcFreeDaysAvg = 0;
        if (cnt > 0) {
            for (PXWeekSummary *weekSumm in weekSumms) {
                drinksAvg += weekSumm.totalUnits;
                alcFreeDaysAvg += weekSumm.alcoholFreeDays;
            }
            drinksAvg = drinksAvg / (CGFloat)weekSumms.count;
            alcFreeDaysAvg = alcFreeDaysAvg / (CGFloat)weekSumms.count;
        }
        
        NSNumber *valNum = @(plot == self.drinkingRunningAvgPlot ? drinksAvg : alcFreeDaysAvg);
        return valNum;
        
    }
    if (plot == self.drinkingFixedRangeAvgPlot || plot == self.alcFreeFixedRangeAvgPlot) {
        if (fieldEnum == CPTCoordinateX) {
            CGFloat latestPortalLoc1 = [self.xMaxRange.location floatValue] + [self.xMaxRange.length floatValue];
            CGFloat latestPortalLoc0 = latestPortalLoc1 - [self.xViewRange.length floatValue];
            return @(idx == 0 ? latestPortalLoc0 : latestPortalLoc1);
        }
        if (plot == self.drinkingFixedRangeAvgPlot) {
            return @(self.drinkUnitsAverage);
        } else {
            return @(self.alcFreeDaysAverage);
        }
    }
    return @(0);
    
//    return @(idx);
}


//- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
//{
//    return (5);
//}

//---------------------------------------------------------------------

- (CPTFillArray *)barFillsForBarPlot:(CPTBarPlot *)barPlot recordIndexRange:(NSRange)indexRange
{
    const CGFloat MAX_DARKEN = 0.15;
    NSMutableArray *colors = [NSMutableArray array];
    for (NSUInteger idx=indexRange.location; idx<indexRange.location+indexRange.length; idx++) {
        UIColor *baseColor;
        UIColor *darkColor;
        CGFloat angle = 0;
        CGFloat barValue = [[self numberForPlot:barPlot field:CPTCoordinateY recordIndex:idx] floatValue];
        
        if (barPlot == self.alcFreePlot) {
            baseColor = UIColor.drinkLessGreenColor;
            angle = 90;
            CGFloat rangeMax = self.alcFreeYRange.location.floatValue + self.alcFreeYRange.length.floatValue;
            darkColor = [baseColor colorWithBrightnessAdjustedBy:-MAX_DARKEN * barValue / rangeMax];
        } else {
            CGFloat rangeMax = self.drinkingYRange.location.floatValue;  // location is max because we define range from bottom up (and the graph is upside down)
            CGFloat maxFrac = barValue / rangeMax;
            baseColor = [UIColor.gaugeYellowColor colorFadedTowardColor:UIColor.gaugeRedColor amount:maxFrac];
            angle = -90;
            darkColor = [baseColor colorWithBrightnessAdjustedBy:-MAX_DARKEN * maxFrac];
        }
        
        CPTGradient *grad = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:baseColor.CGColor] endingColor:[CPTColor colorWithCGColor:darkColor.CGColor]];
        grad.angle = angle;
        //UIColor *fadeColor = [baseColor colorWithAlphaComponent:((float)idx)/12.0];
        [colors addObject:[CPTFill fillWithGradient:grad]];
    }
    return [CPTFillArray arrayWithArray:colors];
}

//---------------------------------------------------------------------

// Constrain to visible range or it will allow scrolling forever in all directions
- (CPTPlotRange *)plotSpace:(CPTXYPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate {
    
    if (self.allStats == nil) {
        return newRange;
    }
    
    CPTMutablePlotRange *changedRange = newRange.mutableCopy;
    if (coordinate == CPTCoordinateY) {
        CPTPlotRange *maxRange = space == self.alcFreePlotSpace ? self.alcFreeYRange : self.drinkingYRange;
        [changedRange shiftEndToFitInRange:maxRange];
        [changedRange shiftLocationToFitInRange:maxRange];
    } else {
        //CPTPlotRange *r = [CPTPlotRange plotRangeWithLocation:@(-10) length:@30];
        [changedRange shiftEndToFitInRange:self.xMaxRange];
        [changedRange shiftLocationToFitInRange:self.xMaxRange];
        
        // HACK to prevent CorePlot from drawing gradient from the middle line *after* we've shimmed a gap.  Not didFinishDrawing isnt called when no chagne occurs so detect this first
        CPTPlotRange *currentViewRange = [space plotRangeForCoordinate:CPTCoordinateX];
        double maxX = self.xMaxRange.locationDouble + self.xMaxRange.lengthDouble;
        double currX0 = currentViewRange.locationDouble;
        double currX1 = currentViewRange.locationDouble + currentViewRange.lengthDouble;
        BOOL newRangeIsOOB =
            (newRange.locationDouble < 0.0) ||
        ((newRange.locationDouble + newRange.lengthDouble) > maxX);  // prevetns flicker when s off boundaries
        if (!newRangeIsOOB || (currX0 > 0 && currX1 < maxX)) {
            CGRect f = self.alcFreeRunningAvgPlot.frame;
            f.origin.y = 0;
            self.alcFreeRunningAvgPlot.frame = f;
            f = self.drinkingRunningAvgPlot.frame;
            f.origin.y = 0;
            self.drinkingRunningAvgPlot.frame = f;
        }
    }

    
    
    return changedRange;
}

//---------------------------------------------------------------------

/** Adjust things to create a gap around the middle for the x axis labels */
- (void)_doGraphShims {
    CGRect f = self.drinkingPlot.frame;
    f.origin.y = -7;
    f.origin.x = -7;
    self.drinkingPlot.frame =
    self.drinkingRunningAvgPlot.frame =
    self.drinkingFixedRangeAvgPlot.frame = f;

    f = self.alcFreePlot.frame;
    f.origin.y = 7;
    f.origin.x = -7;
    self.alcFreePlot.frame =
    self.alcFreeRunningAvgPlot.frame =
    self.alcFreeFixedRangeAvgPlot.frame = f;
    // just do this every time. we're using abs positions so its fine
    // Move up the x labels
    CPTXYAxis *x = ((CPTXYAxisSet *)self.graph.axisSet).xAxis;
    CGRect r = x.bounds;
    r.origin.y = 8;
    r.origin.x = -7;
    x.bounds = r;
    
//    CPTXYAxis *y = ((CPTXYAxisSet *)self.graph.axisSet).yAxis;
//    f = y.frame;
//    f.origin.x = f.origin.x + 25;
//    y.frame = f;
//
}

@end
