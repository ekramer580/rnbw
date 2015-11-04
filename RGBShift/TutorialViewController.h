//
//  TutorialViewController.h
//  RGBShift
//
//  Created by MarK on 03.11.15.
//  Copyright © 2015 Mason Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *next1Button;
@property (weak, nonatomic) IBOutlet UIButton *next2Button;
@property (weak, nonatomic) IBOutlet UIButton *next3Button;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIImageView *tutorialStart;
@property (weak, nonatomic) IBOutlet UIImageView *tutorial1;
@property (weak, nonatomic) IBOutlet UIImageView *tutorial2;
@property (weak, nonatomic) IBOutlet UIImageView *tutorial3;
@property (weak, nonatomic) IBOutlet UIImageView *tutorial4;

- (IBAction)startAction:(UIButton *)sender;
- (IBAction)next1Action:(UIButton *)sender;
- (IBAction)next2Action:(UIButton *)sender;
- (IBAction)next3Action:(UIButton *)sender;
- (IBAction)doneAction:(UIButton *)sender;

@end
