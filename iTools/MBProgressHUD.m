//
//  MBProgressHUD.m
//  iTools
//
//  Created by Jolin He on 12-11-16.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD()
@property(nonatomic,strong,readonly)NSProgressIndicator* indicator;
@property(nonatomic,strong,readonly)NSTextView* textView;
@end

@implementation MBProgressHUD{
    NSView* _contentView;
    
    NSArray* _contentViewConstraints;
    NSArray* _indicatorConstraints;
    NSArray* _textFieldConstraints;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.translatesAutoresizingMaskIntoConstraints=NO;
        self.alphaValue=0;
        _removeFromSuperViewOnHide=YES;
        
        _contentView=[[NSView alloc] init];
        CALayer *viewLayer = [CALayer layer];
        [viewLayer setBackgroundColor:[[NSColor grayColor] colorWithAlphaComponent:0.8].CGColor];
        viewLayer.cornerRadius=7;
        viewLayer.opaque=NO;
        [_contentView setWantsLayer:YES];
        [_contentView setLayer:viewLayer];
        _contentView.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:_contentView];
            
        _indicator=[[NSProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        _indicator.displayedWhenStopped=NO;
        [_indicator setStyle:NSProgressIndicatorSpinningStyle];
        _indicator.translatesAutoresizingMaskIntoConstraints=NO;
        [_contentView addSubview:_indicator];
        
        _textView=[[NSTextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints=NO;
        _textView.frame=CGRectMake(0, 0, 200, 0);
        _textView.alignment=NSCenterTextAlignment;
        [_textView setVerticallyResizable:YES];
        [_textView setHorizontallyResizable:NO];
        _textView.textColor=[NSColor whiteColor];
        _textView.font=[NSFont boldSystemFontOfSize:17];
        [_textView setEditable:NO];
        [_textView setSelectable:YES];
        [_textView setBackgroundColor:[NSColor clearColor]];
        [_contentView addSubview:_textView];
        
        self.text=@"数据加载中...";
    }
    
    return self;
}

- (id)initWithView:(NSView *)view {
	NSAssert(view, @"View must not be nil.");
	id me = [self initWithFrame:view.bounds];
    [view addSubview:me];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(me);
    NSArray* constraints1=[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[me]-0-|" options:0 metrics:nil views:viewsDictionary];
    NSArray* constraints2=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[me]-0-|" options:0 metrics:nil views:viewsDictionary];
    [view addConstraints:constraints1];
    [view addConstraints:constraints2];
    
	return me;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.6] set];
    CGContextFillRect(context, self.bounds);
}

-(void)setText:(NSString *)text{
    if(!text)return;
    
    [_textView setString:text];
    [self setNeedsUpdateConstraints:YES];
}

-(void)updateConstraints{
    [super updateConstraints];
    if (_contentViewConstraints) {
        [self removeConstraints:_contentViewConstraints];
    }
    if (_indicatorConstraints) {
        [_contentView removeConstraints:_indicatorConstraints];
    }
    if (_textFieldConstraints) {
        [_contentView removeConstraints:_textFieldConstraints];
    }
    //_textField
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_textView);
    NSMutableArray* constraints=[NSMutableArray array];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_textView(==%f)]",_textView.bounds.size.width] options:0 metrics:nil views:viewsDictionary]
     ];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_textView(==%f)]",_textView.bounds.size.height] options:0 metrics:nil views:viewsDictionary]
     ];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]
     ];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeTop multiplier:1 constant:40]
     ];
    [_contentView addConstraints:constraints];
    _textFieldConstraints=constraints;
    //_indicator
    viewsDictionary = NSDictionaryOfVariableBindings(_indicator);
    constraints=[NSMutableArray array];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_indicator(==24)]" options:0 metrics:nil views:viewsDictionary]
     ];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_indicator(==24)]" options:0 metrics:nil views:viewsDictionary]
     ];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_indicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]
     ];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_indicator attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeTop multiplier:1 constant:10]
     ];
    [_contentView addConstraints:constraints];
    _indicatorConstraints=constraints;
    //_contentView
    viewsDictionary = NSDictionaryOfVariableBindings(_contentView);
    constraints=[NSMutableArray array];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]
     ];
    [constraints addObject:
     [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]
     ];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_contentView(>=%f)]",_textView.bounds.size.width+10] options:0 metrics:nil views:viewsDictionary]
     ];
    [constraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_contentView(>=%f)]",_textView.bounds.size.height+50] options:0 metrics:nil views:viewsDictionary]
     ];
    [self addConstraints:constraints];
    _contentViewConstraints=constraints;
}

- (void)mouseDown:(NSEvent *)theEvent{
    NSLog(@"mouseDown");
}

- (void)show:(BOOL)animated{
    [_indicator startAnimation:self];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:(animated?0.3:0)];
    [self.animator setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

- (void)hide:(BOOL)animated{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:(animated?0.3:0)];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [_indicator stopAnimation:self];
        if (self.removeFromSuperViewOnHide) {
            [self removeFromSuperview];
        }
    }];
    [self.animator setAlphaValue:0];
    [NSAnimationContext endGrouping];
}
- (void)hideDelayed:(NSNumber *)animated {
	[self hide:[animated boolValue]];
}
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay{
	[self performSelector:@selector(hideDelayed:) withObject:@(animated) afterDelay:delay];
}

+ (MBProgressHUD *)showHUDAddedTo:(NSView *)view animated:(BOOL)animated{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
	[hud show:animated];
	return hud;
}

+ (BOOL)hideHUDForView:(NSView *)view animated:(BOOL)animated{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
	if (hud != nil) {
		hud.removeFromSuperViewOnHide = YES;
		[hud hide:animated];
		return YES;
	}
	return NO;
}

+ (NSUInteger)hideAllHUDsForView:(NSView *)view animated:(BOOL)animated {
	NSArray *huds = [self allHUDsForView:view];
	for (MBProgressHUD *hud in huds) {
		hud.removeFromSuperViewOnHide = YES;
		[hud hide:animated];
	}
	return [huds count];
}

+ (MBProgressHUD *)HUDForView:(NSView *)view{
    MBProgressHUD *hud = nil;
	NSArray *subviews = view.subviews;
	Class hudClass = [MBProgressHUD class];
	for (NSView *view in subviews) {
		if ([view isKindOfClass:hudClass]) {
			hud = (MBProgressHUD *)view;
		}
	}
	return hud;
}

+ (NSArray *)allHUDsForView:(NSView *)view {
	NSMutableArray *huds = [NSMutableArray array];
	NSArray *subviews = view.subviews;
	Class hudClass = [MBProgressHUD class];
	for (NSView *view in subviews) {
		if ([view isKindOfClass:hudClass]) {
			[huds addObject:view];
		}
	}
	return [NSArray arrayWithArray:huds];
}

@end
