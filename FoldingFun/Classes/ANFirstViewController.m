//
//  ANFirstViewController.m
//  PanFoldFun
//
//  Created by Andrzej Naglik on 21.07.2013.
//  Copyright (c) 2013 Andrzej Naglik. All rights reserved.
//

#import "ANFirstViewController.h"
#import <QuartzCore/QuartzCore.h>

#define NUMBER_OF_FOLDS 4
#define FOLD_VIEW_HEIGHT 548.0

@interface ANFirstViewController(){
  CGFloat _gestureStartY;
  CGFloat _currentProgress;
  UIView *_foldingView;
  NSMutableArray *_foldsArray;
}

- (UIImage*)imageFoldForRect:(CGRect)rect;
- (void)viewPanned:(UIPanGestureRecognizer*)recognizer;
- (void)updateLayersTransformsWithProgress:(CGFloat)progress animated:(BOOL)animated time:(CFTimeInterval)time;

@end

@implementation ANFirstViewController

- (id)init{
  self = [super init];
  if(self){
  }
  return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView{
  UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self setView:mainView];
  UIImage *ios6Image = [UIImage imageNamed:@"ios6.png"];
  UIImageView *bgImageView = [[UIImageView alloc] initWithImage:ios6Image];
  [[self view] addSubview:bgImageView];
  UIImage *ios7Image = [UIImage imageNamed:@"ios7.png"];
  _foldingView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, ios7Image.size.width, ios7Image.size.height)];
  bgImageView = [[UIImageView alloc] initWithImage:ios7Image];
  [[self view] addSubview:_foldingView];
}

- (void)viewDidLoad{
  [super viewDidLoad];
  CALayer* perspectiveLayer = [_foldingView layer];
  
  //prepare folds in advance (this is of course matter of preference and it depends on case)
  //normally, screenshots will have to be taken but here we have image from resources.
  _foldsArray = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_FOLDS];
  UIImage *ios7Image = [UIImage imageNamed:@"ios7.png"];
  //this should be calculated more presize
  CGFloat foldHeight = ios7Image.size.height/NUMBER_OF_FOLDS;
  CGFloat yPos = 0.0;
  CALayer *joinLayer = perspectiveLayer;
  for(NSUInteger i = 0;i<NUMBER_OF_FOLDS;i++){
    CGRect rect = CGRectMake(0.0,i*foldHeight, ios7Image.size.width, foldHeight);    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self imageFoldForRect:rect]];
    [[imageView layer] setAnchorPoint:CGPointMake(0.5, 0.0)];
    CGPoint imagePosition = [[imageView layer] position];
    imagePosition.y = 0.0;
    [[imageView layer] setPosition:imagePosition];

    CATransformLayer *tLayer = [CATransformLayer layer];
    tLayer.frame = CGRectMake(0.0, 0.0, CGRectGetWidth([imageView frame]), CGRectGetHeight([imageView frame])*(NUMBER_OF_FOLDS - i));
    tLayer.anchorPoint = CGPointMake(0.5, 0.0);
    tLayer.position = CGPointMake(CGRectGetWidth([tLayer frame])/2.0, yPos);
    [tLayer addSublayer:[imageView layer]];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    [gradientLayer setAnchorPoint:CGPointMake(0.5, 0.0)];
    [gradientLayer setFrame:[imageView frame]];
    CGColorRef black = [[[UIColor blackColor] colorWithAlphaComponent:0.8] CGColor];
    CGColorRef otherBlack = [[[UIColor blackColor] colorWithAlphaComponent:0.4] CGColor];
    [gradientLayer setColors:@[(__bridge id)black,(__bridge id)otherBlack]];
    [gradientLayer setLocations:@[@0,@1]];
    [gradientLayer setOpacity:0.0];
    [gradientLayer setOpaque:YES];
    [tLayer addSublayer:gradientLayer];
    
    [joinLayer addSublayer:tLayer];

    yPos = foldHeight;
    joinLayer = tLayer;
    [_foldsArray addObject:tLayer];
  }
  
  CATransform3D transform = CATransform3DIdentity;
  transform.m34 = -1.0/1200.0;
  perspectiveLayer.sublayerTransform = transform;
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanned:)];
  [[self view] addGestureRecognizer:panGestureRecognizer];
}

#pragma mark - 
#pragma mark - Helpers/Internal methods

