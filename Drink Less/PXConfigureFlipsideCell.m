//
//  PXConfigureFlipsideCell.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXConfigureFlipsideCell.h"

@interface PXConfigureFlipsideCell ()

@property (weak, nonatomic) IBOutlet UILabel *positiveTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *negativeTitleLabel;

@end

@implementation PXConfigureFlipsideCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.positiveTitleLabel.textColor = [UIColor drinkLessGreenColor];
    self.negativeTitleLabel.textColor = [UIColor goalRedColor];
}

@end
