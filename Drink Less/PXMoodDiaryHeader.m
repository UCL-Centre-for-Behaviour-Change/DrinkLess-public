//
//  PXMoodDiaryHeader.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMoodDiaryHeader.h"

@implementation PXMoodDiaryHeader

+ (instancetype)moodDiaryHeader {
    PXMoodDiaryHeader *moodDiaryHeader = [[self alloc] init];
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
    [nib instantiateWithOwner:moodDiaryHeader options:nil];
    return moodDiaryHeader;
}

@end
