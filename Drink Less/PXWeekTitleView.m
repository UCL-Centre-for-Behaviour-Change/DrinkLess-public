//
//  PXWeekTitleView.m
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekTitleView.h"

@interface PXWeekTitleView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation PXWeekTitleView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.textColor = [UIColor whiteColor];
    self.subtitleLabel.textColor = [UIColor drinkLessLightGreenColor];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"d MMMM";
}

- (void)setDate:(NSDate *)date {
    _date = date;
    
    self.subtitleLabel.text = [NSString stringWithFormat:@"Ending %@", [self.dateFormatter stringFromDate:date]];
}

@end
