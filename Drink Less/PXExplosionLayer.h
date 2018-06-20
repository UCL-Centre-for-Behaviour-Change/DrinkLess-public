//
//  PXExplosionLayer.h
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <QuartzCore/QuartzCore.h>

@interface PXExplosionLayer : CAEmitterLayer

@property (nonatomic, getter = isEmitting) BOOL emitting;

@end
