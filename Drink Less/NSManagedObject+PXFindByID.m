//
//  NSManagedObject+PXFindByID.m
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "NSManagedObject+PXFindByID.h"

@implementation NSManagedObject (PXFindByID)

+ (NSManagedObject *)createInContext:(NSManagedObjectContext *)context {
    NSString *entityName = NSStringFromClass([self class]);
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

+ (NSManagedObject *)updateWithID:(NSNumber *)identifier predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSManagedObject *object = [self findWithID:identifier predicate:predicate inContext:context];
    if (!object) {
        object = [[self class] createInContext:context];
        [object setValue:identifier forKey:@"identifier"];
    }
    return object;
}

+ (NSManagedObject *)updateWithID:(NSNumber *)identifier inContext:(NSManagedObjectContext *)context {
    return [self updateWithID:identifier predicate:nil inContext:context];
}

+ (NSManagedObject *)findWithID:(NSNumber *)identifier predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSString *entityName = NSStringFromClass([self class]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    if (predicate) {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fetchRequest.predicate, predicate]];
    }
    return [context executeFetchRequest:fetchRequest error:NULL].firstObject;
}

+ (NSManagedObject *)findWithID:(NSNumber *)identifier inContext:(NSManagedObjectContext *)context {
    return [self findWithID:identifier predicate:nil inContext:context];
}

@end
