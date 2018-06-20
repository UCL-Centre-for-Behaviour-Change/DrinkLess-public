//
//  PXFormatter.m
//  drinkless
//
//  Created by Edward Warrender on 29/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFormatter.h"

@interface PXFormatter ()

@property (strong, nonatomic) NSNumberFormatter *currencyFormatter;

@end

@implementation PXFormatter

+ (instancetype)sharedFormatter {
    static PXFormatter *sharedFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFormatter = [[PXFormatter alloc] init];
    });
    return sharedFormatter;
}

- (id)init {
    self = [super init];
    if (self) {
        _currencyFormatter = [[NSNumberFormatter alloc] init];
        _currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        _currencyFormatter.locale = [NSLocale currentLocale];
    }
    return self;
}

+ (NSString *)currencyFromNumber:(NSNumber *)number {
    NSString *currency = nil;
    if (number) {
        currency = [[PXFormatter sharedFormatter].currencyFormatter stringFromNumber:number];
    }
    return currency;
}

@end
