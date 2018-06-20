//
//  PXBlurAnimationController.h
//  drinkless
//
//  Created by Edward Warrender on 18/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@protocol PXBlurAnimationControllerDelegate;

@interface PXBlurAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

+ (instancetype)animationControllerPresenting:(BOOL)presenting delegate:(id)delegate;

@property (weak, nonatomic) id <PXBlurAnimationControllerDelegate> delegate;

@end

@protocol PXBlurAnimationControllerDelegate <NSObject>
@optional

- (void)animationControllerDidCaptureScreenshot:(UIImage *)screenshot;

@end
