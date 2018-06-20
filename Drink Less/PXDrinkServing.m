//
//  PXDrinkServing.m
//  drinkless
//
//  Created by Edward Warrender on 25/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkServing.h"
#import "PXDrink.h"


@implementation PXDrinkServing

@dynamic identifier;
@dynamic millilitres;
@dynamic size;
@dynamic name;
@dynamic drink;

- (NSString *)name {
    [self willAccessValueForKey:@"name"];
    NSString *name = [NSString stringWithFormat:@"%@ (%@ml)",
                      self.size, self.millilitres.stringValue];
    [self didAccessValueForKey:@"name"];
    return name;
}

- (void)setSize:(NSString *)size {
    [self willChangeValueForKey:@"size"];
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:size forKey:@"size"];
    [self didChangeValueForKey:@"size"];
    [self didChangeValueForKey:@"name"];
}

- (void)setMillilitres:(NSNumber *)millilitres {
    [self willChangeValueForKey:@"millilitres"];
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:millilitres forKey:@"millilitres"];
    [self didChangeValueForKey:@"millilitres"];
    [self didChangeValueForKey:@"name"];
}

@end
