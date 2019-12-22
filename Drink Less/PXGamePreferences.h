//
//  PXGamePreferences.h
//  drinkless
//
//  Created by Edward Warrender on 27/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXGamePreferences : NSObject

+ (BOOL)isPushTall;
+ (NSString *)pushOrientation;
+ (NSString *)pullOrientation;
+ (NSString *)pushParenthetical;
+ (NSString *)pullParenthetical;
@end
