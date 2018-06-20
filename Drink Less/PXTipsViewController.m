//
//  PXTipsViewController.m
//  drinkless
//
//  Created by Greg Plumbly on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTipsViewController.h"
#import "PXWebViewController.h"

@interface PXTipsViewController ()

@property (nonatomic, strong) NSArray *navItemsArray;

@end

@implementation PXTipsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"PXTipsNav" ofType:@"plist"];
    self.navItemsArray = [[NSArray alloc] initWithContentsOfFile:filepath];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Useful information menu"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.navItemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settings_cell" forIndexPath:indexPath];
    NSDictionary *dictionary = self.navItemsArray[indexPath.row];
    cell.textLabel.text = dictionary[@"title"];
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"show_HTML"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        NSDictionary *dictionary = self.navItemsArray[indexPath.row];
        PXWebViewController *webViewController = segue.destinationViewController;
        webViewController.resource = dictionary[@"resource"];
        webViewController.title = dictionary[@"title"];
    }
}

@end
