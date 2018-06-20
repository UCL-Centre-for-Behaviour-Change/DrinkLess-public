//
//  PXEditFlipsideViewController.m
//  drinkless
//
//  Created by Edward Warrender on 12/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXEditFlipsideViewController.h"
#import "PXFlipside.h"
#import "PXSolidButton.h"
#import "PXImageStore.h"

@interface PXEditFlipsideViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet PXSolidButton *positiveButton;
@property (weak, nonatomic) IBOutlet PXSolidButton *negativeButton;
@property (weak, nonatomic) IBOutlet UITextView *positiveTextView;
@property (weak, nonatomic) IBOutlet UITextView *negativeTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) UIButton *selectedButton;

@end

@implementation PXEditFlipsideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Edit flipsides";
    
    if (!_flipside) {
        _flipside = [[PXFlipside alloc] init];
        self.title = @"New flipside";
    } else {
        self.title = @"Edit flipside";
    }

    [self.positiveButton setImage:self.flipside.positiveImage forState:UIControlStateNormal];
    [self.negativeButton setImage:self.flipside.negativeImage forState:UIControlStateNormal];
    self.positiveTextView.text = self.flipside.positiveText;
    self.negativeTextView.text = self.flipside.negativeText;
    
    [self configureButton:self.positiveButton];
    [self configureButton:self.negativeButton];
    [self configureTextView:self.positiveTextView];
    [self configureTextView:self.negativeTextView];
}

- (void)configureButton:(UIButton *)button {
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button addTarget:self action:@selector(addPhoto:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureTextView:(UITextView *)textView {
    textView.layer.cornerRadius = 3.0;
    textView.layer.masksToBounds = YES;
    textView.textContainer.lineFragmentPadding = 15.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [self.positiveTextView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.bottomConstraint.constant = keyboardFrame.size.height;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSString *key = [[PXImageStore sharedImageStore] addImage:image];
    
    if (self.selectedButton == self.positiveButton) {
        self.flipside.positiveImage = image;
        self.flipside.positiveImageID = key;
    } else if (self.selectedButton == self.negativeButton) {
        self.flipside.negativeImage = image;
        self.flipside.negativeImageID = key;
    }
    [self.selectedButton setImage:image forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (IBAction)pressedCancel:(id)sender {
    [self.view endEditing:YES];
    
    self.flipside.positiveImageID = nil;
    self.flipside.negativeImageID = nil;
    [self.delegate didCancelEditing:self];
}

- (IBAction)pressedSave:(id)sender {
    [self.view endEditing:YES];
    
    self.flipside.positiveText = self.positiveTextView.text;
    self.flipside.negativeText = self.negativeTextView.text;
    NSString *errorMessage = self.flipside.errorMessage;
    if (errorMessage) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [self.delegate didFinishEditing:self];
}

- (void)addPhoto:(UIButton *)button {
    [self.view endEditing:YES];
    self.selectedButton = button;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else {
        [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)showImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;
    imagePickerController.sourceType = sourceType;
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.navigationBar.translucent = false;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    UIImagePickerControllerSourceType sourceType;
    if (buttonIndex == 0) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    [self showImagePickerWithSourceType:sourceType];
}

@end
