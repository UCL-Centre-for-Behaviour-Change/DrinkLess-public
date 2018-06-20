//
//  PXDrinkOptionCell.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkOptionCell.h"
#import "PXDashedBackgroundView.h"

@interface PXDrinkOptionCell ()

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation PXDrinkOptionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.abvLabel.textColor = [UIColor drinkLessGreenColor];
    
    PXDashedBackgroundView *backgroundView = [[PXDashedBackgroundView alloc] init];
    backgroundView.fillColor = [UIColor whiteColor];
    backgroundView.cornerRadius = 5.0;
    backgroundView.lineWidth = 1.0;
    backgroundView.strokeColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    backgroundView.dashed = YES;
    self.backgroundView = backgroundView;
    
    PXDashedBackgroundView *selectedBackgroundView = [[PXDashedBackgroundView alloc] init];
    selectedBackgroundView.fillColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    selectedBackgroundView.cornerRadius = 5.0;
    self.selectedBackgroundView = selectedBackgroundView;
    
    self.deleteButton.layer.cornerRadius = CGRectGetMidX(self.deleteButton.bounds);
    self.deleteButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.deleteButton.layer.shouldRasterize = YES;
    self.editing = NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.isHidden && self.isEditing && CGRectContainsPoint(self.deleteButton.frame, point)) {
        return self.deleteButton;
    }
    return [super hitTest:point withEvent:event];
}

- (IBAction)deletePressed:(id)sender {
    [self.delegate drinkOptionCell:self pressedDelete:sender];
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
    
    self.backgroundView.alpha = editing;
    self.deleteButton.alpha = editing;
    self.deleteButton.transform = editing ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.1, 0.1);
    self.backgroundView.frame = editing ? self.bounds : CGRectInset(self.bounds, 5.0, 5.0);
    [self.backgroundView layoutIfNeeded];
}

#pragma mark - Shaking

- (CGFloat)randomPixel {
    // -1.0 to 1.0 pixels
    CGFloat decimal = ((NSInteger)arc4random_uniform(21) - 10) / 10.0;
    return decimal;
}

- (CGFloat)randomAngle {
    // 1.0 to 2.0 degrees
    CGFloat decimal = (arc4random_uniform(6) + 5) / 10.0;
    return (M_PI / 180.0) * 2.0 * decimal;
}

- (CGAffineTransform)randomShakeTransformClockwise:(BOOL)clockwise {
    CGFloat randomAngle = [self randomAngle];
    if (!clockwise) randomAngle *= -1.0;
    CGAffineTransform rotation = CGAffineTransformRotate(CGAffineTransformIdentity, randomAngle);
    CGAffineTransform translation = CGAffineTransformMakeTranslation([self randomPixel], [self randomPixel]);
    return CGAffineTransformConcat(rotation, translation);
}

- (void)setShaking:(BOOL)shaking {
    _shaking = shaking;
    if (shaking) {
        if (![self.layer.animationKeys containsObject:@"transform"]) {
            [UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction animations:^{
                [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
                    self.transform = [self randomShakeTransformClockwise:YES];
                }];
                [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
                    self.transform = CGAffineTransformIdentity;
                }];
                [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.25 animations:^{
                    self.transform = [self randomShakeTransformClockwise:NO];
                }];
                [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
                    self.transform = CGAffineTransformIdentity;
                }];
            } completion:NULL];
        }
    } else {
        [self.layer removeAnimationForKey:@"transform"];
    }
}

@end
