//
//  PXAlcoholEffectViewController.h
//  drinkless
//
//  Created by Edward Warrender on 03/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXAlcoholEffects.h"

@interface PXAlcoholEffectViewController : PXTrackedViewController

- (instancetype)initWithEffectType:(PXAlcoholEffectType)effectType;

@property (strong, nonatomic) PXAlcoholEffects *alcoholEffects;

@end
