//
//  PXWeekAlcoholFreeView.m
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekAlcoholFreeView.h"

@interface PXWeekAlcoholFreeView ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

@implementation PXWeekAlcoholFreeView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.valueLabel.textColor = [UIColor drinkLessGreenColor];
}

- (void)setNumberOfFreeDays:(NSInteger)numberOfFreeDays {
    _numberOfFreeDays = numberOfFreeDays;
    
    NSString *text = numberOfFreeDays == 1 ? @"Alcohol Free Day" : @"Alcohol Free Days";
    self.valueLabel.text = [NSString stringWithFormat:@"%li %@", (long)numberOfFreeDays, text];
}

@end