- (UIImage*)imageFoldForRect:(CGRect)rect{
  //it should be cached if reused
  UIImage *ios7Image = [UIImage imageNamed:@"ios7.png"];
  rect.origin.x *=2;rect.origin.y *=2;
  rect.size.width *=2;rect.size.height *=2;
  CGImageRef image = CGImageCreateWithImageInRect([ios7Image CGImage], rect);
  return [UIImage imageWithCGImage:image scale:2 orientation:UIImageOrientationUp];
}

- (void)viewPanned:(UIPanGestureRecognizer*)recognizer{
  if([recognizer state] == UIGestureRecognizerStateBegan){
    _gestureStartY = [recognizer locationInView:_foldingView].y;
  }else if([recognizer state] == UIGestureRecognizerStateChanged){
    CGFloat diff = (_gestureStartY - [recognizer locationInView:_foldingView].y);
    _gestureStartY = [recognizer locationInView:_foldingView].y;
    CGRect newFoldingViewRect = [_foldingView frame];
    newFoldingViewRect.size.height -= diff;
    if(newFoldingViewRect.size.height < 0.0) newFoldingViewRect.size.height = 0.0;
    if(newFoldingViewRect.size.height > FOLD_VIEW_HEIGHT) newFoldingViewRect.size.height = FOLD_VIEW_HEIGHT;
    [_foldingView setFrame:newFoldingViewRect];
    //TODO: use NSDecimalNumber here
    _currentProgress = 1.00 - CGRectGetHeight(newFoldingViewRect)/(FOLD_VIEW_HEIGHT);
    _currentProgress = ((int)(_currentProgress * 100))/100.0;
    [self updateLayersTransformsWithProgress:_currentProgress animated:NO time:0];
  }else if([recognizer state] == UIGestureRecognizerStateEnded){
    CGPoint a = [recognizer velocityInView:[self view]];
    CGFloat pointsToGo = FOLD_VIEW_HEIGHT - CGRectGetHeight([_foldingView frame]);
    CFTimeInterval time = ABS(pointsToGo/a.y);
    if(time < 0.2) time = 0.2;
    if(time > 1)
      time = 0.5;
    CGFloat progress = (a.y > 0) ? 0.0 : 1.0;
    if(_currentProgress == progress)
      return;
    
    [self updateLayersTransformsWithProgress:progress animated:YES time:time];
    _currentProgress = progress;
    CGRect newFoldingViewRect = [_foldingView frame];
    newFoldingViewRect.size.height = (a.y > 0) ? FOLD_VIEW_HEIGHT : 0.0;
    [_foldingView setFrame:newFoldingViewRect];
  }
}

- (void)updateLayersTransformsWithProgress:(CGFloat)progress animated:(BOOL)animated time:(CFTimeInterval)time{
  if (progress < 0.0 || progress > 1.0)
    return;
  [CATransaction setDisableActions:!animated];
  [CATransaction begin];
  
  [_foldsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CATransformLayer *layer = (CATransformLayer*)obj;
    CGFloat currentAngle = (idx == 0) ? _currentProgress * -M_PI_2 : (idx % 2 == 0 ) ? _currentProgress*(-M_PI) : _currentProgress*(M_PI);
    CGFloat angle = (idx == 0) ? progress * -M_PI_2 : (idx % 2 == 0 ) ? progress*(-M_PI) : progress*(M_PI);
    layer.transform = CATransform3DMakeRotation(angle, 1, 0, 0);
    //TODO: organize it better
    CAGradientLayer *gradientLayer = [layer sublayers][1];
    [gradientLayer setOpacity:progress];
    
    if(animated){
      CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
      [animation setDuration:time];
      [animation setBeginTime:0.0];
      [animation setFillMode:kCAFillModeForwards];
      [animation setValueFunction:[CAValueFunction functionWithName:kCAValueFunctionRotateX]];
      [animation setValues:@[[NSNumber numberWithFloat:currentAngle],[NSNumber numberWithFloat:angle]]];
      [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
      [layer addAnimation:animation forKey:@"transform"];
      
      CABasicAnimation *gradientOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
      [gradientOpacityAnimation setDuration:time];
      [gradientOpacityAnimation setBeginTime:0.0];
      [gradientOpacityAnimation setFromValue:[NSNumber numberWithFloat:_currentProgress]];
      [gradientOpacityAnimation setToValue:[NSNumber numberWithFloat:progress]];
      [gradientLayer addAnimation:gradientOpacityAnimation forKey:@"opacity"];
    }
  }];
  
  [CATransaction commit];
}

@end
