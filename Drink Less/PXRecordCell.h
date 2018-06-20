//
//  PXRecordCell.h
//  drinkless
//
//  Created by Edward Warrender on 07/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXQuantityControl.h"
#import "PXNumberFieldDelegate.h"

typedef NS_ENUM(NSInteger, PXFormatType) {
    PXFormatTypePercentage,
    PXFormatTypeCurrency,
    PXFormatTypeInteger
};

@interface PXRecordCell : UITableViewCell

@property (weak, nonatomic) UIImage *iconImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISwitch *toggleSwitch;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet PXQuantityControl *quantityControl;
@property (strong, nonatomic) PXNumberFieldDelegate *numberFieldDelegate;
@property (nonatomic) PXFormatType formatType;

@end
