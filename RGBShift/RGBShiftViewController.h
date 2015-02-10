//
//  RGBShiftViewController.h
//  RGBShift
//
//  Created by Mason Kramer on 6/14/13.
//  Copyright (c) 2013 Mason Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface RGBShiftViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *stillButton;
@property (weak, nonatomic) IBOutlet GPUImageView *videoPreviewView;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraRollPickerButton;
@property (weak, nonatomic) IBOutlet UIButton *startMoviePlaybackButton;
- (IBAction)startMoviePlaybackPressed:(id)sender;

- (IBAction)presentCameraRollPicker:(id)sender;
- (IBAction)actionButtonPressed:(id)sender;
- (IBAction)toggleCaptureMode:(id)sender;
- (IBAction)panDetected:(UIPanGestureRecognizer *)sender;
- (IBAction)twoFingerPanDetected:(UIPanGestureRecognizer *)sender;
- (IBAction)doubleTapDetected:(UITapGestureRecognizer *)sender;


@end
