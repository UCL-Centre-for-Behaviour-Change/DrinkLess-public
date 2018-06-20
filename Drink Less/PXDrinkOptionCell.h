//
//  PXDrinkOptionCell.h
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXDrinkOptionCellDelegate;

@interface PXDrinkOptionCell : UICollectionViewCell

@property (weak, nonatomic) id <PXDrinkOptionCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *abvLabel;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, getter = isShaking) BOOL shaking;

@end

@protocol PXDrinkOptionCellDelegate <NSObject>

- (void)drinkOptionCell:(PXDrinkOptionCell *)cell pressedDelete:(id)sender;

@end
