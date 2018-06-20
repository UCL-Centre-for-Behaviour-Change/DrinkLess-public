//
//  PXPlaceholderView.h
//  drinkless
//
//  Created by Edward Warrender on 14/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXSolidButton;

@interface PXPlaceholderViewRenamed : UIView

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet PXSolidButton *button;
@property (strong, nonatomic) IBOutlet UILabel *footerLabel;

// Use these methods which construct the layout instead of using the properties directly
- (void)setImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle footer:(NSAttributedString *)footer;
- (void)setImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle buttonTitle:(NSString *)buttonTitle footer:(NSAttributedString *)footer solid:(BOOL)solid target:(id)target action:(SEL)action;

@end
