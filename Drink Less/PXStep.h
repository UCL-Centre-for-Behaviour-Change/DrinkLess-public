//
//  PXStep.h
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@class PXStepGuide;

@interface PXStep : NSObject

@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *detail;
@property (strong, nonatomic, readonly) NSString *identifier;
@property (nonatomic, getter=hasCompleted) BOOL completed;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
