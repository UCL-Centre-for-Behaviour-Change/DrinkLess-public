//
//  PXActionPlanView.h
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXActionPlanView : UIView

@property (weak, nonatomic) IBOutlet UILabel *ifTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *thenTextLabel;
@property (nonatomic, getter = isCollapsed) BOOL collapsed;

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated;
- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated delay:(NSTimeInterval)delay;

@end
