//
//  PXAlcoholFreeRecord.h
//  drinkless
//
//  Created by Edward Warrender on 12/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PXAlcoholFreeRecord : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString *timezone;
@property (nonatomic, retain) NSString * parseObjectId;
@property (nonatomic, retain) NSNumber * parseUpdated;

@end
