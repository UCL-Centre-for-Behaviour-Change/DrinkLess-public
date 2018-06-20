//
//  PXIdentityExampleViewController.m
//  drinkless
//
//  Created by Edward Warrender on 05/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityExampleViewController.h"
#import "PXUserIdentity.h"
#import "PXExampleCell.h"
#import "PXHorizontalPagingLayout.h"

@interface PXIdentityExampleViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PXHorizontalPagingLayoutDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet PXHorizontalPagingLayout *layout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageControlHeightConstraint;
@property (nonatomic) CGFloat originalPageControlHeight;
@property (strong, nonatomic) NSString *originalAbout;

@end

@implementation PXIdentityExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"I am";
    self.screenName = @"Identity example";
    
    self.view.layer.contents = (id)[UIImage imageNamed:@"radialGradient"].CGImage;
    
    self.originalPageControlHeight = self.pageControlHeightConstraint.constant;
    self.originalAbout = self.aboutLabel.text;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.userIdentity.exampleContradictions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *contradiction = self.userIdentity.exampleContradictions[indexPath.item];
    PXExampleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"exampleCell" forIndexPath:indexPath];
    cell.titleLabel.text = contradiction[@"title"];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *contradiction = self.userIdentity.exampleContradictions[indexPath.item];
    self.aboutLabel.text = contradiction[@"about"];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.aboutLabel.text = self.originalAbout;
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

#pragma mark - Actions

- (IBAction)pageControlChanged:(UIPageControl *)pageControl {
    NSInteger previousPage = self.layout.currentPage;
    [self.layout scrollToPage:pageControl.currentPage animated:YES];
    // Restore previous page as the delegate handles it (otherwise it will jump)
    pageControl.currentPage = previousPage;
}

- (IBAction)pressedRestart:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

@end
