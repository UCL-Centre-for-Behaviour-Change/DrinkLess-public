//
//  ProgressNavTableViewController.h
//  nav
//
//  Created by Greg Plumbly on 06/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXSectionNavTableVC : UITableViewController

@property (nonatomic, strong) NSString *navigationFilename;
@property (nonatomic, strong) NSString *storyboardName;
@property (nonatomic, strong) NSArray *navItemsArray;

- (BOOL)shouldNavigateWithIdentifier:(NSString *)identifier;

@end
