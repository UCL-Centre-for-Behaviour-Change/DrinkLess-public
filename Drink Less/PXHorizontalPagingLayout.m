//
//  PXPagingFlowLayout/m
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXHorizontalPagingLayout.h"

static NSInteger const PXDefaultColumns = 3;
static NSInteger const PXDefaultRows = 3;
static CGFloat const PXDefaultPageMargin = 15.0;
static CGFloat const PXDefaultItemSpacing = 10.0;

@interface PXHorizontalPagingLayout ()

@property (strong, nonatomic) NSArray *allAttributes;
@property (nonatomic) CGSize itemSize;

@end

@implementation PXHorizontalPagingLayout

- (id)init {
    self = [super init];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)initialConfiguration {
    self.numberOfColumns = PXDefaultColumns;
    self.numberOfRows = PXDefaultRows;
    self.pageMargin = PXDefaultPageMargin;
    self.itemSpacing = PXDefaultItemSpacing;
}

- (void)setNumberOfRows:(NSInteger)numberOfRows
{
    _numberOfRows = numberOfRows;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    
    self.itemSize = CGSizeZero;
    
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:numberOfItems];
    for (NSInteger item = 0; item < numberOfItems; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [allAttributes addObject:attributes];
    }
    self.allAttributes = allAttributes.copy;
    
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger itemsPerPage = self.numberOfColumns * self.numberOfRows;
    self.numberOfPages = ceilf(itemCount / (CGFloat)itemsPerPage);
}

- (CGSize)itemSize {
    if (CGSizeEqualToSize(_itemSize, CGSizeZero)) {
        CGSize pageSize = self.collectionView.frame.size;
        CGFloat horizontalSpacing = self.itemSpacing * (self.numberOfColumns - 1);
        CGFloat verticalSpacing = self.itemSpacing * (self.numberOfRows - 1);
        CGFloat totalWidth = pageSize.width - (self.pageMargin * 2.0) - horizontalSpacing;
        CGFloat totalHeight = pageSize.height - (self.pageMargin * 2.0) - verticalSpacing;
        CGFloat width = totalWidth / self.numberOfColumns;
        CGFloat height = totalHeight / self.numberOfRows;
        _itemSize = CGSizeMake(width, height);
    }
    return _itemSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger itemsPerPage = self.numberOfColumns * self.numberOfRows;
    NSInteger column = indexPath.item % self.numberOfColumns;
    NSInteger row = (NSInteger)floorf(indexPath.item / self.numberOfColumns) % self.numberOfRows;
    CGFloat page = floorf(indexPath.item / (CGFloat)itemsPerPage);
    CGSize pageSize = self.collectionView.frame.size;
    CGFloat x = (page * pageSize.width) + self.pageMargin + (column * (self.itemSize.width + self.itemSpacing));
    CGFloat y = self.pageMargin + (row * (self.itemSize.height + self.itemSpacing));
    
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(x, y, self.itemSize.width, self.itemSize.height);
    return layoutAttributes;
}

- (CGSize)collectionViewContentSize {
    CGSize size = self.collectionView.bounds.size;
    size.width *= self.numberOfPages;
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *intersectingElements = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.allAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [intersectingElements addObject:attributes];
        }
    }
    return intersectingElements;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    self.currentPage = roundf(newBounds.origin.x / newBounds.size.width);
    return NO;
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated {
    CGPoint offset = self.collectionView.contentOffset;
    offset.x = self.collectionView.bounds.size.width * page;
    [self.collectionView setContentOffset:offset animated:animated];
}

#pragma mark - Properties

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    if (numberOfPages != _numberOfPages) {
        _numberOfPages = numberOfPages;
        [self.delegate horizontalPagingLayout:self changedNumberOfPages:numberOfPages];
    }
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (currentPage != _currentPage) {
        _currentPage = currentPage;
        [self.delegate horizontalPagingLayout:self changedCurrentPage:currentPage];
    }
}

@end

