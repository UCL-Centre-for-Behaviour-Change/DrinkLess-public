//
//  PXCoreDataManager.h
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PXDrinkRecord;

@interface PXCoreDataManager : NSObject

+ (instancetype)sharedManager;
+ (NSManagedObjectContext *)temporaryContext;
- (void)loadDatabase;
- (void)resetData;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
