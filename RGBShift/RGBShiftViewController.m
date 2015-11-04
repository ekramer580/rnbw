//
//  RGBShiftViewController.m
//  RGBShift
//
//  Created by Mason Kramer on 6/14/13.
//  Copyright (c) 2013 Mason Kramer. All rights reserved.
//
//
#import "RGBShiftViewController.h"
#import "GPUImage.h"
#import "GPUImageRGBShiftFilter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "TutorialViewController.h"

#define kTutorialCompleted @"tutorialCompleted"

typedef enum {
    stillCaptureJPEG = 1,
    videoCapture     = 2,
    movieReplay      = 3,
    stillEdit        = 4
}  cameraMode;
@interface RGBShiftViewController ()

@property (nonatomic) UIImageView *overlayView;

@property (nonatomic) GPUImageStillCamera       *stillCamera;
@property (nonatomic) GPUImageVideoCamera       *videoCamera;
@property (nonatomic) GPUImageMovieWriter       *movieWriter;
@property (nonatomic) GPUImageMovie             *movie;
@property (nonatomic) GPUImagePicture           *stillPicture;

@property (nonatomic) NSTimer *blinkTimer;
@property (nonatomic) NSURL                     *movieReplayURL;
@property (nonatomic) UIImagePickerController   *imagePicker;
@property (nonatomic) GPUImageRGBShiftFilter    *filter1;
@property (nonatomic) cameraMode mode;
@property (nonatomic) bool recording;
@property (nonatomic) NSURL *movieURL;
@end


@implementation RGBShiftViewController

