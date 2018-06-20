//
//  PXFlipsidesViewController.m
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFlipsidesViewController.h"
#import "PXUserFlipsides.h"
#import "PXFlipside.h"
#import "PXFlipsideCell.h"
#import "PXHorizontalPagingLayout.h"
#import "PXEditFlipsideViewController.h"
#import "PXConfigureFlipsidesViewController.h"

@interface PXFlipsidesViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PXHorizontalPagingLayoutDelegate, PXEditFlipsideViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet PXHorizontalPagingLayout *layout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageControlHeightConstraint;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *configureButton;
@property (nonatomic) CGFloat originalPageControlHeight;

@end

@implementation PXFlipsidesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Flipsides";
    
    self.originalPageControlHeight = self.pageControlHeightConstraint.constant;
    self.collectionView.allowsMultipleSelection = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.userFlipsides.createdFlipsides.count == 0) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.rightBarButtonItem = self.configureButton;
    }
}

#pragma mark - UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PXFlipsideCell *cell = (PXFlipsideCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.positiveFlipView setOverlayHidden:YES animated:YES];
    [cell.negativeFlipView setOverlayHidden:YES animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PXFlipsideCell *cell = (PXFlipsideCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.positiveFlipView setOverlayHidden:NO animated:YES];
    [cell.negativeFlipView setOverlayHidden:NO animated:YES];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.userFlipsides.flipsides.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PXFlipside *flipside = self.userFlipsides.flipsides[indexPath.row];
    PXFlipsideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"flipsideCell" forIndexPath:indexPath];
    cell.positiveFlipView.titleLabel.text = flipside.positiveText;
    cell.negativeFlipView.titleLabel.text = flipside.negativeText;
    cell.positiveFlipView.imageView.image = flipside.positiveImage ?: [UIImage imageNamed:@"flipside-0-positive"];
    cell.negativeFlipView.imageView.image = flipside.negativeImage ?: [UIImage imageNamed:@"flipside-0-negative"];
    cell.positiveFlipView.overlayHidden = cell.isSelected;
    cell.negativeFlipView.overlayHidden = cell.isSelected;
    
    // Calling willDisplayCell manually for versions below iOS 8
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        [self collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[PXFlipsideCell class]]) {
        PXFlipsideCell *flipsideCell = (PXFlipsideCell *)cell;
        [flipsideCell animateFlipside];
    }
}

#pragma mark - PXHorizontalPagingLayoutDelegate

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout changedNumberOfPages:(NSInteger)numberOfPages {
    BOOL hasAdditionalPages = numberOfPages > 1;
    self.pageControlHeightConstraint.constant = hasAdditionalPages ? self.originalPageControlHeight : 0.0;
    self.pageControl.numberOfPages = numberOfPages;
}

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout changedCurrentPage:(NSInteger)currentPage {
    self.pageControl.currentPage = currentPage;
}

#pragma mark - PXEditFlipsideViewControllerDelegate

- (void)didCancelEditing:(PXEditFlipsideViewController *)editFlipsideViewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didFinishEditing:(PXEditFlipsideViewController *)editFlipsideViewController {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.userFlipsides.flipsides.count inSection:0];
    [self.userFlipsides.createdFlipsides addObject:editFlipsideViewController.flipside];
    [self.userFlipsides save];
    self.userFlipsides.flipsides = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        } completion:^(BOOL finished) {
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }];
    }];
}

#pragma mark - Actions

- (IBAction)pageControlChanged:(UIPageControl *)pageControl {
    NSInteger previousPage = self.layout.currentPage;
    [self.layout scrollToPage:pageControl.currentPage animated:YES];
    // Restore previous page as the delegate handles it (otherwise it will jump)
    pageControl.currentPage = previousPage;
}

- (IBAction)unwindToFlipsides:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"configuredFlipsides"]) {
        if (self.userFlipsides.hasChanges) {
            self.userFlipsides.changed = NO;
            [self.userFlipsides save];
            self.userFlipsides.flipsides = nil;
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addFlipside"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PXEditFlipsideViewController *editFlipsideVC = (PXEditFlipsideViewController *)navigationController.topViewController;
        editFlipsideVC.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"configureFlipsides"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PXConfigureFlipsidesViewController *configureFlipsidesVC = (PXConfigureFlipsidesViewController *)navigationController.topViewController;
        configureFlipsidesVC.userFlipsides = self.userFlipsides;
    }
}

@end
