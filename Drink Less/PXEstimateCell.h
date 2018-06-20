//
//  PXEstimateCell.h
//  drinkless
//
//  Created by Edward Warrender on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXGaugeView.h"

@protocol PXEstimateCellDelegate;

@interface PXEstimateCell : UITableViewCell

@property (weak, nonatomic) id <PXEstimateCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet PXGaugeView *gaugeView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;

- (void)startHintAnimation;

@end

@protocol PXEstimateCellDelegate <NSObject>

- (void)updatedGaugeForEstimateCell:(PXEstimateCell *)cell;

@end