AVCaptureVideoOrientation AVOrientationFromDeviceOrientation(UIDeviceOrientation deviceOrientation) {
    if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        return AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        return AVCaptureVideoOrientationLandscapeLeft;
    else if( deviceOrientation == UIDeviceOrientationPortrait)
        return AVCaptureVideoOrientationPortrait;
    else if( deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
        return AVCaptureVideoOrientationPortraitUpsideDown;
    else
        return AVCaptureVideoOrientationPortrait; // Deal with, e.g., "face up" and "face down" orientations.
}
UIInterfaceOrientation OutputOrientationFromDeviceOrientation(UIDeviceOrientation deviceOrientation) {
    
    switch (deviceOrientation) {
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            return UIInterfaceOrientationPortrait;
        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeLeft;
        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeLeft;
        case UIDeviceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationPortraitUpsideDown;
        default: // In case further values are added to UIDeviceOrientation
            return UIInterfaceOrientationPortrait;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait; // + UIInterfaceOrientationMaskPortraitUpsideDown;
}

UIInterfaceOrientation currentInterfaceOrientation() {
    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return currentOrientation;
}

UIDeviceOrientation currentDeviceOrientation() {
    return [[UIDevice currentDevice] orientation];
}


- (void)deviceOrientationChanged:(NSNotification *)notification
{
    [self updateAVOrientation];
}

- (void)updateAVOrientation {
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    self.stillCamera.outputImageOrientation = statusBarOrientation;
    self.videoCamera.outputImageOrientation = statusBarOrientation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view layoutIfNeeded];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];

    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mq = [NSOperationQueue mainQueue];
    [noteCenter
    addObserverForName:@"didSwitchFromMovieReplayMode"
    object:nil
    queue:mq
    usingBlock:^(NSNotification *notification){
        if (self.recording) {
            [self finishWriting];
        }
        [self.videoCamera removeAllTargets];
        [self.videoCamera stopCameraCapture];
        self.startMoviePlaybackButton.hidden = true;
    }];
    [noteCenter
     addObserverForName:@"didSwitchFromVideoCaptureMode"
     object:nil
     queue:mq
     usingBlock:^(NSNotification *notification){
         if (self.recording) {
             [self finishWriting];
         }
         [self.videoCamera removeAllTargets];
         [self.videoCamera stopCameraCapture];
     }];
    [noteCenter
     addObserverForName:@"didSwitchFromStillCaptureJPEGMode"
     object:nil
     queue:mq
     usingBlock:^(NSNotification *notification){
         [self.stillCamera removeAllTargets];
         [self.stillCamera stopCameraCapture];
     }];
    [noteCenter
     addObserverForName:@"didSwitchFromImageEditMode"
     object:nil
     queue:mq
     usingBlock:^(NSNotification *notification){
         
     }];
    
    [noteCenter
    addObserverForName:@"didSwitchMode"
    object:nil
    queue:mq
    usingBlock:^(NSNotification *notification){

        if (self.mode == stillCaptureJPEG) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"didSwitchFromStillCaptureJPEGMode"object:self];
        }
         else if (self.mode == videoCapture) {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"didSwitchFromVideoCaptureMode" object:nil];
         }
         else if (self.mode == movieReplay) {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"didSwitchFromMovieReplayMode" object: nil];
         }
         else if (self.mode == stillEdit) {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"didSwitchFromStillEditMode" object:nil];
         }
     }];

    self.startMoviePlaybackButton.hidden = true;
    [self switchToStillCameraMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL tutorialCompleted = [[defaults objectForKey:kTutorialCompleted] boolValue];
    
    // Tutorial
    if (tutorialCompleted == NO) {
        NSString *launchImageString;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 480) {
            launchImageString = @"LaunchImage-700@2x.png"; // iPhone 4/4s, 3.5 inch screen
        } else {
            launchImageString = @"LaunchImage-700-568h@2x.png";
        }
        UIImage *launchImage = [UIImage imageNamed:launchImageString];
        self.overlayView = [[UIImageView alloc] initWithImage:launchImage];
        self.overlayView.frame = self.view.frame;
        [self.view addSubview:self.overlayView];
        [self.view bringSubviewToFront:self.overlayView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL tutorialCompleted = [[defaults objectForKey:kTutorialCompleted] boolValue];
    
    // Tutorial
    if (tutorialCompleted == NO) {
        [defaults setObject:@YES forKey:kTutorialCompleted];
        [defaults synchronize];
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
        TutorialViewController *tutorialViewController = [mainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([TutorialViewController class])];
        [self presentViewController:tutorialViewController animated:YES completion:^{
            [self.overlayView removeFromSuperview];
            self.overlayView = nil;
        }];
    }
}

- (IBAction)startMoviePlaybackPressed:(id)sender {
    if (self.movie) {
        self.recording = true;
        self.startMoviePlaybackButton.hidden = true;
        [self.movieWriter startRecording];
        [self.movie startProcessing];
    }
    else {
        NSLog(@"Warning: movie playback button pressed, but no movie was queued up. This shouldn't be possible.");
    }
}

- (IBAction)presentCameraRollPicker:(id)sender {
    UIImagePickerController *picker = [self createImagePicker];
    picker.allowsEditing = YES;

    [self presentViewController:picker animated:YES completion:^{}];
}

- (UIImagePickerController *) createImagePicker {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, kUTTypeImage, nil];

    imagePicker.allowsEditing = NO;
//    imagePicker.showsCameraControls = NO;
//    imagePicker.cameraViewTransform = CGAffineTransformIdentity;
    
//    // not all devices have two cameras or a flash so just check here
//    if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceRear] ) {
//        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
//        if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront] ) {
//            cameraSelectionButton.alpha = 1.0;
//            showCameraSelection = YES;
//        }
//    } else {
//        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
//    }
//    
//    if ( [UIImagePickerController isFlashAvailableForCameraDevice:imagePicker.cameraDevice] ) {
//        imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
//        flashModeButton.alpha = 1.0;
//        showFlashMode = YES;
//    }
    
//    imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;
    
    imagePicker.delegate = self;
    imagePicker.wantsFullScreenLayout = YES;
    
    return imagePicker;
}

- (IBAction)actionButtonPressed:(id)sender {
    if (self.mode == stillCaptureJPEG) {
        [self takeStill:self];
    }
    else if (self.mode == videoCapture) {
        [self toggleVideoRecording];
    }
    else if (self.mode == stillEdit) {
        [self saveFilteredPicture];
    }
}

-(void)setRecording:(bool)recording {
    _recording = recording;
    if (recording) {
        [self startRecordingIndicator];
    }
    else {
        [self stopRecordingIndicator];
    }
}

-(void)startRecordingIndicator {
    UIImage * cameraImage = [UIImage imageNamed:@"video_indicator_light.png"];
    [self.modeButton setImage:cameraImage forState:UIControlStateNormal];
    
    if (self.blinkTimer == nil) {
        self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                      target:self
                                                      selector:@selector(updateBlinker)
                                                      userInfo:nil repeats:YES];
    }
}

