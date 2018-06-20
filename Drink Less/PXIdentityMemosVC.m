//
//  PXIdentityMemosVC.m
//  drinkless
//
//  Created by Chris on 26/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityMemosVC.h"
#import "PXMemoManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIViewController+RecordMemo.h"

@interface PXIdentityMemosVC () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PXIdentityMemosVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.presentingViewController) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    } else {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)playMemo:(PXMemo *)memo {
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:memo.filePath]];
    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
}

- (void)donePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PXMemoManager sharedInstance] numberOfMemos] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    BOOL isButton = (indexPath.row == 0);
    cell.textLabel.textColor = isButton ? self.tableView.tintColor : [UIColor blackColor];
    
    if (isButton) {
        cell.textLabel.text = @"Add new memo";
    } else {
        PXMemo *memo = [[PXMemoManager sharedInstance] memoAtIndex:indexPath.row - 1];
        cell.textLabel.text = memo.memoName;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL isButton = (indexPath.row == 0);
    if (isButton) {
        [self recordVideoMemo];
    } else {
        PXMemo *memo = [[PXMemoManager sharedInstance] memoAtIndex:indexPath.row - 1];
        if (tableView.isEditing) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Edit memo name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *textField = [alertView textFieldAtIndex:0];
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.text = memo.memoName;
            [alertView show];
            return;
        } else {
            [self playMemo:memo];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isButton = (indexPath.row == 0);
    return !isButton;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[PXMemoManager sharedInstance] deleteMemoAtIndex:indexPath.row - 1];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        PXMemo *memo = [[PXMemoManager sharedInstance] memoAtIndex:indexPath.row - 1];
        NSString *title = [alertView textFieldAtIndex:0].text;
        memo.memoName = title;
        [[PXMemoManager sharedInstance] save];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
