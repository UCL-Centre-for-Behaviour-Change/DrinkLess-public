//
//  PXGoalsHeader.h
//  drinkless
//
//  Created by Edward Warrender on 18/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXGoalsHeader : NSObject

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)animateAppearance;

@end
