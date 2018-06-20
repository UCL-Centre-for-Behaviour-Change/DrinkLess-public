//
//  PXIdentityPhotoViewController.m
//  drinkless
//
//  Created by Edward Warrender on 02/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityPhotoViewController.h"
#import "PXUserIdentity.h"
#import "PXIdentityAspectsViewController.h"
#import "PXImageStore.h"
#import "PXDebug.h"

@interface PXIdentityPhotoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerConstraint;
@property (nonatomic) CGFloat originalHeightConstant;
@property (strong, nonatomic) NSString *noPhotoInstructions;

@end

@implementation PXIdentityPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"I am";
    self.screenName = @"Identity photo view";
    
    self.addButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.originalHeightConstant = self.buttonContainerConstraint.constant;
    self.noPhotoInstructions = self.instructionsLabel.text;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

#if !FORCE_DEFAULT_AVATAR_IMAGE
    if (self.userIdentity.photo) {
        [self.addButton setImage:self.userIdentity.photo forState:UIControlStateNormal];
        self.buttonContainerConstraint.constant = self.originalHeightConstant;
        self.instructionsLabel.text = @"Tap on the image above to change the photo of yourself";
    } else {
        // allow skipping nowfab
//        self.buttonContainerConstraint.constant = 0.0;
        self.instructionsLabel.text = self.noPhotoInstructions;
    }
#else
      self.instructionsLabel.text = self.noPhotoInstructions;
#endif
    
    UIView *containerView = self.buttonContainerConstraint.firstItem;
    [containerView setNeedsLayout];
    [containerView layoutIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.userIdentity save];
}

#pragma mark - Action

- (IBAction)pressedAdd:(id)sender {
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
    [self presentViewController:imagePickerController animated:YES completion:nil];
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


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.userIdentity.photo = image;
    self.userIdentity.photoID = [[PXImageStore sharedImageStore] addImage:image];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (image) {
            [self performSegueWithIdentifier:@"showAspects" sender:self];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAspects"]) {
        PXIdentityAspectsViewController *aspectsVC = segue.destinationViewController;
        aspectsVC.userIdentity = self.userIdentity;
    }
}

@end
