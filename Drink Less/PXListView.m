//
//  PXListView.m
//  drinkless
//
//  Created by Edward Warrender on 12/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXListView.h"

@implementation PXListView

+ (instancetype)listView {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    return [nib instantiateWithOwner:nil options:nil].firstObject;
}

@end
