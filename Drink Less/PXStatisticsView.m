//
//  PXStatisticsView.m
//  drinkless
//
//  Created by Edward Warrender on 23/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStatisticsView.h"
#import "PXWeekSummaryFormatter.h"

@interface PXStatisticsView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *topTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *topValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightValueLabel;
@property (strong, nonatomic) PXWeekSummaryFormatter *formatter;

@end

@implementation PXStatisticsView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.topValueLabel.textColor = [UIColor drinkLessOrangeColor];
    self.rightValueLabel.textColor = [UIColor drinkLessOrangeColor];
}

- (void)setAllStatistics:(PXAllStatistics *)allStatistics {
    _allStatistics = allStatistics;
    
    self.formatter = [[PXWeekSummaryFormatter alloc] initWithWeekSummary:allStatistics.thisWeekSummary];
}

- (void)setConsumptionType:(PXConsumptionType)consumptionType {
    _consumptionType = consumptionType;
    
    switch (consumptionType) {
        case PXConsumptionTypeUnits:
            self.titleLabel.text = @"Units from alcohol";
            self.topValueLabel.text = self.formatter.unitsValue;
            self.leftValueLabel.text = self.formatter.unitsChange;
            self.rightValueLabel.text = [self.formatter formatUnits:self.allStatistics.allUnits];
            break;
        case PXConsumptionTypeCalories:
            self.titleLabel.text = @"Calories from alcohol";
            self.topValueLabel.text = self.formatter.caloriesValue;
            self.leftValueLabel.text = self.formatter.caloriesChange;
            self.rightValueLabel.text = [self.formatter formatCalories:self.allStatistics.allCalories];
            break;
        case PXConsumptionTypeSpending:
            self.titleLabel.text = @"Spend on alcohol";
            self.topValueLabel.text = self.formatter.spendingValue;
            self.leftValueLabel.text = self.formatter.spendingChange;
            self.rightValueLabel.text = [self.formatter formatSpending:self.allStatistics.allSpending];
            break;
        default:
            break;
    }
}

@end