-(void)stopRecordingIndicator {
    UIImage * cameraImage = [UIImage imageNamed:@"048 Videocamera@2x.png"];
    [self.modeButton setImage:cameraImage forState:UIControlStateNormal];
    
    [self.blinkTimer invalidate];
    self.blinkTimer = nil;
}

-(void)updateBlinker {
    if ([self.modeButton isHidden]) {
        self.modeButton.hidden = false;
    }
    else {
        self.modeButton.hidden = true;
    }
}
-(void)toggleVideoRecording {
    if (!self.recording) {
        self.recording = true;
        [self.movieWriter startRecording];
    }
    else {
        [self finishWriting];
    }
}

-(void)setupMovieWriterForVideoCapture {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartRecording" object:nil];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    AVCaptureVideoDataOutput *output = [[[self.videoCamera captureSession] outputs] lastObject];
    NSDictionary* outputSettings = [output videoSettings];
    
    long width  = [[outputSettings objectForKey:@"Width"]  longValue];
    long height = [[outputSettings objectForKey:@"Height"] longValue];
    
    if (UIInterfaceOrientationIsPortrait(self.videoCamera.outputImageOrientation)) {
        long buf = width;
        width = height;
        height = buf;
    }
    
    GPUImageMovieWriter * mw = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(width, height)];
    self.movieURL = movieURL;
    self.movieWriter = mw;
    [self.filter1 addTarget:mw];
    mw.shouldPassthroughAudio = YES;

}

-(void)setupMovieWriterForMovieFiltering {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartRecording" object:nil];
    self.recording = true;
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    //[movie setShouldAutoplay:YES];
    AVAsset *movieAsset = [self.movie asset];
    NSArray *movieTracks =  [movieAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *movieTrack = [movieTracks lastObject];
    
    CGSize size = [movieTrack naturalSize];
    
    GPUImageMovieWriter * mw = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size];
    self.movieURL = movieURL;
    self.movieWriter = mw;
    [self.filter1 addTarget:mw];
    mw.shouldPassthroughAudio = YES;
    
    [self.movie enableSynchronizedEncodingUsingMovieWriter:mw];

}

-(void)finishWriting {
    self.recording = false;
    [self.movieWriter finishRecording];
    [self.filter1 removeTarget:self.movieWriter];
    UISaveVideoAtPathToSavedPhotosAlbum(self.movieURL.path, nil, NULL, NULL);
    self.movieWriter = nil;
    
    if (self.mode == movieReplay) {
        [self switchToMovieReplayMode:self.movieReplayURL];
    }
}

- (IBAction)toggleCaptureMode:(id)sender {
    if (self.mode == videoCapture) {
        [self switchToStillCameraMode];
    }
    else {
        [self switchToVideoMode];
    }
}

-(void) setMode:(cameraMode)newMode {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didSwitchMode" object:nil];
    _mode = newMode;
}

-(void)switchToStillCameraMode {
    self.mode = stillCaptureJPEG;
    
    UIImage * cameraImage = [UIImage imageNamed:@"030 Camera@2x.png"];
    [self.modeButton setImage:cameraImage forState:UIControlStateNormal];
    
    if (self.stillCamera == nil) {
        self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];

        if (self.filter1 == nil) {
            GPUImageRGBShiftFilter *rf = [[GPUImageRGBShiftFilter alloc] init];
            self.filter1 = rf;
            [self.filter1 addTarget:self.videoPreviewView];
        }
        
    }
    self.stillPicture = NULL;
    [self.stillCamera addTarget:self.filter1];
    [self.stillCamera startCameraCapture];
    [self updateAVOrientation];
}

-(void)switchToVideoMode {
    self.mode = videoCapture;

    UIImage * videoImage = [UIImage imageNamed:@"048 Videocamera@2x.png"];
    [self.modeButton setImage:videoImage forState:UIControlStateNormal];
    
    if (self.videoCamera == nil) {
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
        
        if (self.filter1 == nil) {
            GPUImageRGBShiftFilter *rf = [[GPUImageRGBShiftFilter alloc] init];
            self.filter1 = rf;
            [self.filter1 addTarget:self.videoPreviewView];
        }
    }
    [self updateAVOrientation];
    [self.videoCamera addTarget:self.filter1];
    [self.videoCamera startCameraCapture];
    [self setupMovieWriterForVideoCapture];
}

