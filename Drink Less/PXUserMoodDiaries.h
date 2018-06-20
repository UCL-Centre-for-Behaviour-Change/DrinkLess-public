//
//  PXUserMoodDiaries.h
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@class PXMoodDiary;

@interface PXUserMoodDiaries : NSObject <NSCoding>

+ (instancetype)loadMoodDiaries;
+ (void)deleteAllData;

@property (strong, nonatomic) NSMutableArray *moodDiaries;
@property (nonatomic, readonly) NSUInteger currentStreak;
@property (nonatomic, readonly) NSUInteger highestStreak;

- (PXMoodDiary *)fetchTodaysMoodDiary;
- (void)save;
- (void)calculateStreaks;

@end
