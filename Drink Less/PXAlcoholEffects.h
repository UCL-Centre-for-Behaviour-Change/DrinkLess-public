//
//  PXAlcoholEffects.h
//  drinkless
//
//  Created by Edward Warrender on 03/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXAlcoholEffectType) {
    PXAlcoholEffectTypeMood,
    PXAlcoholEffectTypeProductivity,
    PXAlcoholEffectTypeClarity,
    PXAlcoholEffectTypeSleep
};

@interface PXAlcoholEffects : NSObject

@property (strong, nonatomic, readonly) NSDictionary *afterDrinking;
@property (strong, nonatomic, readonly) NSDictionary *afterNotDrinking;
@property (strong, nonatomic, readonly) NSArray *information;

@end