-(void)switchToMovieReplayMode:(NSURL*) movieURL {
    self.mode = movieReplay;
    self.movieReplayURL = movieURL;
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
    GPUImageMovie *movie = [[GPUImageMovie alloc] initWithAsset:(AVAsset *)asset];
    [movie addTarget:self.filter1];
    self.movie = movie;
    self.startMoviePlaybackButton.hidden = false;
    
    [self setupMovieWriterForMovieFiltering];
    [self updateAVOrientation];
//
//    [library assetForURL:movieURL
//             resultBlock:^(ALAsset *asset) {
//                 if (asset) {
//                     
//                     
//
//                 }
//             }
//            failureBlock:^(NSError *error) {
//                NSLog(@"Couldn't get asset for %@", movieURL);
//            
//            }
//    ];
}

-(void)switchToStillEditMode:(UIImage *) editImage {
    self.mode = stillEdit;
    
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:editImage];
    [picture addTarget:self.filter1];
    [picture processImage];
    self.stillPicture = picture;
    self.stillCamera.outputImageOrientation = editImage.imageOrientation;
}

- (IBAction)takeStill:(id)sender {
    [self.stillButton setEnabled:NO];
    [self.stillCamera capturePhotoAsJPEGProcessedUpToFilter:self.filter1 withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        NSLog(@"%@", self.stillCamera.currentCaptureMetadata);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:processedJPEG];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.stillButton setEnabled:YES];
            });
        });
    }];
}

-(void)saveFilteredPicture {
    [self.filter1 useNextFrameForImageCapture];
    [self.stillPicture processImage];
    
    UIImage *filteredPhoto = [self.filter1 imageFromCurrentFramebuffer];
    UIImageWriteToSavedPhotosAlbum(filteredPhoto, nil, nil, nil);
}

CGPoint rotateOffset(UIDeviceOrientation orientation, CGPoint raw) {
    CGPoint new;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationPortrait) {
        // 90ccw
        new.x =  -1 * raw.y;
        new.y = raw.x;
        return new;
    }
    else if (orientation == UIDeviceOrientationLandscapeRight || orientation == UIDeviceOrientationLandscapeLeft) {
        new.x = -1 * raw.y;
        new.y = raw.x;
        return new;
    }
    else {
        return raw;
    }
}

- (IBAction)panDetected:(UIPanGestureRecognizer *)panRecognizer {

    CGPoint translation = rotateOffset(currentDeviceOrientation(), [panRecognizer translationInView:self.videoPreviewView]);
    
    CGRect bounds = [self.videoPreviewView bounds];
    CGPoint offset = CGPointMake(-1 * translation.y / bounds.size.height, translation.x / bounds.size.width);

    [self.filter1 addRedOffset: offset];
    [self.stillPicture processImage];

    [panRecognizer setTranslation:CGPointZero inView:self.videoPreviewView];
}

- (IBAction)twoFingerPanDetected:(UIPanGestureRecognizer *)panRecognizer {
    CGPoint translation = rotateOffset(currentDeviceOrientation(), [panRecognizer translationInView:self.videoPreviewView]);
    
    CGRect bounds = [self.videoPreviewView bounds];
    
    CGPoint offset = CGPointMake(-1 * translation.y / bounds.size.height, translation.x / bounds.size.width);
    
    [self.stillPicture processImage];
    [self.filter1 addBlueOffset: offset];
    
    [panRecognizer setTranslation:CGPointZero inView:self.videoPreviewView];

}

- (IBAction)doubleTapDetected:(UITapGestureRecognizer *)sender {
    [self.filter1 setRedOffset:CGPointZero];
    [self.filter1 setGreenOffset:CGPointZero];
    [self.filter1 setBlueOffset:CGPointZero];
    [self.stillPicture processImage];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info valueForKey:UIImagePickerControllerMediaType]; // The value for this key is an NSString object containing a type code such as kUTTypeImage or kUTTypeMovie.

    NSURL *videoURL = [info valueForKey:UIImagePickerControllerReferenceURL]; // The Assets Library URL for the original version of the picked item.
    UIImage *stillImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    for (id key in info) {
        NSLog(@"key: %@, value: %@ \n", key, [info objectForKey:key]);
    }
    
    if ([mediaType isEqualToString:@"public.movie"]) {
        [self switchToMovieReplayMode: videoURL];
    }
    else if ([mediaType isEqualToString:@"public.image"]) {
        [self switchToStillEditMode: stillImage];
    }
    
    [picker dismissViewControllerAnimated:true completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

    [picker dismissViewControllerAnimated:true completion:^{}];
}


@end

