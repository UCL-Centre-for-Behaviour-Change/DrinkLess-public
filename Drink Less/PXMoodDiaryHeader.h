//
//  PXMoodDiaryHeader.h
//  drinkless
//
//  Created by Edward Warrender on 05/11/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXMoodDiaryHeader : NSObject

@property (weak, nonatomic) IBOutlet UIView *explanationView;
@property (weak, nonatomic) IBOutlet UIView *completedView;

+ (instancetype)moodDiaryHeader;

@end
