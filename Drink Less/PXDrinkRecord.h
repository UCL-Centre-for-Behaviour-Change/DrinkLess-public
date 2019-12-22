//
//  PXDrinkRecord.h
//  drinkless
//
//  Created by Edward Warrender on 20/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PXDrink;

@interface PXDrinkRecord : NSManagedObject 

@property (nonatomic, retain) NSNumber * abv;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString *timezone;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSString * parseObjectId;
@property (nonatomic, retain) NSString * iconName;
@property (nonatomic, retain) NSNumber * parseUpdated;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSNumber * servingID;
@property (nonatomic, retain) NSNumber * totalCalories;
@property (nonatomic, retain) NSNumber * totalSpending;
@property (nonatomic, retain) NSNumber * totalUnits;
@property (nonatomic, retain) NSNumber * typeID;
@property (nonatomic, retain) NSNumber * additionID;
@property (nonatomic, retain) PXDrink *drink;

@end
