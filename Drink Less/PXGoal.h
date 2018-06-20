//
//  PXGoal.h
//  drinkless
//
//  Created by Edward Warrender on 28/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PXGoal : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * goalType;
@property (nonatomic, retain) NSString * parseObjectId;
@property (nonatomic, retain) NSNumber * parseUpdated;
@property (nonatomic, retain) NSNumber * recurring;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * targetMax;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSString * feedbackMessageID;
@property (nonatomic, retain) NSNumber * feedbackRecursion;

@end
