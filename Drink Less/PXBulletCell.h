//
//  PXBulletCell.h
//  drinkless
//
//  Created by Edward Warrender on 04/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXBulletCellDelegate;

@interface PXBulletCell : UITableViewCell

@property (strong, nonatomic) UIColor *dotColor;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet id <PXBulletCellDelegate> delegate;

@end

@protocol PXBulletCellDelegate <NSObject>

- (void)insertLine:(NSString *)line fromCell:(PXBulletCell *)cell;
- (void)deleteLine:(NSString *)line fromCell:(PXBulletCell *)cell;
- (void)changedTextViewInCell:(PXBulletCell *)cell;

@end
