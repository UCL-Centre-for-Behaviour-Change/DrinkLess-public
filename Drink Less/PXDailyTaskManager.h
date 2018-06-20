//
//  PXDailyTaskManager.h
//  drinkless
//
//  Created by Edward Warrender on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXDailyTaskManager : NSObject

+ (PXDailyTaskManager *)sharedManager;

@property (strong, nonatomic) NSDictionary *tasks;
@property (strong, nonatomic) NSMutableArray *availableTaskIDs;
@property (strong, nonatomic) NSMutableSet *completedTaskIDs;

- (void)completeTaskWithID:(NSString *)identifier;
- (void)checkForNewTasks;
- (void)save;

@end
