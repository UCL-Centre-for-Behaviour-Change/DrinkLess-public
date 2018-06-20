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

@class PXDrink;

@interface PXDrinkServing : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * millilitres;
@property (nonatomic, retain) NSString * size;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) PXDrink *drink;

@end
