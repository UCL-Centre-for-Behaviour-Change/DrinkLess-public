//
//  PXPlot.m
//  drinkless
//
//  Created by Edward Warrender on 01/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPlot.h"

NSString *const PXTitleKey = @"title";
NSString *const PXColorKey = @"color";

@interface PXPlot()

@property (nonatomic, strong) CPTLegend *theLegend;

@end

@implementation PXPlot

- (instancetype)initWithHostingView:(CPTGraphHostingView *)hostingView {
    self = [super init];
    if (self) {
        _hostingView = hostingView;
        _hostingView.collapsesLayers = NO;
        _hostingView.allowPinchScaling = NO;
        [self setupGraph];
    }
    return self;
}

- (void)setupGraph {
    // Overridden by subclasses
}

- (void)setupLegend {
    self.theLegend = [CPTLegend legendWithGraph:self.graph];
    self.theLegend.columnMargin = 10.0;
    self.theLegend.rowMargin = 10.0;
    
    self.theLegend.paddingLeft = 0.0;
    self.theLegend.paddingTop = 0.0;
    self.theLegend.paddingRight = 0.0;
    self.theLegend.paddingBottom = 0.0;
    
    self.theLegend.entryPaddingLeft     = 0.0;
    self.theLegend.entryPaddingTop      = 0.0;
    self.theLegend.entryPaddingRight    = 0.0;
    self.theLegend.entryPaddingBottom   = 0.0;
    
    CPTMutableTextStyle *legendTextStyle = [CPTMutableTextStyle textStyle];
    legendTextStyle.color = [CPTColor colorWithGenericGray:0.33];
    legendTextStyle.textAlignment = CPTTextAlignmentLeft;
    legendTextStyle.fontName = @"Helvetica";
    legendTextStyle.fontSize = 11.0;
    self.theLegend.textStyle = legendTextStyle;
    
    self.graph.legendAnchor = CPTRectAnchorBottom;
    self.graph.legend.paddingBottom = 15.0;
}

- (void)updateLegendWithCount:(NSInteger)count {
    CGFloat paddingBottom = self.paddingBottomOffset;
    if (!self.isLegendHidden) {
        CPTLegend *theLegend = self.graph.legend;
        theLegend.numberOfColumns = count == 1 ? 1 : 2;
        theLegend.numberOfRows = ceilf(count / (float)theLegend.numberOfColumns);
        paddingBottom += [[theLegend.rowHeightsThatFit valueForKeyPath:@"@sum.self"] floatValue];
        paddingBottom += (theLegend.numberOfRows - 1) * theLegend.rowMargin;
        paddingBottom += theLegend.paddingBottom;
    }
    self.graph.plotAreaFrame.paddingBottom = paddingBottom;
}

- (void)setLegendHidden:(BOOL)legendHidden {
    _legendHidden = legendHidden;
    
    self.graph.legend = _legendHidden ? nil : self.theLegend;;
}

@end
