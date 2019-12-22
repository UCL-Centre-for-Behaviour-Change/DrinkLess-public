//
//  PXDrinkServing.h
//  drinkless
//
//  Created by Edward Warrender on 25/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//////////////////////////////////////////////////////////
// MARK: - Types & Consts
//////////////////////////////////////////////////////////

extern const NSInteger kPXDrinkServingCustomIdentifier;


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


@class PXDrink;

@interface PXDrinkServing : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * millilitres;
@property (nonatomic, retain) NSString * size;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) PXDrink *drink;

@property (nonatomic, readonly) BOOL isCustom;

+ (instancetype)drinkServingForCustomVolume:(NSNumber *)volume forDrink:(PXDrink *)drink context:(NSManagedObjectContext *)context;

@end
