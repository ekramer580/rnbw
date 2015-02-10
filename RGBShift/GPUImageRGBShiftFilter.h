//
//  GPUImageRGBShiftFilter.h
//  RGBShift
//
//  Created by Mason Kramer on 6/18/13.
//  Copyright (c) 2013 Mason Kramer. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageRGBShiftFilter : GPUImageFilter {
    GLint redOffsetUniform, greenOffsetUniform, blueOffsetUniform;
}

@property(readwrite, nonatomic) CGPoint redOffset;
@property(readwrite, nonatomic) CGPoint blueOffset;
@property(readwrite, nonatomic) CGPoint greenOffset;

-(void)addRedOffset:(CGPoint)offSet;
-(void)addBlueOffset:(CGPoint)offSet;
@end

