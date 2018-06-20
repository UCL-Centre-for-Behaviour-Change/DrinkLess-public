//
//  PXWeekFiguresView.m
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekFiguresView.h"
#import "PXWeekSummaryFormatter.h"

@interface PXWeekFiguresView ()

@property (weak, nonatomic) IBOutlet UILabel *thisWeekLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLastWeekLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitsValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitsChangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *spendingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *spendingValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *spendingChangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *caloriesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *caloriesValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *caloriesChangeLabel;

@end

@implementation PXWeekFiguresView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    for (UILabel *label in @[self.unitsValueLabel, self.spendingValueLabel, self.caloriesValueLabel]) {
        label.textColor = [UIColor drinkLessGreenColor];
    }
}

- (void)setWeekSummary:(PXWeekSummary *)weekSummary {
    _weekSummary = weekSummary;
    
    PXWeekSummaryFormatter *formatter = [[PXWeekSummaryFormatter alloc] initWithWeekSummary:weekSummary];
    
    self.unitsValueLabel.text = formatter.unitsValue;
    self.unitsChangeLabel.text = formatter.unitsChange;
    self.caloriesValueLabel.text = formatter.caloriesValue;
    self.caloriesChangeLabel.text = formatter.caloriesChange;
    self.spendingValueLabel.text = formatter.spendingValue;
    self.spendingChangeLabel.text = formatter.spendingChange;
}

@end
