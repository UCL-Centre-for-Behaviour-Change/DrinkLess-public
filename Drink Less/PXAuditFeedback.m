//
//  PXAuditFeedback.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAuditFeedback.h"

@implementation PXAuditFeedback

- (instancetype)initWithEstimate:(double)estimate percentile:(double)percentile text:(NSString *)text {
    self = [super init];
    if (self) {
        _estimate = estimate;
        _percentile = percentile;
        _text = text;
    }
    return self;
}

@end
