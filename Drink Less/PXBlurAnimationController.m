//
//  PXBlurAnimationController.m
//  drinkless
//
//  Created by Edward Warrender on 18/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXBlurAnimationController.h"
#import "UIImageEffects.h"

@interface PXBlurAnimationController ()

@property (nonatomic, getter=isPresenting) BOOL presenting;

@end

@implementation PXBlurAnimationController

+ (instancetype)animationControllerPresenting:(BOOL)presenting delegate:(id)delegate {
    PXBlurAnimationController *animationController = [[self alloc] init];
    animationController.presenting = presenting;
    animationController.delegate = delegate;
    return animationController;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    if (self.presenting) {
        if ([self.delegate respondsToSelector:@selector(animationControllerDidCaptureScreenshot:)]) {
            UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
            UIImage *screenshot = [self.class screenshotView:fromViewController.view];
            [self.delegate animationControllerDidCaptureScreenshot:screenshot];
        }
        
        toView.frame = containerView.bounds;
        toView.alpha = 0.0;
        [containerView addSubview:toView];
        
        [UIView animateWithDuration:duration animations:^{
            toView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            fromView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

+ (UIImage *)screenshotView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImageEffects imageByApplyingBlurToImage:image withRadius:20.0 tintColor:[UIColor colorWithWhite:0.0 alpha:0.65] saturationDeltaFactor:1.0 maskImage:nil];
}

@end
