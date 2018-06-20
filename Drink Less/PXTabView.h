//
//  PXTabView.h
//  drinkless
//
//  Created by Edward Warrender on 30/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXTabView : UIControl

@property (strong, nonatomic) NSArray *titles;
@property (nonatomic) NSInteger selectedIndex;

@end
