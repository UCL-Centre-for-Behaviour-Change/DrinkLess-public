//
//  PXStep.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStep.h"
#import "PXStepGuide.h"

@implementation PXStep

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _image = [UIImage imageNamed:dictionary[@"imageName"]];
        _title = dictionary[@"title"];
        _detail = dictionary[@"detail"];
        _identifier = dictionary[@"identifier"];
        _completed = NO;
    }
    return self;
}

@end
