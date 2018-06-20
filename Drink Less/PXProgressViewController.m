//
//  PXProgressViewController.m
//  drinkless
//
//  Created by Edward Warrender on 04/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXProgressViewController.h"
#import "PXProgressCell.h"
#import "PXGroupsManager.h"
#import "PXStepGuide.h"
#import "PXTipView.h"

@interface PXProgressViewController ()

@property (strong, nonatomic) NSArray *menuItems;
@property (strong, nonatomic) PXTipView *tipView;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@end

@implementation PXProgressViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ProgressMenu" ofType:@"plist"];
    NSArray *items = [NSMutableArray arrayWithContentsOfFile:path];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSDictionary *group = evaluatedObject[@"group"];
        
        if (group) {
            
            NSString *key = group[@"key"];
            id value = group[@"value"];
            PXGroupsManager *groupsManager = [PXGroupsManager sharedManager];
            
            if ([groupsManager respondsToSelector:NSSelectorFromString(key)]) {
                return [[groupsManager valueForKey:key] isEqual:value];
            }
        }
        
        return YES;
    }];
    
    self.menuItems = [items filteredArrayUsingPredicate:predicate];
    [self.collectionView reloadData];
    
    self.tipView = [[PXTipView alloc] initWithFrame:CGRectMake(0, -43, self.view.frame.size.width, 43)];
    [self.view addSubview:self.tipView];
    [self.tipView showTipToConstant:43];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dictionary = self.menuItems[indexPath.row];
    PXProgressCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"progressCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:dictionary[@"iconName"]];
    cell.titleLabel.text = dictionary[@"title"];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dictionary = self.menuItems[indexPath.row];
    NSString *identifier = dictionary[@"identifier"];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Progress" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    [self.navigationController pushViewController:viewController animated:YES];
    
    if (![identifier isEqualToString:@"PXGoalsNavTVC"]) {
        [PXStepGuide completeStepWithID:@"explore"];
    }
}

@end
