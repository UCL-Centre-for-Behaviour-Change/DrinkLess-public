//
//  PXBalloonView.h
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXBalloonView : UIView

- (void)resetWithCompletion:(void (^)(void))completion;
- (void)inflateToCapacity:(CGFloat)capacity completion:(void (^)(void))completion;
- (void)explodeWithCompletion:(void (^)(void))completion;
- (void)collectWithCompletion:(void (^)(void))completion;

@end
