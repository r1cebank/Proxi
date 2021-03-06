//
//  RKNotificationHub.m
//  RKNotificationHub
//
//  Created by Richard Kim on 9/30/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//

#import "RKNotificationHub.h"
#import <QuartzCore/QuartzCore.h>

//%%% default diameter
CGFloat kDefaultDiameter = 30;
CGFloat kCountMagnitudeAdaptationRatio = 0.3;
//%%% pop values
CGFloat kPopStartRatio = .85;
CGFloat kPopOutRatio = 1.05;
CGFloat kPopInRatio = .95;

//%%% blink values
CGFloat kBlinkDuration = 0.1;
CGFloat kBlinkAlpha = 0.1;

//%%% bump values
CGFloat kFirstBumpDistance = 8.0;
CGFloat kBumpTimeSeconds = 0.13;
CGFloat SECOND_BUMP_DIST = 4.0;
CGFloat kBumpTimeSeconds2 = 0.1;

@interface RKView : UIView
@property (nonatomic) BOOL isUserChangingBackgroundColor;
@end

@implementation RKView

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (self.isUserChangingBackgroundColor) {
        super.backgroundColor = backgroundColor;
        self.isUserChangingBackgroundColor = NO;
    }
}

@end


@implementation RKNotificationHub {
    int count;
    int curOrderMagnitude;
    UILabel *countLabel;
    RKView *redCircle;
    CGPoint initialCenter;
    CGRect baseFrame;
    CGRect initialFrame;
    BOOL isIndeterminateMode;
}

@synthesize hubView;

#pragma mark - SETUP

- (id)initWithView:(UIView *)view
{
    self = [super init];
    if (!self) return nil;
    
    [self setView:view andCount:0];
    
    return self;
}

//%%% give this a view and an initial count (0 hides the notification circle)
// and it will make a hub for you
- (void)setView:(UIView *)view andCount:(int)startCount
{
    curOrderMagnitude = 0;

    CGRect frame = view.frame;
    
    isIndeterminateMode = NO;
    
    redCircle = [[RKView alloc]init];
    redCircle.userInteractionEnabled = NO;
    redCircle.isUserChangingBackgroundColor = YES;
    redCircle.backgroundColor = [UIColor redColor];
    
    countLabel = [[UILabel alloc]initWithFrame:redCircle.frame];
    countLabel.userInteractionEnabled = NO;
    [self setCount:startCount];
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    countLabel.textColor = [UIColor whiteColor];
    
    [self setCircleAtFrame:CGRectMake(frame.size.width- (kDefaultDiameter*2/3), -kDefaultDiameter/3, kDefaultDiameter, kDefaultDiameter)];
    
    [view addSubview:redCircle];
    [view addSubview:countLabel];
    [view bringSubviewToFront:redCircle];
    [view bringSubviewToFront:countLabel];
    hubView = view;
    [self checkZero];
}

//%%% set the frame of the notification circle relative to the button
- (void)setCircleAtFrame:(CGRect)frame
{
    [redCircle setFrame:frame];
    initialCenter = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    baseFrame = frame;
    initialFrame = frame;
    countLabel.frame = redCircle.frame;
    redCircle.layer.cornerRadius = frame.size.height/2;
    [countLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:frame.size.width/2]];
    [self expandToFitLargerDigits];
}

//%%% moves the circle by x amount on the x axis and y amount on the y axis
- (void)moveCircleByX:(CGFloat)x Y:(CGFloat)y
{
    CGRect frame = redCircle.frame;
    frame.origin.x += x;
    frame.origin.y += y;
    [self setCircleAtFrame:frame];
}

//%%% changes the size of the circle. setting a scale of 1 has no effect
- (void)scaleCircleSizeBy:(CGFloat)scale
{
    CGRect fr = initialFrame;
    CGFloat width = fr.size.width * scale;
    CGFloat height = fr.size.height * scale;
    CGFloat wdiff = (fr.size.width - width) / 2;
    CGFloat hdiff = (fr.size.height - height) / 2;

    CGRect frame = CGRectMake(fr.origin.x + wdiff, fr.origin.y + hdiff, width, height);
    [self setCircleAtFrame:frame];
}

