//
//  PXCPTBarPlot.h
//  drinkless
//
//  Created by Hari Karam Singh on 14/04/2016.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "CPTBarPlot.h"

/** PXBarPlot is a bit confusing of a name as it has nothign to do with CPTBarPlot. This however is an extension for adding the custom icon when the value is 0  */
@interface PXCPTBarPlot : CPTBarPlot

@property (assign, nonatomic) BOOL isGameBarPlot;

@end
