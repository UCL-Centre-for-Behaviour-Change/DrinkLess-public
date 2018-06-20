//
//  PXFlipView.h
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXFlipView : UIView

+ (instancetype)flipViewPositive:(BOOL)positive;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, getter = isOverlayHidden) BOOL overlayHidden;

- (void)setOverlayHidden:(BOOL)overlayHidden animated:(BOOL)animated;

@end
