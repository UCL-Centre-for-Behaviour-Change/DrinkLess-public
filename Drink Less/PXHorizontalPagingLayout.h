//
//  PXHorizontalPagingLayout.h
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXHorizontalPagingLayoutDelegate;

@interface PXHorizontalPagingLayout : UICollectionViewLayout

@property (weak, nonatomic) IBOutlet id <PXHorizontalPagingLayoutDelegate> delegate;
@property (nonatomic, readonly) NSInteger numberOfPages;
@property (nonatomic, readonly) NSInteger currentPage;
@property (nonatomic) IBInspectable NSInteger numberOfColumns;
@property (nonatomic) IBInspectable NSInteger numberOfRows;
@property (nonatomic) IBInspectable CGFloat pageMargin;
@property (nonatomic) IBInspectable CGFloat itemSpacing;

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;

@end

@protocol PXHorizontalPagingLayoutDelegate <NSObject>

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout
          changedNumberOfPages:(NSInteger)numberOfPages;

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout
            changedCurrentPage:(NSInteger)currentPage;

@end