//%%% change the color of the notification circle
- (void)setCircleColor:(UIColor*)circleColor labelColor:(UIColor*)labelColor
{
    redCircle.isUserChangingBackgroundColor = YES;
    redCircle.backgroundColor = circleColor;
    [countLabel setTextColor:labelColor];
}

- (void)hideCount
{
    countLabel.hidden = YES;
    isIndeterminateMode = YES;
}

- (void)showCount
{
    isIndeterminateMode = NO;
    [self checkZero];
}

#pragma mark - ATTRIBUTES

//%%% increases count by 1
- (void)increment
{
    [self setCount:count+1];
}

//%%% increases count by amount
- (void)incrementBy:(int)amount
{
    [self setCount:count+amount];
}

//%%% decreases count
- (void)decrement
{
    if (count == 0) {
        return;
    }
    [self setCount:count-1];
}

//%%% decreases count by amount
- (void)decrementBy:(int)amount
{
    [self setCount:count-amount];
}

//%%% set the count yourself
- (void)setCount:(int)newCount
{
    count = newCount;
    countLabel.text = [NSString stringWithFormat:@"%i",count];
    [self checkZero];
    [self expandToFitLargerDigits];
}

- (int)count
{
    return count;
}

#pragma mark - ANIMATION

//%%% animation that resembles facebook's pop
- (void)pop
{
    const float height = baseFrame.size.height;
    const float width = baseFrame.size.width;
    const float pop_start_h = height * kPopStartRatio;
    const float pop_start_w = width * kPopStartRatio;
    const float time_start = 0.05;
    const float pop_out_h = height * kPopOutRatio;
    const float pop_out_w = width * kPopOutRatio;
    const float time_out = .2;
    const float pop_in_h = height * kPopInRatio;
    const float pop_in_w = width * kPopInRatio;
    const float time_in = .05;
    const float pop_end_h = height;
    const float pop_end_w = width;
    const float time_end = 0.05;
    
    CABasicAnimation *startSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    startSize.duration = time_start;
    startSize.beginTime = 0;
    startSize.fromValue = @(pop_end_h / 2);
    startSize.toValue = @(pop_start_h / 2);
    startSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *outSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    outSize.duration = time_out;
    outSize.beginTime = time_start;
    outSize.fromValue = startSize.toValue;
    outSize.toValue = @(pop_out_h / 2);
    outSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *inSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    inSize.duration = time_in;
    inSize.beginTime = time_start+time_out;
    inSize.fromValue = outSize.toValue;
    inSize.toValue = @(pop_in_h / 2);
    inSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *endSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    endSize.duration = time_end;
    endSize.beginTime = time_in+time_out+time_start;
    endSize.fromValue = inSize.toValue;
    endSize.toValue = @(pop_end_h / 2);
    endSize.removedOnCompletion = FALSE;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    [group setDuration: time_start+time_out+time_in+time_end];
    [group setAnimations:@[startSize, outSize, inSize, endSize]];
    
    [redCircle.layer addAnimation:group forKey:nil];
    
    [UIView animateWithDuration:time_start animations:^{
        CGRect frame = redCircle.frame;
        CGPoint center = redCircle.center;
        frame.size.height = pop_start_h;
        frame.size.width = pop_start_w;
        redCircle.frame = frame;
        redCircle.center = center;
    }completion:^(BOOL complete){
        [UIView animateWithDuration:time_out animations:^{
            CGRect frame = redCircle.frame;
            CGPoint center = redCircle.center;
            frame.size.height = pop_out_h;
            frame.size.width = pop_out_w;
            redCircle.frame = frame;
            redCircle.center = center;
        }completion:^(BOOL complete){
            [UIView animateWithDuration:time_in animations:^{
                CGRect frame = redCircle.frame;
                CGPoint center = redCircle.center;
                frame.size.height = pop_in_h;
                frame.size.width = pop_in_w;
                redCircle.frame = frame;
                redCircle.center = center;
            }completion:^(BOOL complete){
                [UIView animateWithDuration:time_end animations:^{
                    CGRect frame = redCircle.frame;
                    CGPoint center = redCircle.center;
                    frame.size.height = pop_end_h;
                    frame.size.width = pop_end_w;
                    redCircle.frame = frame;
                    redCircle.center = center;
                }];
            }];
        }];
    }];
}

