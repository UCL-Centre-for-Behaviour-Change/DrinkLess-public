//
//  PXProgressViewController.m
//  drinkless
//
//  Created by Edward Warrender on 04/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXActivitiesViewController.h"
#import "PXActivitiesCell.h"
#import "PXGroupsManager.h"
#import "PXStepGuide.h"
#import "PXTipView.h"

@interface PXActivitiesViewController ()

@property (strong, nonatomic) NSArray *menuItems;
@property (strong, nonatomic) PXTipView *tipView;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@end

@implementation PXActivitiesViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(pressedHelp:)];
    

}

- (void)pressedHelp:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *viewController = [storyboard instantiateInitialViewController];
    [self presentViewController:viewController animated:YES completion:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ActivitiesMenu" ofType:@"plist"];
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
    PXActivitiesCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"activitiesCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:dictionary[@"iconName"]];
    cell.titleLabel.text = dictionary[@"title"];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dictionary = self.menuItems[indexPath.row];
    NSString *identifier = dictionary[@"identifier"];
    UIViewController *viewController;
    if ([identifier isEqualToString:@"game"]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PXGames" bundle:nil];
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"PXCardMenuViewController"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Activities" bundle:nil];
        viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    }
    [self.navigationController pushViewController:viewController animated:YES];
    
    if (![identifier isEqualToString:@"PXGoalsNavTVC"]) {
        [PXStepGuide completeStepWithID:@"explore"];
    }
}

@end
