//
//  PXFormatter.h
//  drinkless
//
//  Created by Edward Warrender on 29/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXFormatter : NSObject

+ (instancetype)sharedFormatter;
+ (NSString *)currencyFromNumber:(NSNumber *)number;

@end
