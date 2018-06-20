//
//  PXInfographicViewController.h
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXAuditCalculator.h"

@interface PXInfographicViewController : PXTrackedViewController  

+ (instancetype)infographicWithType:(PXGraphicType)type;

@property (strong, nonatomic) PXAuditCalculator *auditCalculator;
@property (nonatomic, readonly) PXGraphicType graphicType;
@property (nonatomic) PXPopulationType populationType;

@end
