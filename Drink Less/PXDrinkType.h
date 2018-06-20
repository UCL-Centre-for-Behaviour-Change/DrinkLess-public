//
//  PXDrinkType.h
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PXDrink;

@interface PXDrinkType : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) PXDrink *drink;

@end
