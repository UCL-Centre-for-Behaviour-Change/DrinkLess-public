//
//  PXDrink.h
//  drinkless
//
//  Created by Edward Warrender on 20/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PXDrinkAddition, PXDrinkRecord, PXDrinkServing, PXDrinkType;

@interface PXDrink : NSManagedObject

@property (nonatomic, retain) NSNumber * abvMax;
@property (nonatomic, retain) NSNumber * abvMin;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *record;
@property (nonatomic, retain) NSSet *servings;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSSet *additions;
@end

@interface PXDrink (CoreDataGeneratedAccessors)

- (void)addRecordObject:(PXDrinkRecord *)value;
- (void)removeRecordObject:(PXDrinkRecord *)value;
- (void)addRecord:(NSSet *)values;
- (void)removeRecord:(NSSet *)values;

- (void)addServingsObject:(PXDrinkServing *)value;
- (void)removeServingsObject:(PXDrinkServing *)value;
- (void)addServings:(NSSet *)values;
- (void)removeServings:(NSSet *)values;

- (void)addTypesObject:(PXDrinkType *)value;
- (void)removeTypesObject:(PXDrinkType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

- (void)addAdditionsObject:(PXDrinkAddition *)value;
- (void)removeAdditionsObject:(PXDrinkAddition *)value;
- (void)addAdditions:(NSSet *)values;
- (void)removeAdditions:(NSSet *)values;

@end
