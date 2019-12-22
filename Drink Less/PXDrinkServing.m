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
#import "PXDebug.h"
#import "NSManagedObject+PXFindByID.h"

//////////////////////////////////////////////////////////
// MARK: - Types & Consts
//////////////////////////////////////////////////////////

const NSInteger kPXDrinkServingCustomIdentifier = 10000;


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


@implementation PXDrinkServing

@dynamic identifier;
@dynamic millilitres;
@dynamic size;
@dynamic name;
@dynamic drink;

//---------------------------------------------------------------------

+ (instancetype)drinkServingForCustomVolume:(NSNumber *)volume forDrink:(PXDrink *)drink context:(NSManagedObjectContext *)context
{
    PXDrinkServing *customServing;
    
    // Look for one with the specified volume
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkServing"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier > %li && millilitres == %@ && drink.identifier == %@", kPXDrinkServingCustomIdentifier, volume, drink.identifier];
    NSArray *recs = [context executeFetchRequest:fetchRequest error:nil];
    customServing = recs.firstObject;
    
    if (customServing) {
        logd(@"[PXDrinkServing] Found existing custom Drink Serving %@", customServing);
        return customServing;
    }
    
    // Otherwise find the next available identifier and create the record
    NSInteger identifier = kPXDrinkServingCustomIdentifier;
    PXDrinkServing *rec;
    do {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkServing"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %li", ++identifier];
        rec = [context executeFetchRequest:fetchRequest error:nil].firstObject;
    } while (rec);
    
    // Now create a record with the id
    customServing = (id)[self createInContext:context];
    customServing.identifier = @(identifier);
    customServing.millilitres = volume;
    customServing.size = @"Custom";
    customServing.drink = drink;
    NSError *e;
    [context save:&e];
    logd(@"[PXDrinkServing] Created new Drink Serving %@ (err: %@)", customServing, e);
    
    return customServing;
}

//---------------------------------------------------------------------

- (NSString *)name {
    [self willAccessValueForKey:@"name"];
    // The placeholder for user entered values has a special name
    NSString *name;
    if (self.identifier.integerValue == kPXDrinkServingCustomIdentifier) {
        name = @"Custom...";
    } else {
        name = [NSString stringWithFormat:@"%@ (%@ml)",
                self.size, self.millilitres.stringValue];
    }
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

- (BOOL)isCustom
{
    // > b/c the number itself is the placeholder. It should never be ==
    return self.identifier.integerValue > kPXDrinkServingCustomIdentifier;
}

@end
