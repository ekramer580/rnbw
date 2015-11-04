//
//  TutorialViewController.m
//  RGBShift
//
//  Created by MarK on 03.11.15.
//  Copyright © 2015 Mason Kramer. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()

@end

@implementation TutorialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.startButton.layer.borderWidth = 1;
    self.startButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.startButton.layer.cornerRadius = 10;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)startAction:(UIButton *)sender {
    [self.scrollView scrollRectToVisible:self.tutorial1.frame animated:true];
}

- (IBAction)next1Action:(UIButton *)sender {
    [self.scrollView scrollRectToVisible:self.tutorial2.frame animated:true];
}

- (IBAction)next2Action:(UIButton *)sender {
    [self.scrollView scrollRectToVisible:self.tutorial3.frame animated:true];
}

- (IBAction)next3Action:(UIButton *)sender {
    [self.scrollView scrollRectToVisible:self.tutorial4.frame animated:true];
}

- (IBAction)doneAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