//%%% animation that flashes on an off
- (void)blink
{
    [self setAlpha:kBlinkAlpha];
    
    [UIView animateWithDuration:kBlinkDuration animations:^{
        [self setAlpha:1];
    }completion:^(BOOL complete){
        [UIView animateWithDuration:kBlinkDuration animations:^{
            [self setAlpha:kBlinkAlpha];
        }completion:^(BOOL complete){
            [UIView animateWithDuration:kBlinkDuration animations:^{
                [self setAlpha:1];
            }];
        }];
    }];
}

//%%% animation that jumps similar to OSX dock icons
- (void)bump
{
    if (!CGPointEqualToPoint(initialCenter,redCircle.center)) {
        //%%% canel previous animation
    }
    
    [self bumpCenterY:0];
    [UIView animateWithDuration:kBumpTimeSeconds animations:^{
        [self bumpCenterY:kFirstBumpDistance];
    }completion:^(BOOL complete){
        [UIView animateWithDuration:kBumpTimeSeconds animations:^{
            [self bumpCenterY:0];
        }completion:^(BOOL complete){
            [UIView animateWithDuration:kBumpTimeSeconds2 animations:^{
                [self bumpCenterY:SECOND_BUMP_DIST];
            }completion:^(BOOL complete){
                [UIView animateWithDuration:kBumpTimeSeconds2 animations:^{
                    [self bumpCenterY:0];
                }];
            }];
        }];
    }];
}

#pragma mark - HELPERS

//%%% changes the Y origin of the notification circle
- (void)bumpCenterY:(float)yVal
{
    CGPoint center = redCircle.center;
    center.y = initialCenter.y-yVal;
    redCircle.center = center;
    countLabel.center = center;
}

- (void)setAlpha:(float)alpha
{
    redCircle.alpha = alpha;
    countLabel.alpha = alpha;
}

//%%% used for pop animation to change the diameter
- (CGRect)nextRectWithDiameter:(float)diameter
{
    const float initialD = baseFrame.size.width;
    float buffer = (initialD - diameter)/2;
    
    CGRect frame = redCircle.frame;
    frame.size.height = diameter;
    frame.size.width = diameter;
    frame.origin.x = redCircle.frame.origin.x + buffer;
    frame.origin.y = redCircle.frame.origin.y + buffer;
    return frame;
}

//%%% hides the notification if the value is 0
- (void)checkZero
{
    if (count <= 0) {
        redCircle.hidden = YES;
        countLabel.hidden = YES;
    } else {
        redCircle.hidden = NO;
        if (!isIndeterminateMode) {
            countLabel.hidden = NO;
        }
    }
}

- (void)expandToFitLargerDigits {
    int orderOfMagnitude = log10((double)count);
    orderOfMagnitude = (orderOfMagnitude >= 2) ? orderOfMagnitude : 1;
    CGRect frame = initialFrame;
    frame.size.width = initialFrame.size.width * (1 + kCountMagnitudeAdaptationRatio * (orderOfMagnitude - 1));
    frame.origin.x = initialFrame.origin.x - (frame.size.width - initialFrame.size.width) / 2;

    [redCircle setFrame:frame];
    initialCenter = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    baseFrame = frame;
    countLabel.frame = redCircle.frame;
    curOrderMagnitude = orderOfMagnitude;
}

@end
