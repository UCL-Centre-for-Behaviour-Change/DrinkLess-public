//
//  PXButtonIntrinsicInsets.m
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXButtonIntrinsicInsets.h"

@implementation PXButtonIntrinsicInsets

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    return CGSizeMake(size.width +
                      self.titleEdgeInsets.left +
                      self.imageEdgeInsets.left +
                      self.titleEdgeInsets.right +
                      self.imageEdgeInsets.right,
                      
                      size.height +
                      self.titleEdgeInsets.top +
                      self.imageEdgeInsets.top +
                      self.titleEdgeInsets.bottom +
                      self.imageEdgeInsets.bottom);
    
}

@end
