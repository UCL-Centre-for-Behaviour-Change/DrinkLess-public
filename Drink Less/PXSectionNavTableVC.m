//
//  ProgressNavTableViewController.m
//  nav
//
//  Created by Greg Plumbly on 06/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXSectionNavTableVC.h"
#import "PXWebViewController.h"

@implementation PXSectionNavTableVC

- (NSArray *)navItemsArray {
    if (!_navItemsArray) {
        NSString *filepath = [[NSBundle mainBundle] pathForResource:self.navigationFilename ofType:@"plist"];
        _navItemsArray = [[NSArray alloc] initWithContentsOfFile:filepath];
    }
    return _navItemsArray;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.navItemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NavCell" forIndexPath:indexPath];
    NSDictionary *dict = self.navItemsArray[indexPath.row];
    cell.textLabel.text = dict[@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:self.storyboardName bundle:nil];
    NSDictionary *dict = self.navItemsArray[indexPath.row];
    
    NSString *identifier = dict[@"vc"];
    if ([self shouldNavigateWithIdentifier:identifier]) {
        UIViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:identifier];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    
    NSString *resource = dict[@"resource"];
    if (resource.length != 0) {
        PXWebViewController *webViewController = [[PXWebViewController alloc] initWithResource:resource];
        webViewController.view.backgroundColor = [UIColor whiteColor];
        webViewController.title = dict[@"title"];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)shouldNavigateWithIdentifier:(NSString *)identifier {
    return identifier.length != 0;
}

@end
