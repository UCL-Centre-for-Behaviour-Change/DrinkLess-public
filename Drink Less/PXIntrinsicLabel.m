//
//  PXIntrinsicLabel.m
//  drinkless
//
//  Created by Edward Warrender on 19/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIntrinsicLabel.h"

@implementation PXIntrinsicLabel

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.preferredMaxLayoutWidth = self.bounds.size.width;
}

@end
