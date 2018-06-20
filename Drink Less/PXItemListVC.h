//
//  PXPopoverListVC.h
//  Drink Less
//
//  Created by Chris Pritchard on 09/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXItemListVC;

@protocol PXItemListVCDelegate <NSObject>
- (void)itemListVC:(PXItemListVC*)itemListVC chosenIndex:(NSInteger)chosenIndex;
@end

@interface PXItemListVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id <PXItemListVCDelegate> delegate;
@property (nonatomic, strong) NSArray* itemsArray;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) NSInteger sectionIndex;

@end
