//
//  PXGroupedTableView.m
//  drinkless
//
//  Created by Edward Warrender on 13/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGroupedTableView.h"
#import "PXBackgroundView.h"

static CGFloat const PXInset = 15.0;

@interface PXGroupedTableView () <UITableViewDelegate>

@property (weak, nonatomic) id <UITableViewDelegate> realDelegate;
@property (strong, nonatomic) NSMutableDictionary *dequeuedBackgroundViews;
@property (nonatomic) UIEdgeInsets defaultSeparatorInset;

@end

@implementation PXGroupedTableView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialConfiguration];
}

- (void)initialConfiguration {
    self.defaultSeparatorInset = self.separatorInset;
    self.separatorInset = UIEdgeInsetsMake(0.0, PXInset * 2.0, 0.0, PXInset * 2.0);
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Forwarding

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    if (delegate != self) {
        self.realDelegate = delegate;
        [super setDelegate:self];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return ([super respondsToSelector:aSelector] ||
            [self.realDelegate respondsToSelector:aSelector]);
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.realDelegate respondsToSelector:aSelector]) {
        return self.realDelegate;
    }
    return nil;
}

#pragma mark - Updating

- (void)reloadData {
    [super reloadData];
    [self updateVisibleCells];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self updateVisibleCells];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self updateVisibleCells];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:cell atIndexPath:indexPath];
    
    if ([self.realDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [self.realDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell.backgroundView isKindOfClass:[PXBackgroundView class]]) {
        PXBackgroundView *backgroundView = (PXBackgroundView *)cell.backgroundView;
        NSMutableArray *views = self.dequeuedBackgroundViews[@(backgroundView.position)];
        if (!views) {
            views = @[backgroundView].mutableCopy;
            self.dequeuedBackgroundViews[@(backgroundView.position)] = views;
        } else {
            [views addObject:backgroundView];
        }
        cell.backgroundView = nil;
    }
}

- (void)updateVisibleCells {
    for (UITableViewCell *cell in self.visibleCells) {
        NSIndexPath *indexPath = [self indexPathForCell:cell];
        [self configureCell:cell atIndexPath:indexPath];
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (UIEdgeInsetsEqualToEdgeInsets(cell.separatorInset, self.separatorInset)) {
        cell.separatorInset = self.defaultSeparatorInset;
    }
    PXBackgroundViewPosition position = [self positionForIndexPath:indexPath];
    if ([cell.backgroundView isKindOfClass:[PXBackgroundView class]]) {
        PXBackgroundView *backgroundView = (PXBackgroundView *)cell.backgroundView;
        backgroundView.separatorInset = cell.separatorInset;
        if (backgroundView.position == position) {
            return;
        }
    }
    NSMutableArray *views = self.dequeuedBackgroundViews[@(position)];
    PXBackgroundView *backgroundView;
    if (views.count > 0) {
        backgroundView = views[0];
        [views removeObjectAtIndex:0];
    } else {
        backgroundView = [[PXBackgroundView alloc] initWithPosition:position];
        backgroundView.backgroundColor = self.backgroundColor;
        backgroundView.separatorColor = self.separatorColor;
    }
    backgroundView.separatorInset = cell.separatorInset;
    cell.backgroundView = backgroundView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.frame.size.width - (PXInset * 2.0);
    for (UITableViewCell *cell in self.visibleCells) {
        if (cell.frame.origin.x != PXInset || cell.frame.size.width != width) {
            cell.frame = CGRectMake(PXInset, cell.frame.origin.y, width, cell.frame.size.height);
        }
    }
}

- (PXBackgroundViewPosition)positionForIndexPath:(NSIndexPath *)indexPath {
    if ([self numberOfRowsInSection:indexPath.section] == 1) {
        return PXBackgroundViewPositionSingle;
    } else if (indexPath.row == 0) {
        return PXBackgroundViewPositionTop;
    } else if (indexPath.row == [self numberOfRowsInSection:indexPath.section] - 1) {
        return PXBackgroundViewPositionBottom;
    }
    return PXBackgroundViewPositionMiddle;
}

@end
