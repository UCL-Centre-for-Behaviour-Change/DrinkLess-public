//
//  PXRateView.h
//  drinkless
//
//  Created by Edward Warrender on 10/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXRateViewDelegate;

@interface PXRateView : UIView

@property (weak, nonatomic) IBOutlet id <PXRateViewDelegate> delegate;
@property (nonatomic, getter = isHelpful) BOOL helpful;
@property (nonatomic, getter = isSelected) BOOL selected;

@end

@protocol PXRateViewDelegate <NSObject>

- (void)selectedRateView:(PXRateView *)rateView;

@end
