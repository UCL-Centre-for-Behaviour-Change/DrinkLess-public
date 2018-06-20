//
//  PXSliderCell.h
//  drinkless
//
//  Created by Greg Plumbly on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXSliderCellDelegate;

@interface PXSliderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet id <PXSliderCellDelegate> delegate;

@end

@protocol PXSliderCellDelegate <NSObject>

- (void)sliderCellChangedValue:(PXSliderCell *)cell;

@end

