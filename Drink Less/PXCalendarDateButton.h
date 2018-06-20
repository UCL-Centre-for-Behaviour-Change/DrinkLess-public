//
//  PXCalendarDateButton.h
//  TestProject
//
//  Created by Chris Pritchard on 25/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXCalendarDateButton : UIButton

@property (nonatomic) NSInteger iCoord;
@property (nonatomic) NSInteger jCoord;
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIView *selectedView;

@end
