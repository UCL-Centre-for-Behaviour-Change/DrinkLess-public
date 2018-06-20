//
//  PXStepGuideCell.h
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXStepGuideCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (nonatomic, getter=hasCompleted) BOOL completed;
@property (nonatomic, getter=isVivid) BOOL vivid;

@end
