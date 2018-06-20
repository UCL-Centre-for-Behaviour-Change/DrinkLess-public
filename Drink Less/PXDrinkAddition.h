//
//  PXDrinkAddition.h
//  drinkless
//
//  Created by Edward Warrender on 20/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PXDrink;

@interface PXDrinkAddition : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) PXDrink *drink;

@end
