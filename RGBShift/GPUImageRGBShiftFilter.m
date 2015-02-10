//
//  GPUImageRGBShiftFilter.m
//  RGBShift
//
//  Created by Mason Kramer on 6/18/13.
//  Copyright (c) 2013 Mason Kramer. All rights reserved.
//

#import "GPUImageRGBShiftFilter.h"

NSString *const kRGBShiftShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 uniform mediump vec2 redOffset;
 uniform mediump vec2 greenOffset;
 uniform mediump vec2 blueOffset;
 
 void main()
 {
     mediump vec4 textureColor      = texture2D(inputImageTexture, textureCoordinate);
     
     mediump vec4 redOffsetColor    = texture2D(inputImageTexture, textureCoordinate + redOffset);
     mediump vec4 greenOffsetColor  = texture2D(inputImageTexture, textureCoordinate + greenOffset);
     mediump vec4 blueOffsetColor   = texture2D(inputImageTexture, textureCoordinate + blueOffset);
     
     mediump vec4 outputColor;
     
     outputColor.r         = redOffsetColor.r;
     outputColor.g         = greenOffsetColor.g;
     outputColor.b         = blueOffsetColor.b;
     outputColor.a         = 1.0;
     
     gl_FragColor = outputColor;
     
 }
);

@implementation GPUImageRGBShiftFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRGBShiftShaderString]))
    {
        return nil;
    }
    
    redOffsetUniform   = [filterProgram uniformIndex:@"redOffset"];
    greenOffsetUniform = [filterProgram uniformIndex:@"greenOffset"];
    blueOffsetUniform  = [filterProgram uniformIndex:@"blueOffset"];
    
    self.redOffset   = CGPointMake(0, 0);
    self.greenOffset = CGPointMake(0, 0);
    self.blueOffset  = CGPointMake(0, 0);
    return self;
}

-(void)addRedOffset:(CGPoint)offSet {
    CGPoint newOffset = CGPointMake(_redOffset.x + offSet.x, _redOffset.y + offSet.y);
    [self setRedOffset: newOffset];
}

-(void)addBlueOffset:(CGPoint)offSet {
    CGPoint newOffset = CGPointMake(_blueOffset.x + offSet.x, _blueOffset.y + offSet.y);
    [self setBlueOffset: newOffset];
}

- (void)setRedOffset:(CGPoint)newValue;
{
    _redOffset = CGPointMake(MAX(-0.5, MIN(newValue.x, 0.5)), MAX(-0.5, MIN(newValue.y, 0.5)));

    [self setPoint:_redOffset forUniform:redOffsetUniform program:filterProgram];
}

- (void)setGreenOffset:(CGPoint)newValue;
{
    _greenOffset = CGPointMake(MAX(-0.5, MIN(newValue.x, 0.5)), MAX(-0.5, MIN(newValue.y, 0.5)));
    
    [self setPoint:_greenOffset forUniform:greenOffsetUniform program:filterProgram];
}

- (void)setBlueOffset:(CGPoint)newValue;
{
    _blueOffset = CGPointMake(MAX(-0.5, MIN(newValue.x, 0.5)), MAX(-0.5, MIN(newValue.y, 0.5)));
    
    [self setPoint:_blueOffset forUniform:blueOffsetUniform program:filterProgram];
}

@end
