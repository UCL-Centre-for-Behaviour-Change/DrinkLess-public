//
//  PXExplosionLayer.m
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXExplosionLayer.h"
#import <UIKit/UIKit.h>

@implementation PXExplosionLayer

- (id)init {
    self = [super init];
    if (self) {
        CAEmitterCell *scrap1 = [self cellWithImage:[UIImage imageNamed:@"Balloon-Scrap-1"]];
        CAEmitterCell *scrap2 = [self cellWithImage:[UIImage imageNamed:@"Balloon-Scrap-2"]];
        CAEmitterCell *scrap3 = [self cellWithImage:[UIImage imageNamed:@"Balloon-Scrap-3"]];
        self.emitterCells = @[scrap1, scrap2, scrap3];
        self.emitterShape = kCAEmitterLayerPoint;
        self.renderMode = kCAEmitterLayerOldestFirst;
        self.emitting = NO;
    }
    return self;
}

- (CAEmitterCell *)cellWithImage:(UIImage *)image {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)image.CGImage;
    cell.birthRate = 10.0;
    cell.lifetime = 1.0;
    cell.velocity = 500.0;
    cell.emissionRange = M_PI * 2.0;
    cell.scale = 0.6;
    cell.scaleSpeed = -0.6;
    cell.spin = M_PI * 4.0;
    cell.spinRange = M_PI / 2.0;
    return cell;
}

#pragma mark - Properties

- (void)setEmitting:(BOOL)emitting {
    _emitting = emitting;
    
    self.lifetime = emitting ? 1.0 : 0.0;
}

@end
