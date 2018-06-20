//
//  PXAuditFeedback.h
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXAuditFeedback : NSObject

- (instancetype)initWithEstimate:(double)estimate percentile:(double)percentile text:(NSString *)text;

@property (nonatomic, readonly) double estimate;
@property (nonatomic, readonly) double percentile;
@property (strong, nonatomic, readonly) NSString *text;

@end
