//
//  PXIdentityContradictionsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 05/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityContradictionsViewController.h"
#import "PXUserIdentity.h"
#import "PXIdentityExampleViewController.h"
#import "PXContradictionCell.h"

@interface PXIdentityContradictionsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *instructionsScrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) PXContradictionCell *templateCell;

@end

@implementation PXIdentityContradictionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"I am";
    self.screenName = @"Identity contradictions";
    
    UIView *containerView = self.imageView.superview;
    containerView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    
    // Default to the Smiley avatar
    self.imageView.image = self.userIdentity.photo ?: [UIImage imageNamed:@"Smiley"];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.collectionView.allowsMultipleSelection = YES;
    
    UINib *nib = [PXContradictionCell nib];
    self.templateCell = [nib instantiateWithOwner:nil options:nil].firstObject;
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:self.templateCell.reuseIdentifier];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sometimes drinking can mean that we behave in ways that do not fit with what we value about ourselves.\n\nHave a think about which of these values you struggle with when you’ve been drinking too much. Tap to highlight them if you’d like."
                                                    message:nil
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSString *title in self.userIdentity.contradictedAspects) {
        NSInteger index = [self.userIdentity.importantAspects indexOfObject:title];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(showFinalInstructions) withObject:nil afterDelay:3.0];
}

- (void)showFinalInstructions {
    UIScrollView *scrollView = self.instructionsScrollView;
    CGFloat maxOffsetY = scrollView.contentSize.height - scrollView.bounds.size.height;
    [UIView animateWithDuration:3.0 animations:^{
        scrollView.contentOffset = CGPointMake(0.0, maxOffsetY);
    } completion:^(BOOL finished) {
        [scrollView flashScrollIndicators];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.userIdentity save];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
    
    // Inset to create bottom aligned collection view if there is space
    CGFloat height = self.collectionView.contentSize.height;
    CGFloat verticalSpace = self.collectionView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.collectionView.contentInset = UIEdgeInsetsMake(verticalSpace, 0.0, 0.0, 0.0);
        self.collectionView.scrollEnabled = NO;
    } else {
        self.collectionView.contentInset = UIEdgeInsetsZero;
        self.collectionView.scrollEnabled = YES;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.userIdentity.importantAspects.count;
}

- (void)configureCell:(PXContradictionCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *aspect = self.userIdentity.importantAspects[indexPath.item];
    cell.titleLabel.text = aspect;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PXContradictionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"contradictionCell" forIndexPath:indexPath];
    [self configureCell:cell forItemAtIndexPath:indexPath];
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *aspect = self.userIdentity.importantAspects[indexPath.item];
    [self.userIdentity.contradictedAspects addObject:aspect];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *aspect = self.userIdentity.importantAspects[indexPath.item];
    [self.userIdentity.contradictedAspects removeObject:aspect];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:self.templateCell forItemAtIndexPath:indexPath];
    return [self.templateCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showExamples"]) {
        PXIdentityExampleViewController *examplesVC = segue.destinationViewController;
        examplesVC.userIdentity = self.userIdentity;
    }
}

@end
