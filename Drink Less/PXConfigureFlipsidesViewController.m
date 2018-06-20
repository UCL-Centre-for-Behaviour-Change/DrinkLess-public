//
//  PXConfigureFlipsidesViewController.m
//  drinkless
//
//  Created by Edward Warrender on 12/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXConfigureFlipsidesViewController.h"
#import "PXUserFlipsides.h"
#import "PXFlipside.h"
#import "PXEditFlipsideViewController.h"
#import "PXConfigureFlipsideCell.h"

@interface PXConfigureFlipsidesViewController () <PXEditFlipsideViewControllerDelegate>

@end

@implementation PXConfigureFlipsidesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Configure flipsides"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userFlipsides.createdFlipsides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXFlipside *flipside = self.userFlipsides.createdFlipsides[indexPath.row];
    PXConfigureFlipsideCell *cell = [tableView dequeueReusableCellWithIdentifier:@"configureCell" forIndexPath:indexPath];
    cell.positiveLabel.text = flipside.positiveText;
    cell.negativeLabel.text = flipside.negativeText;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.userFlipsides removeFlipsideAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    if (self.userFlipsides.createdFlipsides.count == 0) {
        [self performSegueWithIdentifier:@"configuredFlipsides" sender:nil];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSObject *object = self.userFlipsides.createdFlipsides[fromIndexPath.row];
    [self.userFlipsides.createdFlipsides removeObject:object];
    [self.userFlipsides.createdFlipsides insertObject:object atIndex:toIndexPath.row];
    self.userFlipsides.changed = YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editFlipside"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        PXEditFlipsideViewController *editFlipsideVC = segue.destinationViewController;
        editFlipsideVC.flipside = self.userFlipsides.createdFlipsides[indexPath.row];
        editFlipsideVC.delegate = self;
    }
}

#pragma mark - PXEditFlipsideViewControllerDelegate

- (void)didCancelEditing:(PXEditFlipsideViewController *)editFlipsideViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didFinishEditing:(PXEditFlipsideViewController *)editFlipsideViewController {
    [self.navigationController popViewControllerAnimated:YES];
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    [self.userFlipsides replaceFlipsideAtIndex:indexPath.row withFlipside:editFlipsideViewController.flipside];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
