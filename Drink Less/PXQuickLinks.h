//
//  PXQuickLinks.h
//  drinkless
//
//  Created by Edward Warrender on 27/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXQuickLinks : NSObject

@property (strong, nonatomic) NSArray *links;

- (void)reload;

@end
