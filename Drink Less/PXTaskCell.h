//
//  PXTaskCell.h
//  drinkless
//
//  Created by Edward Warrender on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXTaskCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) UIColor *dotColor;
@property (nonatomic) BOOL completed;

@end
