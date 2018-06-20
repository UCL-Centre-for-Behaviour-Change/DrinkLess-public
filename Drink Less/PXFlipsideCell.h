//
//  PXFlipsideCell.h
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXFlipView.h"

@interface PXFlipsideCell : UICollectionViewCell

@property (strong, nonatomic) PXFlipView *positiveFlipView;
@property (strong, nonatomic) PXFlipView *negativeFlipView;

- (void)animateFlipside;

@end
