//
//  NSManagedObject+PXFindByID.h
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (PXFindByID)

+ (NSManagedObject *)createInContext:(NSManagedObjectContext *)context;

+ (NSManagedObject *)updateWithID:(NSNumber *)identifier
                        predicate:(NSPredicate *)predicate
                        inContext:(NSManagedObjectContext *)context;

+ (NSManagedObject *)updateWithID:(NSNumber *)identifier
                        inContext:(NSManagedObjectContext *)context;

+ (NSManagedObject *)findWithID:(NSNumber *)identifier
                      predicate:(NSPredicate *)predicate
                      inContext:(NSManagedObjectContext *)context;

+ (NSManagedObject *)findWithID:(NSNumber *)identifier
                      inContext:(NSManagedObjectContext *)context;

@end
